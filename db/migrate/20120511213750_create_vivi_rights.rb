class CreateViviRights < ActiveRecord::Migration
  def change
    create_table :vivi_rights do |t|
      t.string  :name,     :default => ""
      t.boolean :cc,       :default => false
      t.string  :ext_link, :default => ""
    end
  end
end
