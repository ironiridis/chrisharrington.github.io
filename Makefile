deps :
	mkdir -p vendor/bundle
	bundle config set --local path vendor/bundle/
	bundle install

rmdeps :
	rm -rf vendor/bundle Gemfile.lock

update :
	bundle config set --local path vendor/bundle/
	bundle update --all
	bundle clean

serve :
	bundle exec jekyll serve

clean : rmdeps deps

hammer : clean deps serve

test : update serve
