class Activity < ApplicationRecord
  ACTIONS = %w[
    group_created member_joined member_removed song_added song_removed
    round_started round_finished guess_correct guess_wrong
  ].freeze
  SYSTEM_ACTIONS = %w[round_finished].freeze # may have no actor

  belongs_to :group
  belongs_to :actor, class_name: "User", optional: true

  validates :action, inclusion: { in: ACTIONS }
  validates :actor, presence: true, unless: -> { SYSTEM_ACTIONS.include?(action) }

  # Call inside the transaction of the change it describes: if this fails, the change is rolled back.
  # The actor is Current.user (set from the session), never a request parameter.
  def self.record!(group:, action:, actor: Current.user, **metadata)
    create!(group: group, action: action, actor: actor, metadata: metadata)
  end

  def actor_name
    actor&.display_name || "Melodle"
  end

  def description
    data = metadata.with_indifferent_access
    case action
    when "group_created" then "hat die Gruppe erstellt"
    when "member_joined" then "ist der Gruppe beigetreten"
    when "member_removed" then "hat #{data[:name]} aus der Gruppe entfernt"
    when "song_added" then "hat «#{data[:title]}» zur Songliste hinzugefügt"
    when "song_removed" then "hat «#{data[:title]}» aus der Songliste entfernt"
    when "round_started" then "hat eine Runde gestartet"
    when "round_finished" then "Die Runde wurde beendet (Song: «#{data[:title]}»)"
    when "guess_correct" then "hat den Song erraten (#{data[:points]} Punkte)"
    when "guess_wrong" then "hat falsch geraten"
    end
  end
end
