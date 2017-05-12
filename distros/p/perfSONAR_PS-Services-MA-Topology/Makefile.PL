use ExtUtils::MakeMaker;

my @exe_files = ( "psLoadTopology" );

WriteMakefile(
    'NAME' => 'perfSONAR_PS::Services::MA::Topology',
    'VERSION_FROM' => 'lib/perfSONAR_PS/Services/MA/Topology.pm',
    'AUTHOR' => 'Aaron Brown <aaron@internet2.edu>',
    'PREREQ_PM' => {
	"base" => 0,
	"Cwd" => 0,
	"fields" => 0,
	"File::Basename" => 0,
	"Getopt::Long" => 0,
	"lib" => 0,
	"Log::Log4perl" => 1.00,
	"Params::Validate" => 0.64,
	"perfSONAR_PS::Client::LS::Remote" => 0.09,
	"perfSONAR_PS::Client::Topology::MA" => 0.09,
	"perfSONAR_PS::Client::Topology::XMLDB" => 0.09,
	"perfSONAR_PS::Common" => 0.09,
	"perfSONAR_PS::Messages" => 0.09,
	"perfSONAR_PS::Services::Base" => 0.09,
	"perfSONAR_PS::Topology::Common" => 0.09,
	"perfSONAR_PS::Topology::ID" => 0.09,
        "strict" => 0,
        "warnings" => 0,
	"XML::LibXML" => 1.58,
    },

    EXE_FILES => \@exe_files,
);

package MY;

sub postamble {'

install ::

	if [ -f $(INSTALLBIN)/psLoadTopology ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/psLoadTopology; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLPRIVLIB)\"); print}" $(INSTALLBIN)/psLoadTopology > $(INSTALLBIN)/psLoadTopology.new; \
		mv -f $(INSTALLBIN)/psLoadTopology.new $(INSTALLBIN)/psLoadTopology; \
		chmod +x $(INSTALLBIN)/psLoadTopology; \
	elif [ -f $(INSTALLSITEBIN)/psLoadTopology ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/psLoadTopology; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLSITELIB)\"); print}" $(INSTALLBIN)/psLoadTopology > $(INSTALLBIN)/psLoadTopology.new; \
		mv -f $(INSTALLBIN)/psLoadTopology.new $(INSTALLBIN)/psLoadTopology; \
		chmod +x $(INSTALLBIN)/psLoadTopology; \
	elif [ -f $(INSTALLVENDORBIN)/psLoadTopology ]; then \
		perl -i -p -e "s/was_installed = 0/was_installed = 1/" $(INSTALLBIN)/psLoadTopology; \
		awk "{gsub(/XXX_LIBDIR_XXX/,\"$(INSTALLVENDORLIB)\"); print}" $(INSTALLBIN)/psLoadTopology > $(INSTALLBIN)/psLoadTopology.new; \
		mv -f $(INSTALLBIN)/psLoadTopology.new $(INSTALLBIN)/psLoadTopology; \
		chmod +x $(INSTALLBIN)/psLoadTopology; \
	fi;
';}
