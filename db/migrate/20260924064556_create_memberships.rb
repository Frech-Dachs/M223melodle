class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.integer :total_points, null: false, default: 0

      t.timestamps
    end
    add_index :memberships, [ :user_id, :group_id ], unique: true
    add_index :memberships, [ :group_id, :total_points ]
  end
end
