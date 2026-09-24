class LeaderboardsController < ApplicationController
  before_action :require_login

  def show
    @group = policy_scope(Group).find(params[:group_id])
    authorize @group, :leaderboard?

    played = Participation.joins(:round).where(rounds: { group_id: @group.id }).group(:user_id).count
    scores = @group.scores.leaderboard.to_a
    @rows = scores.each_with_index.map do |score, i|
      rank = i.positive? && scores[i - 1].total_points == score.total_points ? nil : i + 1
      { score: score, played: played.fetch(score.user_id, 0), rank: rank }
    end
    # tied players share the rank of the first one
    last = nil
    @rows.each { |row| row[:rank] ? last = row[:rank] : row[:rank] = last }
  end
end
