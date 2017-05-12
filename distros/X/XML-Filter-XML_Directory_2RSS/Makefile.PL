use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'XML::Filter::XML_Directory_2RSS',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/XML/Filter/XML_Directory_2RSS.pm',
	      'PREREQ_PM'    => {
				 XML::Directory                    => '0.96',
				 XML::SAX::Base                    => '1.04',
				 XML::SAX::Writer                  => '0.39',
				 XML::Filter::XML_Directory_Pruner => '1.0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
