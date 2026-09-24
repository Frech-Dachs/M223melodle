class CreateScores < ActiveRecord::Migration[8.1]
  def change
    create_table :scores do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.integer :total_points, null: false, default: 0

      t.timestamps
    end
    add_index :scores, [ :user_id, :group_id ], unique: true
    add_index :scores, [ :group_id, :total_points ]
  end
end
