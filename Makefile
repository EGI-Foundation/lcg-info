NAME= $(shell grep Name: *.spec | sed 's/^[^:]*:[^a-zA-Z]*//' )
VERSION= $(shell grep Version: *.spec | sed 's/^[^:]*:[^0-9]*//' )
RELEASE= $(shell grep Release: *.spec |cut -d"%" -f1 |sed 's/^[^:]*:[^0-9]*//')
build=$(shell pwd)/build
DATE=$(shell date "+%a, %d %b %Y %T %z")
dist=$(shell rpm --eval '%dist' | sed 's/%dist/.el5/')

default: 
	@echo "Nothing to do"

manpage:
	@echo Updating manpage
	@pod2man --section=1 src/lcg-info > lcg-info.groff
	@COLUMNS=80 man ./lcg-info.groff  > src/lcg-info.1

install:
	@echo installing ...
	@mkdir -p $(prefix)/usr/bin/
	@mkdir -p $(prefix)/usr/share/man/man1
	mkdir -p $(prefix)/usr/share/doc/$(NAME)
	@install -m 0755 src/lcg-info   $(prefix)/usr/bin/lcg-info
	@install -m 0644 src/lcg-info.1 $(prefix)/usr/share/man/man1/lcg-info.1
	@install -m 0644 LICENSE.txt $(prefix)/usr/share/doc/$(NAME)/

dist:
	@mkdir -p $(build)/$(NAME)-$(VERSION)/
	rsync -HaS --exclude ".git" --exclude "$(build)" --exclude "debian" * $(build)/$(NAME)-$(VERSION)/
	cd $(build); tar --gzip -cf $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)/; cd -

dist-deb:
	@mkdir -p $(build)/$(NAME)-$(VERSION)/
	rsync -HaS --exclude ".git" --exclude "build" * $(build)/$(NAME)-$(VERSION)/
	cd $(build); tar --gzip -cf $(NAME)_$(VERSION).orig.tar.gz $(NAME)-$(VERSION)/; cd -

sources: dist
	cp $(build)/$(NAME)-$(VERSION).tar.gz .

deb: dist-deb
	cd $(build)/$(NAME)-$(VERSION); debuild -us -uc; cd -
	mkdir $(build)/deb ; cp $(build)/*.deb $(build)/*.dsc $(build)/*.debian.tar.gz $(build)/*.orig.tar.gz $(build)/deb

prepare: dist
	@mkdir -p $(build)/RPMS/noarch
	@mkdir -p $(build)/SRPMS/
	@mkdir -p $(build)/SPECS/
	@mkdir -p $(build)/SOURCES/
	@mkdir -p $(build)/BUILD/
	cp $(build)/$(NAME)-$(VERSION).tar.gz $(build)/SOURCES 
	cp $(NAME).spec $(build)/SPECS

srpm: prepare
	rpmbuild -bs --define="dist ${dist}" --define='_topdir ${build}' $(build)/SPECS/$(NAME).spec

rpm: srpm
	rpmbuild --rebuild --define='_topdir ${build}' $(build)/SRPMS/$(NAME)-$(VERSION)-$(RELEASE)${dist}.src.rpm

clean:
	rm -f *~ ${NAME}.groff $(NAME)-$(VERSION).tar.gz
	rm -rf $(build)

.PHONY: dist dist-deb srpm rpm deb sources clean manpage
