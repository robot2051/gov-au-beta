class InviteForm < Reform::Form
  property :email
  validates :email, :presence => true
  validates :email, :email => true
  validates_uniqueness_of :email
end
