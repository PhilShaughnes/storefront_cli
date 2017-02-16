class Item < ActiveRecord::Base

  has_many :orders
  has_many :reviews
  has_many :users
  belongs_to :user, through: :orders


end
