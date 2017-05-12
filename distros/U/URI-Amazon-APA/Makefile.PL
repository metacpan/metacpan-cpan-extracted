use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'URI::Amazon::APA',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/URI/Amazon/APA.pm',
    ABSTRACT_FROM       => 'lib/URI/Amazon/APA.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Encode'      => 2.00,
        'Test::More'  => 0,
        'URI'         => 1.36,
        'URI::Escape' => 0,
        'Digest::SHA' => 0,
      },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'URI-Amazon-APA-*' },
);
