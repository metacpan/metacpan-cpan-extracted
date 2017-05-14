[%- IF TOP_LEVEL -%]
SUBDIRS = DB Apache templates html
[% END -%]

[%- IF DB -%]
SUBDIRS = Table
[% END -%]

[%- IF APACHE -%]
SUBDIRS = Request
[% END -%]

[%- IF REQUEST -%]
SUBDIRS = Controller
[% END -%]

[%- IF BASE && ( ROW || TABLE || CONTROLLER || TEMPLATE ) -%]
SUBDIRS = [% IF TABLE %]Row [% END %][% FOREACH tableName = TABLES %][% tableName %][% UNLESS loop.last %] [% END %][% END %]
[% IF TEMPLATE -%]

templatedir=$(prefix)/$(PACKAGE_NAME)/templates
template_DATA = _header.tt2 \
                _fieldDisplay.tt2 \
                _fieldInput.tt2 \
                _fkeyDisplay.tt2 \
                _fkeyInput.tt2 \
                _pager.tt2 \
                _form.tt2 \
                _auth.tt2
EXTRA_DIST = $(template_DATA)
[% END -%]
[% END -%]

[%- IF (!BASE) && (ROW || TABLE || CONTROLLER) -%]
moduledir=$(prefix)/modules/[% IF ROW %]DB/Table/Row[% ELSIF TABLE %]DB/Table[% ELSIF CONTROLLER %]Apache/Request/Controller[% END %]
module_DATA = [% tableName %].pm
EXTRA_DIST = $(module_DATA)
[% END -%]

[%- IF (!BASE) && TEMPLATE -%]
templatedir=$(prefix)/$(PACKAGE_NAME)/templates/[% tableName %]
template_DATA = list.tt2 \
                show.tt2 \
                create.tt2 \
                edit.tt2
EXTRA_DIST = $(template_DATA)
[% END -%]

[% IF TOP_LEVEL -%]

cfgdir=$(prefix)/$(PACKAGE_NAME)
cfg_DATA = $(PACKAGE_NAME).cfg

apacheconfdir=$(apacheIncludedConfigs)
apacheconf_DATA = $(PACKAGE_NAME).apache.conf \
                  $(PACKAGE_NAME).pl

EXTRA_DIST = $(cfg_DATA) $(apacheconf_DATA)

rpm: dist
	cp $(PACKAGE)-$(VERSION).tar.gz /usr/src/redhat/SOURCES/
	rpmbuild -ba $(PACKAGE_NAME).spec
	cp /usr/src/redhat/SRPMS/$(PACKAGE)-$(VERSION)-1.src.rpm .
	cp /usr/src/redhat/RPMS/noarch/$(PACKAGE)-$(VERSION)-1.noarch.rpm .
	cp /usr/src/redhat/RPMS/noarch/$(PACKAGE)-db-modules-$(VERSION)-1.noarch.rpm .
[% END -%]
