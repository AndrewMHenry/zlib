.PHONY: test clean

test:
	zproj install lib
	cd test; zapp
	cp test/zlib_test-app.* ~/SharedProjects/

clean:
	find . -name \*~ -delete
