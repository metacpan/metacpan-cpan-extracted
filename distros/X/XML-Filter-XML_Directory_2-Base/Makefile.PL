use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'XML::Filter::XML_Directory_2::Base',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/XML/Filter/XML_Directory_2/Base.pm',
	      'PREREQ_PM'    => {
				 XML::Directory                    => '0.97',
				 XML::SAX::Base                    => '1.03',
				 XML::SAX::Writer                  => '0.39',
				 XML::Filter::XML_Directory_Pruner => '1.3',
				 Digest::MD5                       => '0',
				 Carp                              => '0',
				 File::Basename                    => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
