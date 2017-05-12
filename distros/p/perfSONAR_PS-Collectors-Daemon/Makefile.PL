use ExtUtils::MakeMaker; 

my @exe_files = ( "perfsonar-collector", "psConfigureCollectors" );

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Collectors::Daemon',
    'VERSION_FROM' => 'perfsonar-collector',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"Config::General" => 2.30,
	"Cwd" => 0,
	"Fcntl" => 0,
	"fields" => 0,
	"File::Basename" => 0,
	"Getopt::Long" => 0,
	"lib" => 0,
	"Log::Dispatch::Screen" => 1.00,
        "Log::Dispatch::FileRotate" => 1.00,
        "Log::Dispatch::Syslog" => 1.00,
	"Log::Log4perl" => 1.00,
	"Module::Load" => 0.10,
	"perfSONAR_PS::Common" => 0.09,
	"POSIX" => 0,
        "strict" => 0,
	"Time::HiRes" => 1.85,
        "warnings" => 0,
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

	if [ ! -f $(sysconfdir)/perfsonar/collector.conf ]; then \
	    touch $(sysconfdir)/perfsonar/collector.conf; \
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

	if [ -f $(INSTALLBIN)/perfsonar-collector ]; then \
		install -c -D -m 0755 perfsonar-collector.init $(sysconfdir)/init.d/perfsonar-collector; \
		awk "{gsub(/^VARDIR=.*/,\"VARDIR=$(vardir)\"); gsub(/^BINDIR=.*/,\"BINDIR=$(INSTALLBIN)\"); gsub(/^PREFIX=.*/,\"PREFIX=$(PREFIX)\"); gsub(/^CONFDIR=.*/,\"CONFDIR=$(sysconfdir)\"); print}" $(sysconfdir)/init.d/perfsonar-collector > $(sysconfdir)/init.d/perfsonar-collector.new; \
		mv -f $(sysconfdir)/init.d/perfsonar-collector.new $(sysconfdir)/init.d/perfsonar-collector; \
		chmod +x $(sysconfdir)/init.d/perfsonar-collector; \
	elif [ -f $(INSTALLSITEBIN)/perfsonar-collector ]; then \
		install -c -D -m 0755 perfsonar-collector.init $(sysconfdir)/init.d/perfsonar-collector; \
		awk "{gsub(/^VARDIR=.*/,\"VARDIR=$(vardir)\"); gsub(/^BINDIR=.*/,\"BINDIR=$(INSTALLSITEBIN)\"); gsub(/^PREFIX=.*/,\"PREFIX=$(PREFIX)\"); gsub(/^CONFDIR=.*/,\"CONFDIR=$(sysconfdir)\"); print}" $(sysconfdir)/init.d/perfsonar-collector > $(sysconfdir)/init.d/perfsonar-collector.new; \
		mv -f $(sysconfdir)/init.d/perfsonar-collector.new $(sysconfdir)/init.d/perfsonar-collector; \
		chmod +x $(sysconfdir)/init.d/perfsonar-collector; \
	elif [ -f $(INSTALLVENDORBIN)/perfsonar-collector ]; then \
		install -c -D -m 0755 perfsonar-collector.init $(sysconfdir)/init.d/perfsonar-collector; \
		awk "{gsub(/^VARDIR=.*/,\"VARDIR=$(vardir)\"); gsub(/^BINDIR=.*/,\"BINDIR=$(INSTALLVENDORBIN)\"); gsub(/^PREFIX=.*/,\"PREFIX=$(PREFIX)\"); gsub(/^CONFDIR=.*/,\"CONFDIR=$(sysconfdir)\"); print}" $(sysconfdir)/init.d/perfsonar-collector > $(sysconfdir)/init.d/perfsonar-collector.new; \
		mv -f $(sysconfdir)/init.d/perfsonar-collector.new $(sysconfdir)/init.d/perfsonar-collector; \
		chmod +x $(sysconfdir)/init.d/perfsonar-collector; \
	fi;

	if [ -f $(INSTALLBIN)/perfsonar-collector ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/perfsonar; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLPRIVLIB)\"); gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLBIN)/perfsonar-collector > $(INSTALLBIN)/perfsonar-collector.new; \
		mv -f $(INSTALLBIN)/perfsonar-collector.new $(INSTALLBIN)/perfsonar; \
		chmod +x $(INSTALLBIN)/perfsonar; \
	elif [ -f $(INSTALLSITEBIN)/perfsonar-collector ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLSITEBIN)/perfsonar; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLSITELIB)\"); gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLSITEBIN)/perfsonar-collector > $(INSTALLSITEBIN)/perfsonar-collector.new; \
		mv -f $(INSTALLSITEBIN)/perfsonar-collector.new $(INSTALLSITEBIN)/perfsonar; \
		chmod +x $(INSTALLSITEBIN)/perfsonar; \
	elif [ -f $(INSTALLVENDORBIN)/perfsonar-collector ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLVENDORBIN)/perfsonar; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLVENDORLIB)\"); gsub(/XXX_CONFDIR_XXX/,\"$(sysconfdir)/perfsonar\"); print}" $(INSTALLVENDORBIN)/perfsonar-collector > $(INSTALLVENDORBIN)/perfsonar-collector.new; \
		mv -f $(INSTALLVENDORBIN)/perfsonar-collector.new $(INSTALLVENDORBIN)/perfsonar; \
		chmod +x $(INSTALLVENDORBIN)/perfsonar; \
	fi;

	if [ -f $(INSTALLBIN)/psConfigureCollectors ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/psConfigureCollectors; \
		awk "{gsub(/XXX_DEFAULT_XXX/,\"$(sysconfdir)/perfsonar/collector.conf\"); print}" $(INSTALLBIN)/psConfigureCollectors > $(INSTALLBIN)/psConfigureCollectors.new; \
		mv -f $(INSTALLBIN)/psConfigureCollectors.new $(INSTALLBIN)/psConfigureCollectors; \
		chmod +x $(INSTALLBIN)/psConfigureCollectors; \
	elif [ -f $(INSTALLSITEBIN)/psConfigureCollectors ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLSITEBIN)/psConfigureCollectors; \
		awk "{gsub(/XXX_DEFAULT_XXX/,\"$(sysconfdir)/perfsonar/collector.conf\"); print}" $(INSTALLSITEBIN)/psConfigureCollectors > $(INSTALLSITEBIN)/psConfigureCollectors.new; \
		mv -f $(INSTALLSITEBIN)/psConfigureCollectors.new $(INSTALLSITEBIN)/psConfigureCollectors; \
		chmod +x $(INSTALLSITEBIN)/psConfigureCollectors; \
	elif [ -f $(INSTALLVENDORBIN)/psConfigureCollectors ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLVENDORBIN)/psConfigureCollectors; \
		awk "{gsub(/XXX_DEFAULT_XXX/,\"$(sysconfdir)/perfsonar/collector.conf\"); print}" $(INSTALLVENDORBIN)/psConfigureCollectors > $(INSTALLVENDORBIN)/psConfigureCollectors.new; \
		mv -f $(INSTALLVENDORBIN)/psConfigureCollectors.new $(INSTALLVENDORBIN)/psConfigureCollectors; \
		chmod +x $(INSTALLVENDORBIN)/psConfigureCollectors; \
	fi;
';}
