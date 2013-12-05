all:
	rm -rf /tmp/sitebuild
	bundle exec jekyll --no-server /tmp/sitebuild
	rm -rf _site
	git checkout master
	rm -rf *
	cp -rf /tmp/sitebuild/* .
	git add .
	git commit -a -m "update site"
	git checkout source
	git push --all
