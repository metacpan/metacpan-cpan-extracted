use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "XMLRPC::PurePerl",
              VERSION_FROM => 'lib/XMLRPC/PurePerl.pm',
	      PREREQ_PM => { 
		'HTTP::Request' => '0', 
		'LWP::UserAgent' => '0' 
	      },
              dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              AUTHOR          => 'Ryan Dietrich <ryan[at]dietrich.net>',
	      ABSTRACT        => 'Implements the XMLRPC transport protocol'
             );
