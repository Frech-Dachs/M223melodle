class AddProgressToParticipations < ActiveRecord::Migration[8.1]
  def change
    # Every player works through the stages on their own: stage = current clip stage,
    # finished = solved or out of tries.
    add_column :participations, :stage, :integer, default: 0, null: false
    add_column :participations, :finished, :boolean, default: false, null: false
  end
end
