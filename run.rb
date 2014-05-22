require './models.rb'
require './parser.rb'

# добавил maik_id
# Issue.number лучше тектовым, из-за двойных
# not nulls
# увеличил article_ref.name
# добавил doi
# увеличил кол-во цитирований, встретилось 131
# увеличил текст в цитированиях

# parse_issues

maik_ids = Article.pluck(:maik_id)[257..-1]
maik_ids.each_with_index do |maik_id,i|
  begin
    puts "Parsing ##{maik_id} (#{i+1}/#{maik_ids.count})."
    parse_article(maik_id)
    puts "  Parsed ##{maik_id}"
  rescue
    puts "  !Failed ##{maik_id}"
  end
end



