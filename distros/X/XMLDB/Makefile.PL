use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XMLDB',
    AUTHOR              => q{Ded MedVed <dedmedved@cpan>},
    VERSION_FROM        => 'lib/XMLDB.pm',
    ABSTRACT_FROM       => 'lib/XMLDB.pm',
    MIN_PERL_VERSION    => 5.10.0,
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => [ ],
    PREREQ_PM => {
        'Test::More'            => 0,
        'Carp'                  => 0,
        'DBD::ODBC'             => 0,
        'DBI'                   => 0,
        'Data::Dumper'          => 0,
        'English'               => 0,
        'Getopt::Euclid'        => 0,
        'Graph'                 => 0.90,
        'List::Util'            => 1.00,
        'POSIX'                 => 0,
        'autodie'               => 0,
        'indirect'              => 0,
        'version'               => 0,
		'XML::Simple'			=> 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'StaticData-*' },
);



