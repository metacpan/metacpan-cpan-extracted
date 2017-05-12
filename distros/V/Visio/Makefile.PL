use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'dist' => {COMPRESS=>'gzip', SUFFIX => 'gz'},
	      'NAME'		=> 'Visio',
	      'VERSION_FROM'	=> 'Visio.pm', # finds $VERSION
	      'PREREQ_PM'		=> {
		  XML::LibXML=>0,
		    Carp=>0,
		    Data::Dumper=>0,
		    'Log::Log4perl' => 0
		},
	      PM => {
		  'Visio.pm' => '$(INST_LIBDIR)/Visio.pm',
		  'Visio/PageSheet.pm' => '$(INST_LIBDIR)/Visio/PageSheet.pm',
		  'Visio/PageProps.pm' => '$(INST_LIBDIR)/Visio/PageProps.pm',
		  'Visio/Master.pm' => '$(INST_LIBDIR)/Visio/Master.pm',
		  'Visio/Page.pm' => '$(INST_LIBDIR)/Visio/Page.pm',
		  'Visio/Line.pm' => '$(INST_LIBDIR)/Visio/Line.pm',
		  'Visio/Layout.pm' => '$(INST_LIBDIR)/Visio/Layout.pm',
		  'Visio/Shape.pm' => '$(INST_LIBDIR)/Visio/Shape.pm',
		  'Visio/Hyperlink.pm' => '$(INST_LIBDIR)/Visio/Hyperlink.pm',
	      },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Visio.pm', # retrieve abstract from module
       AUTHOR     => 'Aamer Akhter <aakhter@cisco.com>') : ()),
	      clean => {
		  FILES => '*~ Visio/*~'

	      }
);
