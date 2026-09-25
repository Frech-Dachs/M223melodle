# Demo data. Idempotent: safe to run repeatedly.
password = "demo-password-123"

host, anna, ben = [
  [ "host@example.test", "Host" ],
  [ "anna@example.test", "Anna" ],
  [ "ben@example.test", "Ben" ]
].map do |email, name|
  User.find_or_create_by!(email: email) { |u| u.display_name = name; u.password = password }
end

group = Group.find_or_create_by!(name: "Demo Group") { |g| g.member_limit = 20 }
Membership.find_or_create_by!(user: host, group: group) { |m| m.role = :host }
[ anna, ben ].each { |u| Membership.find_or_create_by!(user: u, group: group) { |m| m.role = :player } }
[ host, anna, ben ].each { |u| Score.find_or_create_by!(user: u, group: group) }

# Synthesised placeholder melodies in public/audio (own work, no licence issues).
# File names are deliberately opaque so they do not reveal the song title.
AUDIO_FILES = %w[c3f1a9 7be204 a8d5e6 19c0b7 e42f83 5d7a10].freeze

[
  [ "Bohemian Rhapsody", "Queen" ],
  [ "Billie Jean", "Michael Jackson" ],
  [ "Smells Like Teen Spirit", "Nirvana" ],
  [ "Hotel California", "Eagles" ],
  [ "Wonderwall", "Oasis" ],
  [ "Rolling in the Deep", "Adele" ]
].each_with_index do |(title, artist), i|
  song = Song.find_or_initialize_by(group: group, title: title, artist: artist)
  song.added_by ||= host
  song.audio_url = "/audio/#{AUDIO_FILES[i]}.wav"
  song.save!
end
