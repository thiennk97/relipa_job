class Category < ApplicationRecord
  searchkick language: "japanese"
  has_many :companies, dependent: :destroy
end
