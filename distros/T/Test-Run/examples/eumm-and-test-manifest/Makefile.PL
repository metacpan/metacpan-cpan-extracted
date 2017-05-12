# This is my version of the XML::RSS Makefile.PL. It makes use of
# Test::Manifest and I added "make runtest" and "make distruntest" targets
# to the makefile.
#
# See the MY::postamble function below for the details.

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

sub ExtUtils::MM_Any::test_via_harness {
    my($self, $perl, $tests) = @_;

    return qq|\t$perl "-MTest::Manifest" | .
      qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
        qq|'\$(INST_ARCHLIB)')"\n|;
}

# This is the function that needs to be added to add the "make runtest"
# and "make distruntest" targets to the makefile. Note that you can add more
# makefile fragments above or below it.

sub MY::postamble {
    return <<'MAKE_FRAG';

runtest: pure_all
	perl -MFile::Spec -MTest::Run::CmdLine::Iface -MTest::Manifest -e \
        "local @INC = @INC;	unshift @INC, map { File::Spec->rel2abs(\$$_) } ('$(INST_LIB)', '$(INST_ARCHLIB)'); Test::Run::CmdLine::Iface->new({test_files => [Test::Manifest::get_t_files()]})->run();"

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
              'clean'        => { FILES => 'XML-RSS-* t/*-generated.xml' },
              @extras
);
