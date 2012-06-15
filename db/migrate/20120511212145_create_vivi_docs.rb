class CreateViviDocs < ActiveRecord::Migration
  def change
    create_table :vivi_docs do |t|
      t.string   :title,              :default => ""
      
      t.string   :asset_file_name,    :default => ""
      t.string   :asset_content_type, :default => ""
      t.integer  :asset_file_size
      t.datetime :asset_updated_at
      t.string   :asset_resolution,   :default => ""
      t.integer  :asset_dpi,          :default => 0
      t.string   :asset_remote_url,   :default => ""
                 
      t.boolean  :processing,         :default => true
      t.integer  :views,              :default => 0
      t.integer  :created_by
      t.string   :uuid,               :default => "",   :null => false
      t.integer  :ext_ref
      t.string   :cover,              :default => ""
      t.integer  :poster_for
    
      t.timestamps
    
    end
    
    add_index :vivi_docs, [:created_by, :created_at], :name => "index_vivi_docs_on_created_by_and_created_at"
    
  end
end
