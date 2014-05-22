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
  issue_links_page = Nokogiri::HTML(open(issues_url))
  issue_links_page.
    xpath('//a[@class="bs-table-link" and text()="HTML"]').
    map{|l| l.attributes['href'].value.split('=').last }
end

### Load issue content
def load_issue_with_article_ids(issue_id)
  issue_url = "http://www.maikonline.com/maik/showIssueContent.do?puid=#{issue_id}&lang=ru"
  issue_page = Nokogiri::HTML(open(issue_url), nil, 'utf-8')

  issue_text = issue_page.
    css('span[style="font-size: 117%;"]').
    text.split(',')

  issue = {
    year: issue_text[2][/\d+/],
    volume: issue_text[0][/\d+/],
    number: issue_text[1][/\d+/], # first, if several
    page_start: issue_text[3].split('-')[0][/\d+/],
    page_end: issue_text[3].split('-')[0][/\d+/],
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
end







