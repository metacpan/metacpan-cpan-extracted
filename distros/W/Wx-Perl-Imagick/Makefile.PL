use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Wx::Perl::Imagick',
    AUTHOR              => 'Jouke Visser <jouke@cpan.org>',
    VERSION_FROM        => 'lib\Wx\Perl\Imagick.pm',
    ABSTRACT_FROM       => 'lib\Wx\Perl\Imagick.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Wx'            => 0,
        'Image::Magick' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Wx-Perl-Imagick-*' },
);
