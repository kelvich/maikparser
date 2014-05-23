require 'active_record'
require 'mysql2'
require 'russian'

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2',
  :database => 'vestnik'
)


# Issue.find_each{|is| is.articles_number = is.articles.count; is.save }
class Issue < ActiveRecord::Base
  has_many :articles, :counter_cache => :articles_number
end

class Section < ActiveRecord::Base
  has_many :articles

  before_save :transliterate

  def transliterate
    self.name_en = Russian::transliterate(name_ru) if name_ru
  end
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

  before_save :transliterate

  def transliterate
    self.title_en = Russian::transliterate(title_ru) if title_ru 
    self.abstract_en = Russian::transliterate(abstract_ru) if abstract_ru
  end
end

class ArticleReference < ActiveRecord::Base
  belongs_to :article

  before_save :transliterate

  def transliterate
    self.text_en = Russian::transliterate(text_ru) if text_ru
  end
end


class Organization < ActiveRecord::Base
  has_many :article_authors

  before_save :transliterate

  def transliterate
    self.name_en = Russian::transliterate(name_ru) if name_ru
  end
end

class Author < ActiveRecord::Base
  has_many :article_authors

  before_save :transliterate

  def transliterate
    self.name_en = Russian::transliterate(name_ru) if name_ru 
    self.middle_name_en = Russian::transliterate(middle_name_ru) if middle_name_ru
    self.last_name_en = Russian::transliterate(last_name_ru) if last_name_ru
  end
end

class ArticleAuthor < ActiveRecord::Base
  self.table_name = "c_articles_authors"

  belongs_to :article
  belongs_to :author
  belongs_to :organization
end

class Keyword < ActiveRecord::Base
  has_many :article_keywords

  before_save :transliterate

  def transliterate
    self.name_en = Russian::transliterate(name_ru) if name_ru
  end
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
