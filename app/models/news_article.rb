class NewsArticle < Node
  has_many :news_distributions
  has_many :sections, through: :news_distributions, source: :distribution,
           source_type: 'Section'

  alias_method :publisher, :section
  store_attribute :data, :release_date, Date

  friendly_id :date_and_name, use: [:slugged, :scoped], routes: :default, scope: :section

  scope :by_release_date, -> {
    order("data ->> 'release_date' DESC")
  }

  scope :by_published_at, -> {
    order(published_at: :desc)
  }

  scope :by_name, -> {
    order("content ->> 'name' ASC")
  }

  validates_presence_of :section

  def layout
    'news_article'
  end

  # News Articles require specific redirects to a custom route that
  # is not defined by node hierarchy. As such, this method is a convenience
  # wrapper around the url helpers, to allow this model to override the default
  # redirect action.
  def full_path
    Rails.application.routes.url_helpers.news_article_path(section.home_node.slug, slug)
  end


  # http://norman.github.io/friendly_id/file.Guide.html#Column_or_Method_
  # As we want to scope the friendly_ids to both section and release_date,
  # and release_date is a field of a store, we are unable to access it via the
  # scope param as it expects to find a column name. Instead, we can manually
  # construct the slug with the below method.
  def date_and_name
    "#{release_date} #{name}"
  end
end
