###
### $Id: Makefile,v 1.2 2005-07-08 12:26:09 kiesling Exp $ 
###
### Install ODBC bridge, conf files, and clients.
###

SBINDIR=/usr/local/sbin

BINDIR=/usr/local/bin

CONFDIR=/usr/local/etc

ADMINDIR=/usr/local/etc/init.d

LOCALMAN1DIR=/usr/local/man/man1

SCRIPTS=remotedsn remotetables

ADMINSCRIPT=unixodbc

LOGINS=odbclogins

INSTSCRIPTS= $(BINDIR)/remotedsn $(BINDIR)/remotetables

MANPAGES= $(LOCALMAN1DIR)/remotedsn.1 $(LOCALMAN1DIR)/remotetables.1

MAN1EXT=1p

DAEMON=odbcbridge

CONF=odbcbridge.conf

all: install

$(SBINDIR)/$(DAEMON) : $(DAEMON)
	if [ ! -d $(SBINDIR) ]; then mkdir -p $(SBINDIR); fi ; \
	cp $(DAEMON) $(SBINDIR) && chmod 0755 "$(SBINDIR)/$(DAEMON)"

install-sbin: $(SBINDIR)/$(DAEMON)

$(CONFDIR)/$(CONF) : $(CONF)
	if [ ! -d $(CONFDIR) ]; then mkdir -p $(CONFDIR); fi ; \
	cp $(CONF) $(CONFDIR)

install-conf: $(CONFDIR)/$(CONF)

$(BINDIR)/remotetables : remotetables
	if [ ! -d $(BINDIR) ]; then mkdir -p $(BINDIR); fi ; \
	cp $< $(BINDIR) && chmod 0755 "$(BINDIR)/$<"

$(BINDIR)/remotedsn : remotedsn
	if [ ! -d $(BINDIR) ]; then mkdir -p $(BINDIR); fi ; \
	cp $< $(BINDIR) && chmod 0755 "$(BINDIR)/$<"

install-scripts: $(BINDIR)/remotedsn $(BINDIR)/remotetables

$(ADMINDIR)/$(ADMINSCRIPT) : $(ADMINSCRIPT)
	if [ ! -d $(ADMINDIR) ]; then mkdir -p $(ADMINDIR); fi ; \
	cp $< $(ADMINDIR) && chmod 0755 "$(ADMINDIR)/$<"

install-admin: $(ADMINDIR)/$(ADMINSCRIPT)

$(LOCALMAN1DIR)/remotedsn.$(MAN1EXT) : remotedsn
	if [ ! -d $(LOCALMAN1DIR) ]; then mkdir -p $(LOCALMAN1DIR); fi ; \
	pod2man $< "$(LOCALMAN1DIR)/$<.$(MAN1EXT)" 

$(LOCALMAN1DIR)/remotetables.$(MAN1EXT) : remotetables
	if [ ! -d $(LOCALMAN1DIR) ]; then mkdir -p $(LOCALMAN1DIR); fi ; \
	pod2man $< "$(LOCALMAN1DIR)/$<.$(MAN1EXT)" 

install-man: $(LOCALMAN1DIR)/remotetables.$(MAN1EXT) \
	$(LOCALMAN1DIR)/remotedsn.$(MAN1EXT)

$(CONFDIR)/$(LOGINS) : $(LOGINS)
	if [ ! -d $(CONFDIR) ]; then mkdir -p $(CONFDIR); fi ; \
	cp $< $(CONFDIR) && chmod 0600 "$(CONFDIR)/$<"

install-logins: $(CONFDIR)/$(LOGINS)

install: install-sbin install-conf install-scripts install-admin install-man \
	install-logins

clean:
	rm *~
test:
	sh -c true
