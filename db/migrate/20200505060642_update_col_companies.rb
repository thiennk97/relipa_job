class UpdateColCompanies < ActiveRecord::Migration[5.2]
  def change
    change_column :companies, :avatar, :text
  end
end
