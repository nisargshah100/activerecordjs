class User < ActiveRecord::Base

  has_many :user_accounts
  has_many :accounts, :through => :user_accounts

  validates :email, :presence => true

  before_create :bc

  def bs
    puts '-----------------  before save called --------------------'
  end

  def as
    puts '-----------------  after save called --------------------'
    # update_attributes(:name => 'apples')
  end

  def bc
    puts '-----------------  before created called --------------------'
  end

  def ac
    puts '-----------------  after created called --------------------'
  end

  def bu
    puts '-----------------  before update called --------------------'
  end

  def au
    puts '-----------------  after update called --------------------'
  end

end
