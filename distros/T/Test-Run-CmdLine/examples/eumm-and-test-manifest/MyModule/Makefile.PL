use strict;
use warnings;
use ExtUtils::MakeMaker;

{
    package MY;

    sub test_via_harness {
        my($self, $perl, $tests) = @_;

        return qq|\t$perl "-MTest::Manifest" | .
          qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
            qq|'\$(INST_ARCHLIB)')"\n|;
    }
}

sub MY::postamble {
    return <<'MAKE_FRAG';

runtest: pure_all
	$(PERLRUNINST) -Itestlib -MTest::Run::CmdLine::WithTestManifest -e "Test::Run::CmdLine::WithTestManifest::run_t_manifest($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)', $(TEST_LEVEL));"

distruntest: distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) runtest $(PASTHRU)

MAKE_FRAG
}

WriteMakefile(
    NAME                => 'MyModule',
    AUTHOR              => 'Shlomi Fish <shlomif@cpan.org>',
    VERSION_FROM        => 'lib/MyModule.pm',
    ABSTRACT_FROM       => 'lib/MyModule.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MyModule-*' },
);
