class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :group, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users } # null = system (e.g. round timed out)
      t.string :action, null: false
      t.json :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :activities, [ :group_id, :created_at ]
  end
end
