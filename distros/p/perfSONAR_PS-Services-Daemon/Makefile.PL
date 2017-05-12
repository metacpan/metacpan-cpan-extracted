use ExtUtils::MakeMaker;

my @exe_files = ( "perfsonar", "psConfigureDaemon" );

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Services::Daemon',
    'VERSION_FROM' => 'perfsonar',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"base" => 0,
	"Config::General" => 2.30,
	"Cwd" => 0,
	"Fcntl" => 0,
	"fields" => 0,
	"File::Basename" => 0,
	"Getopt::Long" => 0,
	"HTTP::Daemon" => 1.35,
	"lib" => 0,
	"Log::Log4perl" => 1.00,
	"Log::Dispatch::Screen" => 1.00,
	"Log::Dispatch::FileRotate" => 1.00,
	"Log::Dispatch::Syslog" => 1.00,
	"Module::Load" => 0.10,
	"Params::Validate" => 0.70,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Error" => 0.09,
	"perfSONAR_PS::Error_compat" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::XML::Document_string" => 0.09,
	"POSIX" => 0,
        "strict" => 0,
	"Sys::Hostname" => 0,
	"Time::HiRes" => 1.85,
        "warnings" => 0,
	"XML::LibXML" => 1.58,
    },

    EXE_FILES => \@exe_files,
);

package MY;

sub postamble {'

ifeq ($(PREFIX),/usr)
  sysconfdir=/etc
else
  sysconfdir=$(PREFIX)/etc
endif

ifeq ($(PREFIX),/usr)
  vardir=/var/run
else
  ifeq ($(PREFIX),/usr/local)
    vardir=/var/run
  else
    vardir=$(PREFIX)/var/run
  endif
endif

install ::

	if [ ! -d $(sysconfdir)/perfsonar ]; then \
		    mkdir -p $(sysconfdir)/perfsonar; \
	fi;

	if [ ! -f $(sysconfdir)/perfsonar/daemon.conf ]; then \
	    touch $(sysconfdir)/perfsonar/daemon.conf; \
	fi;

	if [ ! -f $(sysconfdir)/perfsonar/logger.conf ]; then \
	    install -c -D -m 0644 logger.conf $(sysconfdir)/perfsonar/logger.conf; \
	else \
	    echo "Old configuration file exists at $(sysconfdir)/perfsonar/logger.conf: not overwritten."; \
	fi;

	if [ ! -d $(vardir) ]; then \
		    mkdir -p $(vardir); \
	fi;

	if [ -d $(sysconfdir)/init.d ]; then \
	    mkdir -p $(sysconfdir)/init.d; \
	fi;

	if [ -f $(INSTALLBIN)/perfsonar ]; then \
		install -c -D -m 0755 perfsonar-daemon.init $(sysconfdir)/init.d/perfsonar-daemon; \
		awk "{gsub(/^PIDDIR=.*/,\"PIDDIR=$(vardir)\"); gsub(/^BINDIR=.*/,\"BINDIR=$(INSTALLBIN)\"); gsub(/^PREFIX=.*/,\"PREFIX=$(PREFIX)\"); gsub(/^CONFDIR=.*/,\"CONFDIR=$(sysconfdir)\"); print}" $(sysconfdir)/init.d/perfsonar-daemon > $(sysconfdir)/init.d/perfsonar-daemon.new; \
		mv -f $(sysconfdir)/init.d/perfsonar-daemon.new $(sysconfdir)/init.d/perfsonar-daemon; \
		chmod +x $(sysconfdir)/init.d/perfsonar-daemon; \
	elif [ -f $(INSTALLSITEBIN)/perfsonar ]; then \
		install -c -D -m 0755 perfsonar-daemon.init $(sysconfdir)/init.d/perfsonar-daemon; \
		awk "{gsub(/^PIDDIR=.*/,\"PIDDIR=$(vardir)\"); gsub(/^BINDIR=.*/,\"BINDIR=$(INSTALLSITEBIN)\"); gsub(/^PREFIX=.*/,\"PREFIX=$(PREFIX)\"); gsub(/^CONFDIR=.*/,\"CONFDIR=$(sysconfdir)\"); print}" $(sysconfdir)/init.d/perfsonar-daemon > $(sysconfdir)/init.d/perfsonar-daemon.new; \
		mv -f $(sysconfdir)/init.d/perfsonar-daemon.new $(sysconfdir)/init.d/perfsonar-daemon; \
		chmod +x $(sysconfdir)/init.d/perfsonar-daemon; \
	elif [ -f $(INSTALLVENDORBIN)/perfsonar ]; then \
		install -c -D -m 0755 perfsonar-daemon.init $(sysconfdir)/init.d/perfsonar-daemon; \
		awk "{gsub(/^PIDDIR=.*/,\"PIDDIR=$(vardir)\"); gsub(/^BINDIR=.*/,\"BINDIR=$(INSTALLVENDORBIN)\"); gsub(/^PREFIX=.*/,\"PREFIX=$(PREFIX)\"); gsub(/^CONFDIR=.*/,\"CONFDIR=$(sysconfdir)\"); print}" $(sysconfdir)/init.d/perfsonar-daemon > $(sysconfdir)/init.d/perfsonar-daemon.new; \
		mv -f $(sysconfdir)/init.d/perfsonar-daemon.new $(sysconfdir)/init.d/perfsonar-daemon; \
		chmod +x $(sysconfdir)/init.d/perfsonar-daemon; \
	fi;

	if [ -f $(INSTALLBIN)/perfsonar ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/perfsonar; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLPRIVLIB)\"); gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLBIN)/perfsonar > $(INSTALLBIN)/perfsonar.new; \
		mv -f $(INSTALLBIN)/perfsonar.new $(INSTALLBIN)/perfsonar; \
		chmod +x $(INSTALLBIN)/perfsonar; \
	elif [ -f $(INSTALLSITEBIN)/perfsonar ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLSITEBIN)/perfsonar; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLSITELIB)\"); gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLSITEBIN)/perfsonar > $(INSTALLSITEBIN)/perfsonar.new; \
		mv -f $(INSTALLSITEBIN)/perfsonar.new $(INSTALLSITEBIN)/perfsonar; \
		chmod +x $(INSTALLSITEBIN)/perfsonar; \
	elif [ -f $(INSTALLVENDORBIN)/perfsonar ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLVENDORBIN)/perfsonar; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLVENDORLIB)\"); gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLVENDORBIN)/perfsonar > $(INSTALLVENDORBIN)/perfsonar.new; \
		mv -f $(INSTALLVENDORBIN)/perfsonar.new $(INSTALLVENDORBIN)/perfsonar; \
		chmod +x $(INSTALLVENDORBIN)/perfsonar; \
	fi;

	if [ -f $(INSTALLBIN)/psConfigureDaemon ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/psConfigureDaemon; \
		awk "{gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLBIN)/psConfigureDaemon > $(INSTALLBIN)/psConfigureDaemon.new; \
		mv -f $(INSTALLBIN)/psConfigureDaemon.new $(INSTALLBIN)/psConfigureDaemon; \
		chmod +x $(INSTALLBIN)/psConfigureDaemon; \
	elif [ -f $(INSTALLSITEBIN)/psConfigureDaemon ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLSITEBIN)/psConfigureDaemon; \
		awk "{gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLSITEBIN)/psConfigureDaemon > $(INSTALLSITEBIN)/psConfigureDaemon.new; \
		mv -f $(INSTALLSITEBIN)/psConfigureDaemon.new $(INSTALLSITEBIN)/psConfigureDaemon; \
		chmod +x $(INSTALLSITEBIN)/psConfigureDaemon; \
	elif [ -f $(INSTALLVENDORBIN)/psConfigureDaemon ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLVENDORBIN)/psConfigureDaemon; \
		awk "{gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLVENDORBIN)/psConfigureDaemon > $(INSTALLVENDORBIN)/psConfigureDaemon.new; \
		mv -f $(INSTALLVENDORBIN)/psConfigureDaemon.new $(INSTALLVENDORBIN)/psConfigureDaemon; \
		chmod +x $(INSTALLVENDORBIN)/psConfigureDaemon; \
	fi;

';}
