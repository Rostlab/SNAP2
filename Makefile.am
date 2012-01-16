dist_bin_SCRIPTS = snap2
dist_noinst_DATA = Build.PL.in
dist_pkgdata_DATA = \
	phat.txt \
	snap2rc.default

docdir = $(datadir)/doc/$(PACKAGE)
dist_doc_DATA = AUTHORS README

SUBDIRS = examples models lib

man_MANS = snap2.1

%.1:	%
	sed -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"

snap2.1: snap2
	sed -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"

all-local: build-stamp

clean-local:
	rm -f snap2.1 
	if [ -e Build ]; then perl Build clean && rm -f Build build-stamp; fi

distclean-local:
	    rm -rf _build MYMETA.yml

build-stamp: Build.PL
	    perl Build.PL installdirs=vendor && perl Build && touch build-stamp

install-data-hook:
	for f in '$(DESTDIR)$(pkgdatadir)/snap2rc.default'; do \
		sed -i -e 's|__datadir__|$(datadir)|g;s|__bindir__|$(bindir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$$f"; \
	done

install-data-local:
	perl Build install destdir=$(DESTDIR) $(INSTALL_BASE_ARG) create_packlist=0

install-exec-hook:
	sed -i -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$(DESTDIR)$(bindir)/snap2"
