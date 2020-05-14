class AddUidCompany < ActiveRecord::Migration[5.2]
  def change
    add_column :companies, :uid, :text
  end
end
