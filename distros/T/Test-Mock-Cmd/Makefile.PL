use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::Mock::Cmd',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Test/Mock/Cmd.pm',
    ABSTRACT_FROM => 'lib/Test/Mock/Cmd.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,    # for testing, I know I know: Test::XT
        'Test::Carp' => 0,    # for testing
                              # 'Test::Output' => 0, # for testing
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-Mock-Cmd-*' },
);
