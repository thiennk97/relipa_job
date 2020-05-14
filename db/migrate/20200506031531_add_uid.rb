class AddUid < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :uid, :text
  end
end
