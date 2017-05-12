use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::StubGenerator',
    AUTHOR              => 'Kent Cowgill <kent@c2group.net>',
    VERSION_FROM        => 'lib/Test/StubGenerator.pm',
    ABSTRACT_FROM       => 'lib/Test/StubGenerator.pm',
    ( $ExtUtils::MakeMaker::VERSION > 6.31 ? ( LICENSE => 'perl' ) : () ),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PPI'        => 1.118,
        'Perl::Tidy' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-StubGenerator-*' },
);

sub MY::postamble {
return <<'MAKE_FRAG';
OPENCMD = open
BROWSER = /Applications/Safari.app

cover:
	rm -rf cover_db
	PERL5OPT=-MDevel::Cover=-ignore,\\\.t make test 2>&1
	make recover

mytest:
	TEST_AUTHOR=1 make test

recover:
	cover
	make report

report:
	$(OPENCMD) $(BROWSER) cover_db/coverage.html

reclean:
	rm -rf cover_db blib pm_to_blib Makefile Makefile.old MANIFEST.bak Test-StubGenerator-*
MAKE_FRAG
}
