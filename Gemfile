source :rubygems

gem 'sinatra'
gem 'thin'
gem 'sinatra-partial'
gem 'fb_graph'
gem 'nokogiri'
gem 'mechanize'
gem 'redis'
gem 'gibberish'

gem "dm-core", :git => "git://github.com/datamapper/dm-core.git"
gem "dm-validations", :git => "git://github.com/datamapper/dm-validations.git"
gem "dm-serializer", :git => "git://github.com/datamapper/dm-serializer.git"
gem "dm-aggregates", :git => "git://github.com/datamapper/dm-aggregates.git"
gem "dm-migrations", :git => "git://github.com/datamapper/dm-migrations.git"
gem "dm-transactions", :git => "git://github.com/datamapper/dm-transactions.git"
gem "dm-timestamps", :git => "git://github.com/datamapper/dm-timestamps.git"
gem "dm-types", :git => "git://github.com/datamapper/dm-types.git"
gem "dm-do-adapter", :git => "git://github.com/datamapper/dm-do-adapter"

group :development, :test do
	gem "dm-sqlite-adapter", :git => "git://github.com/datamapper/dm-sqlite-adapter"
	gem "sqlite3"
end

group :production do
	gem 'pg'
	gem "dm-postgres-adapter", :git => "git://github.com/datamapper/dm-postgres-adapter.git"
	#gem 'do-postgres'
end
