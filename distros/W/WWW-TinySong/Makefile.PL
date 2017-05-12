use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'WWW::TinySong',
	ABSTRACT_FROM    => 'lib/WWW/TinySong.pm',
	VERSION_FROM     => 'lib/WWW/TinySong.pm',
	AUTHOR           => 'Miorel-Lucian Palii <mlpalii@gmail.com>',
	LICENSE          => 'perl',
	META_MERGE       => {resources =>
		{
			bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-TinySong',
			repository => 'http://elementsofpuzzle.googlecode.com/',
		}},
	MIN_PERL_VERSION => '5.006',
	PREREQ_PM        =>
		{
			Carp           => 0,
			Exporter       => 0,
			CGI            => 0,
			HTML::Parser   => 3,
			LWP::UserAgent => 0,
		},
);
