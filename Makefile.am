dist_bin_SCRIPTS = snap2 quicksnap
dist_pkgdata_DATA = \
	phat.txt \
	snap2rc.default

docdir = $(datadir)/doc/$(PACKAGE)
dist_doc_DATA = AUTHORS README

SUBDIRS = example models lib quick

man_MANS = snap2.1

%.1:	%
	sed -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"

snap2.1: snap2
	sed -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"

clean-local:
	rm -f $(man_MANS)

install-data-hook:
	for f in '$(DESTDIR)$(pkgdatadir)/snap2rc.default'; do \
		sed -i -e 's|__datadir__|$(datadir)|g;s|__bindir__|$(bindir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$$f"; \
	done

install-exec-hook:
	sed -i -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$(DESTDIR)$(bindir)/snap2"
	sed -i -e 's|__datadir__|$(datadir)|g;s|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__PREFIX__|$(prefix)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__VERSION__|$(VERSION)|g;' "$(DESTDIR)$(bindir)/quicksnap"
