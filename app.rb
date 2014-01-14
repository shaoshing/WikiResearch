require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'yaml'
require 'mysql'


# TODO: error handling
database_configs = YAML.load(File.read "configs/database.yml")

# TODO: error handling
puts "Trying to connect to mysql server..."
mysql = Mysql.connect(database_configs["host"], database_configs["user"], database_configs["password"],
  database_configs["database"], database_configs["port"])

get '/search/:title' do
  # search for page
  page_title = params[:title]
  page_query = mysql.query("select * from page where page_namespace = 0 and page_title = \"#{page_title}\" limit 1;")
  if page_query.num_rows == 0
    return "Oops, found nothing for title #{page_title}"
  else
    page = page_query.fetch_hash
    page_languages_query = mysql.query("select * from langlinks where ll_from = #{page["page_id"]};")
    page_languages = []
    page_languages_query.each_hash do |language|
      page_languages << language
    end

    page_categories_query = mysql.query("select * from categorylinks where cl_from = #{page["page_id"]};")
    page_category_names = []
    page_categories_query.each_hash do |category|
      page_category_names << category["cl_to"] if category["cl_to"] !~ /^(All_article_|All_articles_|All_disambiguation_|Articles_containing_|Articles_that_|Articles_with_|CS1_errors|Pages_containing_|Use_mdy_dates_|Wikipedia_articles_|Wikipedia_pages_|Wikipedia_protected_).+$/
    end

    page_categories_query = mysql.query("select * from page where page_namespace = 14 and page_title in (\"#{page_category_names.join("\", \"")}\");")
    page_categories = []
    page_categories_query.each_hash do |category|
      page_categories << category
    end

    erb :search, :locals => {:page => page, :languages => page_languages, :categories => page_categories}
  end
end
