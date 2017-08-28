use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'sBNC::User::Summary',
    AUTHOR              => q{Mike Jones <mike@netsplit.org.uk>},
    VERSION_FROM        => 'lib/sBNC/User/Summary.pm',
    ABSTRACT_FROM       => 'lib/sBNC/User/Summary.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose'      => 0,
        'Carp'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'sBNC-User-Summary-*' },
);
