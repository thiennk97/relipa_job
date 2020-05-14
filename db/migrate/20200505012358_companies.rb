class Companies < ActiveRecord::Migration[5.2]
  def change
    create_table :companies do |t|
      t.string :name
      t.text :avatar
      t.text :title
      t.text :content
      t.text :type_company
      t.text :address
    end
  end
end
