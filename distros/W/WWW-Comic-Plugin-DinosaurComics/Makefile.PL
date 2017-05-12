use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Comic::Plugin::DinosaurComics',
    AUTHOR              => q{Luke Poskitt <ltp@cpan.org>},
    VERSION_FROM        => 'lib/WWW/Comic/Plugin/DinosaurComics.pm',
    ABSTRACT_FROM       => 'lib/WWW/Comic/Plugin/DinosaurComics.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'WWW::Comic' => 0,
	'HTML::TreeBuilder' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Comic-Plugin-DinosaurComics-*' },
);
