class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.references :group, null: false, foreign_key: true
      t.string :title, null: false
      t.string :artist, null: false
      t.string :audio_url, null: false
      t.references :added_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :songs, [ :group_id, :title, :artist ], unique: true
  end
end
