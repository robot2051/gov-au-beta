class Invite < ApplicationRecord

  COOKIE_NAME = 'govau_beta_token'

  validates :email, :presence => true, :email => true

  def accepted?
    accepted_token.present?
  end

  def to_param
    code
  end
end
