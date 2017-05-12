use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Wx::Perl::Packager',
    AUTHOR              => 'Mark Dootson <mdootson@cpan.org>',
    VERSION_FROM        => 'lib/Wx/Perl/Packager.pm',
    PL_FILES            => {},
    PREREQ_PM           => { Wx => 0.49, 'Class::Accessor' => 0, 'Digest::MD5' => 0 },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Wx-Perl-Packager-*' },
    EXE_FILES           => [ 'bin/wxpar'],
);

