use strict;
use warnings;
use ExtUtils::MakeMaker;

my $build_requires = { 
    'Wx'            => 0.50,
    'Time::HiRes'   => 1.20,
};

my $tarprog = 'tar';

WriteMakefile(
    NAME                => 'Wx::Perl::ProcessStream',
    AUTHOR              => 'Mark Dootson <mdootson@cpan.org>',
    ABSTRACT_FROM       => 'lib/Wx/Perl/ProcessStream.pm',
    VERSION_FROM        => 'lib/Wx/Perl/ProcessStream.pm',
    PL_FILES            => {},
    PREREQ_PM           => { %$build_requires },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', TAR => $tarprog, TARFLAGS => "cvf" },
    clean               => { FILES => 'Wx-Perl-ProcessStream-*' },
    
);


