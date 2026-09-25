class Round < ApplicationRecord
  class AlreadyActive < StandardError; end

  # Clip length in seconds per stage and points per stage. Every player has their own stage:
  # it advances after each wrong guess of that player. Players do not have to play at the same time.
  STAGES = [ 0.1, 0.5, 1, 2, 4, 8, 16 ].freeze
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
      round = group.rounds.create!(song: song, started_by: user, started_at: Time.current)
      Activity.record!(group: group, action: "round_started", actor: user)
      round
    end
  rescue ActiveRecord::RecordNotUnique
    raise AlreadyActive
  end

  def participation_for(user)
    participations.find_by(user_id: user.id)
  end

  # The player's current stage (0 if they have not started yet) and the matching clip length.
  def stage_for(user)
    participation_for(user)&.stage || 0
  end

  def clip_seconds_for(user)
    STAGES[[ stage_for(user), STAGES.size - 1 ].min]
  end

  def finished_by?(user)
    participation_for(user)&.finished? || false
  end

  def points_for(stage)
    POINTS.fetch(stage)
  end

  def correct_guess?(text)
    self.class.normalize(text) == self.class.normalize(song.title)
  end

  def self.normalize(text)
    text.to_s.downcase.gsub(/[^\p{Alnum}]/, "")
  end

  # Result: :correct, :wrong, :out_of_tries (last wrong guess), :already (player is done) or :closed (round over).
  # Runs under the round lock so that concurrent guesses are serialised.
  def guess!(user, text)
    with_lock do
      next :closed unless active?

      participation = participations.find_or_create_by!(user_id: user.id)
      next :already if participation.finished?

      if correct_guess?(text)
        points = points_for(participation.stage)
        participation.update!(correct: true, points: points, stage_reached: participation.stage, finished: true)
        Score.find_or_create_by!(user: user, group: group).add_points!(points) # atomic UPDATE total = total + n
        Activity.record!(group: group, action: "guess_correct", actor: user, points: points)
        result = :correct
      else
        Activity.record!(group: group, action: "guess_wrong", actor: user)
        participation.stage += 1
        participation.finished = participation.stage >= STAGES.size
        participation.stage = STAGES.size - 1 if participation.finished
        participation.save!
        result = participation.finished? ? :out_of_tries : :wrong
      end
      finish_locked! if everyone_finished?
      result
    end
  rescue ActiveRecord::RecordNotUnique
    :already
  end

  # Host ends the round early, e.g. when a player never plays.
  def finish!
    with_lock { finish_locked! }
  end

  private

  def everyone_finished?
    group.memberships.where.not(user_id: participations.where(finished: true).select(:user_id)).none?
  end

  # Marks the round finished; everybody who has not solved it ends with 0 points.
  def finish_locked!
    return unless active?
    update!(status: :finished)
    Activity.record!(group: group, action: "round_finished", actor: nil, title: song.title)
    participations.where(finished: false).update_all(finished: true)
    group.memberships.where.not(user_id: participations.select(:user_id)).find_each do |membership|
      participations.create!(user_id: membership.user_id, correct: false, points: 0, finished: true)
    end
  end
end
