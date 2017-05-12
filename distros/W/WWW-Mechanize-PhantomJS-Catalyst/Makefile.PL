use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'WWW::Mechanize::PhantomJS::Catalyst',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'lib/WWW/Mechanize/PhantomJS/Catalyst.pm',
	VERSION_FROM  => 'lib/WWW/Mechanize/PhantomJS/Catalyst.pm',
	PREREQ_PM     => { 
		Catalyst                    => '5.9', 
		'Catalyst::Plugin::Server'  => 0, 
		'WWW::Mechanize::PhantomJS' => '0.03',
		'Test::WWW::Mechanize'      => 0,
	},
	META_MERGE        => {
		resources => {
			repository => 'https://github.com/dk/WWW-Mechanize-PhantomJS-Catalyst',
		},
	},
);
