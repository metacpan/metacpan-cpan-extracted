use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

our %PREREQ_PM =
(
    DBI => 1.625,
    Dancer => 1.31,
    Expect => 1.21,
    threads => 1.80,
    DateTime => 1.03,
    'IO::Stty' => 0.03,
    'YAML::XS' => 0.41,
    'DBD::SQLite' => 1.37,
    'Getopt::Long' => 2.38,
    'Thread::Queue' => 2.12,
    'IO::Socket::Multicast' => 1.12,
);

our $PKG_NAME = 'pantheon';
our $PKG_FILE = "lib/$PKG_NAME.pm";

WriteMakefile
(
    AUTHOR        => 'Kan Liu <kan@cpan.org>',
    NAME          => $PKG_NAME,
    VERSION_FROM  => $PKG_FILE,
    ABSTRACT_FROM => $PKG_FILE,
    PREREQ_PM     => \%PREREQ_PM, 
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => [ "$PKG_NAME-*", qw( *.in *.ex ) ] },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( LICENSE => 'perl' ) : () ),
);
