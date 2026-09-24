class Round < ApplicationRecord
  class AlreadyActive < StandardError; end

  # Clip length in seconds per stage, seconds until the next stage begins, points per stage.
  STAGES = [ 0.1, 0.5, 1, 2, 4, 8, 16 ].freeze
  STAGE_DURATION = 10
  POINTS = [ 100, 80, 60, 40, 25, 10, 5 ].freeze

  belongs_to :group
  belongs_to :song
  belongs_to :started_by, class_name: "User"
  has_many :participations, dependent: :destroy

  enum :status, { active: 0, finished: 1 }

  validates :started_at, presence: true

  # Real time: subscribers of the group (group page, leaderboard) and of the round refresh themselves.
  after_create_commit -> { broadcast_refresh_later_to group }
  after_update_commit -> { broadcast_refresh_later_to(self); broadcast_refresh_later_to(group) }, if: :saved_change_to_status?

  # Starts a round. Only one active round per group exists (partial unique index);
  # a double click or retry therefore raises AlreadyActive instead of creating a second round.
  def self.start!(group, song, user)
    transaction do
      group.rounds.active.each(&:expire_if_needed!) # a timed-out round must not block a new one
      group.rounds.create!(song: song, started_by: user, started_at: Time.current)
    end
  rescue ActiveRecord::RecordNotUnique
    raise AlreadyActive
  end

  # The server decides the stage, never the client. nil means all stages are over.
  def current_stage(now = Time.current)
    index = ((now - started_at) / STAGE_DURATION).floor
    index if index < STAGES.size
  end

  def expired?(now = Time.current)
    current_stage(now).nil?
  end

  def clip_seconds(now = Time.current)
    stage = current_stage(now)
    stage && STAGES[stage]
  end

  def points_for(stage)
    POINTS.fetch(stage)
  end

  def milliseconds_until_next_stage(now = Time.current)
    (((started_at + (((now - started_at) / STAGE_DURATION).floor + 1) * STAGE_DURATION) - now) * 1000).ceil
  end

  def correct_guess?(text)
    self.class.normalize(text) == self.class.normalize(song.title)
  end

  def self.normalize(text)
    text.to_s.downcase.gsub(/[^\p{Alnum}]/, "")
  end

  # Result: :correct, :wrong, :already (has scored) or :closed (round over).
  # Runs under the round lock so that concurrent guesses are serialised.
  def guess!(user, text, now = Time.current)
    with_lock do
      next :closed unless active?
      if expired?(now)
        finish_locked!
        next :closed
      end
      next :already if participations.exists?(user_id: user.id)
      next :wrong unless correct_guess?(text)

      stage = current_stage(now)
      points = points_for(stage)
      participations.create!(user: user, correct: true, points: points, stage_reached: stage)
      Score.find_or_create_by!(user: user, group: group).add_points!(points) # atomic UPDATE total = total + n
      finish_locked! if everyone_scored?
      :correct
    end
  rescue ActiveRecord::RecordNotUnique
    :already
  end

  def expire_if_needed!
    finish! if active? && expired?
  end

  def finish!
    with_lock { finish_locked! }
  end

  private

  def everyone_scored?
    group.memberships.where.not(user_id: participations.select(:user_id)).none?
  end

  # Marks the round finished and records 0 points for everybody who did not guess it.
  def finish_locked!
    return unless active?
    update!(status: :finished)
    group.memberships.where.not(user_id: participations.select(:user_id)).find_each do |membership|
      participations.create!(user_id: membership.user_id, correct: false, points: 0)
    end
  end
end
