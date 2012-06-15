class CreateViviMetadata < ActiveRecord::Migration
  def change
    create_table :vivi_metadatas do |t|
      t.references :vivi_doc
      t.text     :description
      t.string   :culture,           :limit => 128, :default => ""
      t.date     :creation_start_at
      t.date     :creation_end_at
      t.string   :current_location,  :limit => 128, :default => ""
      t.string   :medium,            :limit => 128, :default => ""
      t.string   :dimensions,        :limit => 32,  :default => ""
      t.string   :period_style,      :limit => 128, :default => ""
      t.string   :language,          :limit => 64,  :default => ""
      t.string   :source,            :limit => 64,  :default => ""
      t.string   :digitization_spec,                :default => ""
      t.text     :subject_headings
      t.string   :subject_matter,                   :default => ""
      t.string   :type_of_work,                     :default => ""
      t.string   :media_credits,                    :default => ""
      t.string   :caption,                          :default => ""
      t.references  :vivi_right                 
      t.string   :publish_status,                   :default => "local-only"
      
      t.timestamps
    end
    
    add_index :vivi_metadatas, [:vivi_doc_id], :name => "index_vivi_metadatas_on_doc_id"
    add_index :vivi_metadatas, [:vivi_right_id], :name => "index_vivi_metadatas_on_right_id"
  end
end
