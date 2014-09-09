class Account < ActiveRecord::Base
  has_many :user_accounts
  has_many :accounts, :through => :user_accounts
end
