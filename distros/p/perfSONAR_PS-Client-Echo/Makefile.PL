use ExtUtils::MakeMaker;

my @exe_files = ( "psping" );

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Client::Echo',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Client/Echo.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
        "strict" => 0,
        "Cwd" => 0,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Transport" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::XML::Document_string" => 0.09,
	"Log::Log4perl" => 1.00,
	"Test::More" => 0,
	"Time::HiRes" => 1.85,
    },

    EXE_FILES => \@exe_files,
);

package MY;

sub postamble {'

install ::

	if [ -f $(INSTALLBIN)/psping ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/psping; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLPRIVLIB)\"); print}" $(INSTALLBIN)/psping > $(INSTALLBIN)/psping.new; \
		mv -f $(INSTALLBIN)/psping.new $(INSTALLBIN)/psping; \
		chmod +x $(INSTALLBIN)/psping; \
	elif [ -f $(INSTALLSITEBIN)/psping ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLSITEBIN)/psping; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLSITELIB)\"); print}" $(INSTALLSITEBIN)/psping > $(INSTALLSITEBIN)/psping.new; \
		mv -f $(INSTALLSITEBIN)/psping.new $(INSTALLSITEBIN)/psping; \
		chmod +x $(INSTALLSITEBIN)/psping; \
	elif [ -f $(INSTALLVENDORBIN)/psping ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLVENDORBIN)/psping; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLVENDORLIB)\"); print}" $(INSTALLVENDORBIN)/psping > $(INSTALLVENDORBIN)/psping.new; \
		mv -f $(INSTALLVENDORBIN)/psping.new $(INSTALLVENDORBIN)/psping; \
		chmod +x $(INSTALLVENDORBIN)/psping; \
	fi;
';}
