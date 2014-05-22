require './models.rb'
require './parser.rb'


article_id = "VAHRLXLDTK"

article_url = "http://www.maikonline.com/maik/showArticle.do?auid=#{article_id}&lang=ru"
article_page = Nokogiri::HTML(open(article_url), nil, 'utf-8')

article = {}
article[:title] = article_page.css('.bs-text-black-12px > b').text
article[:pages] = article_page.css('.bs-text-black-12px-bold > span').
  text.split(' ').last.split('-')
article[:abstract] = article_page.
  css('p[style="text-align:justify;"]').text
article[:doi] = article_page.css('a.alink').last.text[/[^ ]+$/]

unless article_page.css('a.alink ~ sup').empty?
  assocs = article_page.
    css('a.alink ~ sup').
    map{|sup| sup.text.to_i}
  authors = article_page.
    css('a.alink')[0..-2].
    map(&:text)
  orgs = article_page.
    css('span[style="font-size: 80%;"]').
    first.children.
    reject{|tag| tag.name != 'text'}.
    map(&:text)
  article[:authors_orgs] = authors.zip(assocs).
    map{|arr| arr[1] = orgs[arr[1]-1]; arr }
else
  authors = article_page.
    css('a.alink')[0..-2].
    map(&:text)
  org = article_page.
    css('span[style="font-size: 80%;"]').
    first.text.strip
  article[:authors_orgs] = authors.zip([org]*authors.count)
end

article[:keywords] = article_page.
  css('font[class="bs-text-black-12px"]')[2].
  children.
  reject{|tag| tag.name != 'text'}.
  map(&:text).
  reject{|str| str[':'].nil? }.
  first.
  split(':').last.
  split(', ').
  map(&:strip)

article[:refs] = article_page.css('ol > li').map(&:text).last

article




# добавил maik_id
# Issue.number лучше тектовым, из-за двойных
# not nulls

# issue_json, articles_by_sections = load_issue_with_article_ids('VIGIX1524J')
# puts articles_by_sections
# issue_id = 'VIGIX1524J'


# years = load_all_years
# puts "Loaded #{years.join(', ')} years."
# years.each do |year|
#   issue_ids = load_issue_ids(year)
#   puts "Loaded #{issue_ids.join(', ')} issues."
#   issue_ids.each do |issue_id|
#     puts "Parsing #{year}, Issue##{issue_id}."
#     issue_json, articles_by_sections = load_issue_with_article_ids(issue_id)
#     issue = Issue.where(issue_json).first_or_create
#     articles_by_sections.each do |arr|
#       section_name = arr.first
#       article_ids = arr.last
#       section = Section.where(name_ru: section_name).first_or_create
#       article_ids.each do |article_id|
#         section.articles.where(maik_id: article_id).first_or_create
#       end
#     end
#     puts "Last article id: #{Article.last.id}"
#   end
# end







