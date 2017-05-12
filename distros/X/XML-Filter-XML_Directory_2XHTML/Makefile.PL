use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'XML::Filter::XML_Directory_2XHTML',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/XML/Filter/XML_Directory_2XHTML.pm',
	      'PREREQ_PM'    => {
				 XML::Filter::XML_Directory_2::Base => '1.4.4',
				 Carp                               => '0',
				 File::Basename                     => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
