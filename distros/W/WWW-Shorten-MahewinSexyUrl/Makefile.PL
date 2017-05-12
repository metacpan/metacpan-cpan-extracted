use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Shorten::MahewinSexyUrl',
    AUTHOR        => q{Natal Ngétal <hobbestig@cpan.org>},
    VERSION_FROM  => 'lib/WWW/Shorten/MahewinSexyUrl.pm',
    ABSTRACT_FROM => 'lib/WWW/Shorten/MahewinSexyUrl.pm',
    PREREQ_PM => {
        'Test::More'   => 0,
        'WWW::Shorten' => 3.00,
    },
);
