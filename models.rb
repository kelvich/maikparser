require 'active_record'
require 'mysql2'

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2',
  :database => 'vestnik'
)

class Issue < ActiveRecord::Base
  has_many :articles
end

class Section < ActiveRecord::Base
  has_many :articles
end

class Article < ActiveRecord::Base
  belongs_to :issue
  belongs_to :section

  has_many :article_references
  has_many :article_authors
  has_many :article_keywords
  has_many :authors, :through => :article_authors
  has_many :organizations, :through => :article_authors
  has_many :keywords, :through => :article_keywords
end

class ArticleReference < ActiveRecord::Base
  belongs_to :article
end


class Organization < ActiveRecord::Base
  has_many :article_authors
end

class Author < ActiveRecord::Base
  has_many :article_authors
end

class ArticleAuthor < ActiveRecord::Base
  self.table_name = "c_articles_authors"

  belongs_to :article
  belongs_to :author
  belongs_to :organization
end

class Keyword < ActiveRecord::Base
  has_many :article_keywords
end

class ArticleKeyword < ActiveRecord::Base
  self.table_name = "c_articles_keywords"
  belongs_to :article
  belongs_to :keyword
end

### Associations test
# a = Article.first
# a.authors
# a.keywords
# a.organizations
# a.article_references
# a.issue
# a.section
