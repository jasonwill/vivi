class CreateViviCreatorings < ActiveRecord::Migration
  def change  
    create_table :vivi_creatorings do |t| 
        t.references :vivi_metadata
        t.references  :vivi_creator
        t.integer  :position, :default => 0
        t.timestamps
    end
    add_index :vivi_creatorings, [:vivi_creator_id, :vivi_metadata_id], :name => "index_vivi_creatorings_on_creator_id_and_metadata_id"
  end
end