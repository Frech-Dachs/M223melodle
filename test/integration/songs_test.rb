require "test_helper"

class SongsTest < ActionDispatch::IntegrationTest
  setup do
    @host = users(:alice)
    @player = User.create!(email: "p@example.com", display_name: "P", password: "a-long-password-1")
    @outsider = User.create!(email: "o@example.com", display_name: "O", password: "a-long-password-1")
    @group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    Group.join!(@group.invite_code, @player)
    @song = @group.songs.create!(title: "Wonderwall", artist: "Oasis", audio_url: "/audio/a.mp3", added_by: @host)
  end

  def login(user, password = "a-long-password-1")
    post session_path, params: { email: user.email, password: password }
  end

  def login_host = login(@host, "correct-horse-battery")

  test "members see the list, outsiders get 404" do
    login(@player)
    get group_songs_path(@group)
    assert_response :success
    assert_select "td", "Wonderwall"
    delete session_path
    login(@outsider)
    get group_songs_path(@group)
    assert_response :not_found
  end

  test "host adds a song" do
    login_host
    assert_difference "Song.count", 1 do
      post group_songs_path(@group), params: { song: { title: "Creep", artist: "Radiohead", audio_url: "/audio/b.mp3" } }
    end
    assert_redirected_to group_songs_path(@group)
    assert_equal @host, Song.last.added_by
  end

  test "player cannot add or remove songs" do
    login(@player)
    assert_no_difference "Song.count" do
      post group_songs_path(@group), params: { song: { title: "Creep", artist: "Radiohead", audio_url: "/audio/b.mp3" } }
      delete group_song_path(@group, @song)
    end
  end

  test "invalid song keeps the form with errors" do
    login_host
    assert_no_difference "Song.count" do
      post group_songs_path(@group), params: { song: { title: "", artist: "X", audio_url: "javascript:alert(1)" } }
    end
    assert_response :unprocessable_entity
  end

  test "duplicate song is rejected" do
    login_host
    assert_no_difference "Song.count" do
      post group_songs_path(@group), params: { song: { title: "Wonderwall", artist: "Oasis", audio_url: "/audio/c.mp3" } }
    end
    assert_response :unprocessable_entity
  end

  test "search filters by title or artist and treats wildcards literally" do
    @group.songs.create!(title: "Creep", artist: "Radiohead", audio_url: "/audio/b.mp3", added_by: @host)
    login_host
    get group_songs_path(@group, q: "radio")
    assert_select "td", "Creep"
    assert_select "td", { text: "Wonderwall", count: 0 }
    get group_songs_path(@group, q: "%")
    assert_select "td", { text: "Wonderwall", count: 0 }
  end

  test "host removes a song" do
    login_host
    assert_difference "Song.count", -1 do
      delete group_song_path(@group, @song)
    end
  end

  test "song already played in a round cannot be removed" do
    @group.rounds.create!(song: @song, started_by: @host, started_at: Time.current, status: :finished)
    login_host
    assert_no_difference "Song.count" do
      delete group_song_path(@group, @song)
    end
    assert_redirected_to group_songs_path(@group)
  end
end
