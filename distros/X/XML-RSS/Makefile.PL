use 5.006;

use ExtUtils::MakeMaker;
@extras = ();

push(@extras,
     CAPI => 'TRUE')
  if ($PERL_VERSION >= 5.005 and $OSNAME eq 'MSWin32'
      and $Config{archname} =~ /-object\b/i);

push(@extras,
     ABSTRACT_FROM => 'lib/XML/RSS.pm',
     AUTHOR        => ' Ask Bjoern Hansen <ask@develooper.com>')
    if ($ExtUtils::MakeMaker::Version >= 5.4301);

if ($ExtUtils::MakeMaker::Version >= 6.36)
{
    push(@extras,
        LICENSE => "perl",
    );
}

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
              'NAME'         => 'XML::RSS',
              'VERSION_FROM' => 'lib/XML/RSS.pm', # finds $VERSION,
              'PREREQ_PM'    => {
                                 'Test::Manifest'   => '0.9',
                                 'Test::More'       => '0',
                                 'XML::Parser'      => '2.23',
                                 'HTML::Entities'   => 0,
                                 'DateTime' => 0,
                                 'DateTime::Format::Mail' => 0,
                                 'DateTime::Format::W3CDTF' => 0,
                                },
              'clean'        => { FILES => 'XML-RSS-* t/generated/*.xml' },
              'PL_FILES' => {},
              @extras
);
