class Address < ActiveRecord::Base
  has_many :people
  has_many :requirements

  validates :city, :country_code, :state_code, presence: true
end
