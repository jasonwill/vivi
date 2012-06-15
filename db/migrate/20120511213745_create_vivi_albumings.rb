class CreateViviAlbumings < ActiveRecord::Migration
  def change
    create_table :vivi_albumings do |t|
      t.references :vivi_album
      t.references :vivi_doc
      t.integer  :position
      t.integer  :submitted_by
      t.datetime :submitted_at
      t.boolean  :approved,       :default => false
      t.integer  :approved_by
      t.datetime :approved_at
      t.text     :approval_notes
      t.timestamps
    end
    
    add_index :vivi_albumings, [:vivi_doc_id, :vivi_album_id], :name => "index_vivi_albumings_on_doc_id_and_album_id"
    add_index :vivi_albumings, [:submitted_by, :submitted_at], :name => "index_vivi_albumings_on_submitted_by_and_submitted_at"
    
  end
end
