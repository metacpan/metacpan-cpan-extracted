use 5.006000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# Add the `devtest` target to run regression and POD tests in one go
sub MY::postamble {
    return <<'END';
devtest :
	REGRESSION_TESTS=1 POD_TESTS=1 $(MAKE) test

END
}

# Override `disttest` so it would behave as `devtest`
sub MY::dist_test {
    return <<'END';
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) devtest $(PASTHRU)

END
}

my $MM_VERSION = $ExtUtils::MakeMaker::VERSION;
my $github_uri = 'https://github.com/nohuhu/Test-ExtDirect';

WriteMakefile(
    NAME              => 'Test::ExtDirect',
    VERSION_FROM      => 'lib/Test/ExtDirect.pm',
    
    ($MM_VERSION >= 6.64
        ? (
            TEST_REQUIRES => {
                'Test::More' => '0.82', # for explain()
            },
            PREREQ_PM     => {
                'RPC::ExtDirect::Server' => '1.01',
                'RPC::ExtDirect::Client' => '1.02',
            },
        )
        : ($MM_VERSION >= 6.5503
            ? ( BUILD_REQUIRES => {
                    'Test::More' => '0.82',
                },
                PREREQ_PM      => {
                    'RPC::ExtDirect::Server' => '1.01',
                    'RPC::ExtDirect::Client' => '1.02',
                },
            )
            : ( PREREQ_PM => {
                    'Test::More'             => '0.82',
                    'RPC::ExtDirect::Server' => '1.01',
                    'RPC::ExtDirect::Client' => '1.02',
                },
            ),
        ),
    ),

    ABSTRACT => 'An easy and convenient way to test Ext.Direct code',
    AUTHOR   => 'Alex Tokarev <tokarev@cpan.org>',
    LICENSE  => 'perl',

    ($MM_VERSION >= 6.48
        ? ( MIN_PERL_VERSION => 5.006000 )
        : ()
    ),

    ($MM_VERSION >= 6.46
        ? ( META_MERGE => {
                resources => {
                    bugtracker => "$github_uri/issues",
                    repository => $github_uri,
                },
            },
        )
        : ()
    ),
);

