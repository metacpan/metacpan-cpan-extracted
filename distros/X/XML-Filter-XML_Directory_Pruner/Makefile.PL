use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'XML::Filter::XML_Directory_Pruner',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/XML/Filter/XML_Directory_Pruner.pm',
	      'PREREQ_PM'    => {
				 XML::Directory => '0.97',
				 XML::SAX::Base => '1.02',
				 MIME::Types    => '0.4',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
