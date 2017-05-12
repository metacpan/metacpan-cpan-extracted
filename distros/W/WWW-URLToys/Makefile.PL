use ExtUtils::MakeMaker;

my $pm = 'URLToys';

WriteMakefile(
	NAME          => "WWW::$pm",
	DISTNAME      => "WWW-$pm",
	VERSION_FROM  => "$pm.pm",
	'PREREQ_PM'	=> {
    		'LWP'	=> 0,
    		'HTTP::Cookies'	=> 0,
    		'URI::URL'	=> 0,
    		'Term::ReadLine'	=> 0,
    		'MIME::Base64'	=> 0,
	},
	dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
	($] >= 5.005 ?
		(ABSTRACT => 'URLToys Engine',
		AUTHOR   => 'Joe Drago (joe@urltoys.com)') : ( ),
  	),
);

