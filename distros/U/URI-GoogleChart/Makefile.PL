use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'URI::GoogleChart',
    VERSION_FROM => 'lib/URI/GoogleChart.pm',
    ABSTRACT_FROM => 'lib/URI/GoogleChart.pm',
    AUTHOR       => 'Gisle Aas <gisle@activestate.com>',
    LICENSE	 => 'perl',

    MIN_PERL_VERSION => 5.006,
    PREREQ_PM    => {
	URI => 1,
    },
    META_MERGE   => {
        build_requires => { 'Test::More' => 0 },
        recommends => { 'LWP' => 0 },
        resources => {
            repository => 'http://github.com/gisle/uri-googlechart',
        }
    },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f "MANIFEST.SKIP";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
