class SynergyNode < ApplicationRecord
  def name
    title || (slug.blank? ? 'Home' : slug.underscore.humanize)
  end
end
