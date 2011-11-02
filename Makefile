all:
	rm -rf /tmp/sitebuild
	jekyll --no-auto --no-server --no-safe /tmp/sitebuild
	git checkout master
	rm -rf *
	cp -rf /tmp/sitebuild/* .
	git add .
	git commit -a -m "update site"
	git checkout source
