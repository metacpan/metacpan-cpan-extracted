use 5.6.1;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Taint',
    VERSION_FROM        => 'Taint.pm',
    ABSTRACT            => "Checks for taintedness of variables",
    PREREQ_PM => {
        'overload'      => 0,
        'Scalar::Util'  => 0,
        'Test::Builder' => 0,
        'Test::More'    => 0,
        'Tie::Array'    => 0,
        'Tie::Hash'     => 0,
        'Tie::Scalar'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Taint-*' },
);

sub MY::postamble {
    return <<'MAKE';
.PHONY: critic

critic:
	perlcritic -1 -q -profile perlcriticrc Taint.pm t/*.t
MAKE
}
