class CreateViviCreators < ActiveRecord::Migration
  def change  
    create_table :vivi_creators do |t| 
      t.string   :name,          :limit => 255, :default => ""
      t.string   :culture,       :limit => 128, :default => ""
      t.string   :role,          :limit => 128, :default => ""
      t.date     :born_at
      t.date     :died_at
      t.string   :add_attr,                     :default => ""
      t.string   :aka,                          :default => ""
      t.string   :education,                    :default => ""
      t.string   :movement,                     :default => ""
      t.string   :reference_url,                :default => ""
      t.text     :notes
      t.string   :uuid
      t.timestamps
    end

    add_index :vivi_creators, [:name], :name => "index_vivi_creators_on_name"
  end
end