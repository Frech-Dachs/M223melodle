class CreateParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :round, null: false, foreign_key: true
      t.boolean :correct, null: false, default: false
      t.integer :points, null: false, default: 0
      t.integer :stage_reached
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
    add_index :participations, [ :user_id, :round_id ], unique: true
  end
end
