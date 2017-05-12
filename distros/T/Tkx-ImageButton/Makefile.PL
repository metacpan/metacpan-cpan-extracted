use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tkx::ImageButton',
    AUTHOR              => q{Alexander Nusov <cpan@sancode.net>},
    VERSION_FROM        => 'lib/Tkx/ImageButton.pm',
    ABSTRACT_FROM       => 'lib/Tkx/ImageButton.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
	INSTALLDIRS         => 'site',
    PREREQ_PM => {
        'Test::More' => 0,
	'Tkx' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tkx-ImageButton-*' },
);
