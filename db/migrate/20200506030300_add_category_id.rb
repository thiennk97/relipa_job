class AddCategoryId < ActiveRecord::Migration[5.2]
  def change
    add_reference :companies, :category, index: false
  end
end
