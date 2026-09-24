class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :group, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.references :started_by, null: false, foreign_key: { to_table: :users }
      t.datetime :started_at, null: false
      t.integer :status, null: false, default: 0
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
    # Only one active round (status = 0) per group
    add_index :rounds, :group_id, unique: true, where: "status = 0", name: "index_rounds_one_active_per_group"
  end
end
