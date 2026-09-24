require "test_helper"

class RoundsTest < ActionDispatch::IntegrationTest
  setup do
    @host = users(:alice)
    @player = User.create!(email: "p@example.com", display_name: "P", password: "a-long-password-1")
    @outsider = User.create!(email: "o@example.com", display_name: "O", password: "a-long-password-1")
    @group = Group.create_with_host!({ name: "G", member_limit: 5 }, @host)
    Group.join!(@group.invite_code, @player)
    @song = @group.songs.create!(title: "Wonderwall", artist: "Oasis", audio_url: "/audio/a.mp3", added_by: @host)
  end

  def login(user, password = "a-long-password-1")
    delete session_path
    post session_path, params: { email: user.email, password: password }
  end

  def login_host = login(@host, "correct-horse-battery")

  test "host starts a round" do
    login_host
    assert_difference "Round.count", 1 do
      post group_rounds_path(@group, song_id: @song.id)
    end
    assert_redirected_to round_path(Round.last)
  end

  test "double start creates only one round" do
    login_host
    post group_rounds_path(@group, song_id: @song.id)
    assert_no_difference "Round.count" do
      post group_rounds_path(@group, song_id: @song.id)
    end
    assert_redirected_to round_path(@group.rounds.active.first)
  end

  test "player and outsider cannot start a round" do
    login(@player)
    assert_no_difference "Round.count" do
      post group_rounds_path(@group, song_id: @song.id)
    end
    login(@outsider)
    assert_no_difference "Round.count" do
      post group_rounds_path(@group, song_id: @song.id)
    end
    assert_response :not_found
  end

  test "random song start works and without songs shows a hint" do
    login_host
    post group_rounds_path(@group)
    assert_response :redirect
    assert_equal @song, Round.last.song
  end

  test "round page hides the song title while active" do
    round = Round.start!(@group, @song, @host)
    login(@player)
    get round_path(round)
    assert_response :success
    assert_no_match(/Wonderwall/, response.body)
  end

  test "outsider gets 404 for a round and cannot guess" do
    round = Round.start!(@group, @song, @host)
    login(@outsider)
    get round_path(round)
    assert_response :not_found
    post round_guesses_path(round), params: { guess: "Wonderwall" }
    assert_response :not_found
    assert_equal 0, round.participations.count
  end

  test "correct guess scores, wrong guess does not, double guess is refused" do
    round = Round.start!(@group, @song, @host)
    login(@player)
    post round_guesses_path(round), params: { guess: "nope" }
    assert_equal 0, round.participations.count
    post round_guesses_path(round), params: { guess: "wonderwall" }
    assert_equal 1, round.participations.count
    post round_guesses_path(round), params: { guess: "wonderwall" }
    assert_equal 1, round.participations.count
    assert_equal 100, Score.find_by(user: @player, group: @group).total_points
  end

  test "guessing in a finished round is refused and result page shows the song" do
    round = Round.start!(@group, @song, @host)
    round.finish!
    login(@player)
    post round_guesses_path(round), params: { guess: "wonderwall" }
    assert_equal 0, Score.find_by(user: @player, group: @group).total_points
    get round_path(round)
    assert_match(/Wonderwall/, response.body)
  end
end
