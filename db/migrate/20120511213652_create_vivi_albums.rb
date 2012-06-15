class CreateViviAlbums < ActiveRecord::Migration
  def change
    create_table :vivi_albums do |t|
      t.string   :name,                          :default => ""
      t.text     :description
      t.string   :type,            :limit => 64, :default => ""
      
      t.integer  :created_by
      t.string   :status,                        :default => "publish"
      t.string   :submission_priv,               :default => "open"
      t.string   :view_priv,                     :default => "public"
      
      t.boolean  :promoted,                      :default => false
      t.integer  :promoted_by
      t.datetime :promoted_at
      
      t.string   :uuid,                          :default => "",        :null => false
      t.integer  :ext_ref
      
      t.timestamps
    end
    
    add_index :vivi_albums, [:created_by, :updated_at], :name => "index_vivi_albums_on_created_by_and_updated_at"
    
  end
end
