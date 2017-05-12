use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;

WriteMakefile(
	NAME                => 'Web::Feed',
	AUTHOR              => q{Gabor Szabo <szabgab@cpan.org>},
	VERSION_FROM        => 'lib/Web/Feed.pm',
	ABSTRACT            => 'Generate Atom and RSS feeds',
	MIN_PERL_VERSION    => '5.010',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'DateTime::Tiny'       => 0,
		'Time::Local'          => 0,
		'Test::More'           => 0,
		'POSIX'                => 0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'http://github.com/szabgab/Web-Feed.git',
				web  => 'http://github.com/szabgab/Web-Feed',
			}
		}})
		: ()
	),
);
