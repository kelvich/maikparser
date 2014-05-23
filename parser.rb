# coding: utf-8
#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'

# ядрище = REO8HVWBM 
# ядрище мифишное = RGBOPHCDP
JOURNAL = 'RGBOPHCDP'

### Load all years with issues
def load_all_years
  years_url = "http://www.maikonline.com/maik/showIssues.do?juid=#{JOURNAL}"
  page = Nokogiri::HTML(open(years_url))
  years = page.
    css('.bs-link-12px').
    map{|l| l.text[/\d+/] }.
    compact.
    map(&:to_i)
end

### Load all issues in given year
def load_issue_ids(year)
  issues_url = "http://www.maikonline.com/maik/showIssues.do?juid=#{JOURNAL}&year=#{year}"
  issue_links_page = Nokogiri::HTML(open(issues_url, :read_timeout => 150))
  issue_links_page.
    xpath('//a[@class="bs-table-link" and text()="HTML"]').
    map{|l| l.attributes['href'].value.split('=').last }
end

### Load issue content
def load_issue_with_article_ids(issue_id)
  issue_url = "http://www.maikonline.com/maik/showIssueContent.do?puid=#{issue_id}&lang=ru"
  issue_page = Nokogiri::HTML(open(issue_url, :read_timeout => 150), nil, 'utf-8')

  issue_text = issue_page.
    css('span[style="font-size: 117%;"]').
    text.split(',')

  issue = {
    year: issue_text[2][/\d+/],
    volume: issue_text[0][/\d+/],
    number: issue_text[1][/\d+/], # first, if several
    page_start: issue_text[3].split('-')[0][/\d+/],
    page_end: issue_text[3].split('-')[1][/\d+/],
    # articles_number: 0 # do not fill at this time
  }

  articles_by_sections = issue_page.
    css('form[name="emptyform"] > table[width="100%"] > tr')[1..-1].
    reject{ |tr| !tr.css('.bs-cell-br-000000-t1-solid-pdt3-pdb3').empty? }.
    each_slice(2).to_a.
    map{ |a| 
      if a.count == 2
        [ a[0].text.strip, 
          a[1].
            css('a.bs-link-010101-12px').
            each_slice(2).
            map{|l| l.first.attributes['href'].value.split('=').last } ]
      end
    }.compact

  [issue, articles_by_sections]
end

### Parse specific article
def load_article(article_id)
  article_url = "http://www.maikonline.com/maik/showArticle.do?auid=#{article_id}&lang=ru"
  article_page = Nokogiri::HTML(open(article_url, :read_timeout => 150), nil, 'utf-8')

  article = {}
  article[:title] = article_page.css('.bs-text-black-12px > b').text
  article[:pages] = article_page.css('.bs-text-black-12px-bold > span').
    text.split(' ').last.split('-')
  article[:abstract] = article_page.
    css('p[style="text-align:justify;"]').text
  if article_page.xpath('//font[contains(text(),"DOI")]').empty?
    puts "!Warning: there is no explicit DOI given, using prefix '10.1134/'"
    article[:doi] = '10.1134/' + article_page.
      xpath('//font[contains(text(),"PII")]').
      text.strip.
      split(' ').last
  else
    article[:doi] = article_page.css('a.alink').last.text[/[^ ]+$/]
  end

  unless article_page.css('a.alink + sup').map{|sup| sup.text[/\d+/]}.compact.empty?
    assocs = article_page.
      css('a.alink + sup').
      map{|sup| sup.text[/\d+/].to_i }.
      compact
    authors = article_page.
      css('a.alink')[0..-2].
      map(&:text)
    orgs = article_page.
      css('span[style="font-size: 80%;"]').
      first.children.
      reject{|tag| tag.name != 'text'}.
      map(&:text)
    article[:authors_orgs] = authors.zip(assocs).
      map{|arr| arr[1] = orgs[(arr[1] || 1)-1]; arr }
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
    join.
    strip.
    split(':').last.
    split(', ').
    map{ |kw| kw.strip.delete('.') }

  article[:refs] = article_page.css('ol > li').map(&:text)

  article
end




###############



def parse_article(maik_id)
  article_json = load_article(maik_id)
  article = Article.where(maik_id:maik_id).first
  article.title_ru = article_json[:title]
  article.abstract_ru = article_json[:abstract]
  article.doi = article_json[:doi]
  article.page_start = article_json[:pages].first
  article.page_end = article_json[:pages].last
  article.save

  article_json[:refs].each_with_index do |reftitle, i|
    ArticleReference.where({
      text_ru: reftitle,
      article_id: article.id,
      order: i
    }).first_or_create
  end


  ArticleKeyword.where(article_id:article.id).delete_all
  article_json[:keywords].each_with_index do |kwtitle,i|
    kw = Keyword.where(name_ru:kwtitle).first_or_create
    ArticleKeyword.create!({
      article_id: article.id,
      keyword_id: kw.id,
      order: i
    })
  end

  ArticleAuthor.where(article_id:article.id).delete_all
  article_json[:authors_orgs].each_with_index do |arr, i|
    author_name, org_name = arr
    aname_arr = author_name.delete('.').split
    author = Author.where({
      name_ru: aname_arr[0].first,
      middle_name_ru: aname_arr[1].first,
      last_name_ru: aname_arr.last
    }).first_or_create

    org = Organization.where({
      name_ru: org_name
      }).first_or_create

    ArticleAuthor.create({
      article_id: article.id,
      author_id: author.id,
      organization_id: org.id,
      order: i
    })
  
  end

  article
end

def parse_issues
  years = load_all_years
  puts "Loaded #{years.join(', ')} years."
  years.each do |year|
    issue_ids = load_issue_ids(year)
    puts "Loaded #{issue_ids.join(', ')} issues."
    issue_ids.each do |issue_id|
      puts "Parsing #{year}, Issue##{issue_id}."
      issue_json, articles_by_sections = load_issue_with_article_ids(issue_id)
      issue = Issue.where(issue_json).first_or_create
      articles_by_sections.each do |arr|
        section_name = arr.first
        article_ids = arr.last
        section = Section.where(name_ru: section_name).first_or_create
        article_ids.each do |article_id|
          section.articles.where(maik_id: article_id, issue_id: issue.id).first_or_create
        end
      end
      puts "Last article id: #{Article.last.id}"
    end
  end
end





