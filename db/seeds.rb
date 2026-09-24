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

[
  [ "Bohemian Rhapsody", "Queen" ],
  [ "Billie Jean", "Michael Jackson" ],
  [ "Smells Like Teen Spirit", "Nirvana" ],
  [ "Hotel California", "Eagles" ],
  [ "Wonderwall", "Oasis" ],
  [ "Rolling in the Deep", "Adele" ]
].each_with_index do |(title, artist), i|
  Song.find_or_create_by!(group: group, title: title, artist: artist) do |s|
    s.audio_url = "/audio/demo-#{i + 1}.mp3" # placeholder, use licence-free tracks
    s.added_by = host
  end
end
