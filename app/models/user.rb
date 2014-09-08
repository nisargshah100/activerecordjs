class User < ActiveRecord::Base

  validates :email, :uniqueness => true
  validates :age, :presence => true, :length => { :minimum => 3 }

  before_save :bs
  after_save :as
  before_create :bc
  after_create :ac
  before_update :bu
  after_update :au

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
