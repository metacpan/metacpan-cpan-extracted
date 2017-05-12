use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'WWW::Grooveshark',
	ABSTRACT_FROM    => 'lib/WWW/Grooveshark.pm',
	VERSION_FROM     => 'lib/WWW/Grooveshark.pm',
	AUTHOR           => 'Miorel-Lucian Palii <mlpalii@gmail.com>',
	LICENSE          => 'perl',
	META_MERGE       => {resources =>
		{
			bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Grooveshark',
			repository => 'http://elementsofpuzzle.googlecode.com/',
		}},
	MIN_PERL_VERSION => '5.006',
	PREREQ_PM        =>
		{
			Carp           => 0,
			Digest::MD5    => 0,
			Exporter       => 0,
			JSON::Any      => 0,
			LWP::UserAgent => 0,
			NEXT           => 0.61,
			URI::Escape    => 0,
		},
);
