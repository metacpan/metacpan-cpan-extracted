use strict;

use lib qw[inc];
use ExtUtils::MakeMaker;
use Inline::Module;

my %WriteMakefileArgs = (
    NAME          => 'cppAdaptive2',
    ABSTRACT_FROM => 'lib/cppAdaptive2.pm',
    VERSION_FROM  => 'lib/cppAdaptive2.pm',
    INC           => '-Isrc',
    postamble     => {
        inline => {
            module => 'cppAdaptive2',
            stub   => 'cppAdaptive2::Inline',
            ilsm   => 'Inline::CPP',

            # makestub => 1,
        },
    },
);

if ( $^O eq 'MSWin32' ) {
    $WriteMakefileArgs{PREREQ_PM}{'Win32::Mutex'} = '1.09';
}

WriteMakefile(%WriteMakefileArgs);

1;
