use 5.008000;
use ExtUtils::MakeMaker;

# Read the parameters from Triceps Makefiles
delete $ENV{MAKEFLAGS}; # these cause spurious messages from make
delete $ENV{MAKELEVEL};

# Some broken Perl builds return the non-0 code, this handles them.
my $xxx = `echo xxx`;
die "The shell calling does not seem to work: $!\n(got '$xxx')" unless ($xxx eq "xxx\n");
my $exp_bang = $!;
my $exp_err = $?;

my $TRICEPS_CONF = `make --quiet -f ../../cpp/Makefile.inc getconf`;
die "Failed to read the configuration: $!" if ($! != $exp_bang);
die "Failed to read the configuration: error code $?" if ($? != $exp_err);
my $TRICEPS_XLIB = `make --quiet -f ../../cpp/Makefile.inc getxlib`;
die "Failed to read the configuration: $!" if ($! != $exp_bang);
die "Failed to read the configuration: error code $?" if ($? != $exp_err);
my $TRICEPS_LIBRARY = `make --quiet -f ../../cpp/Makefile.inc getlib`;
die "Failed to read the configuration: $!" if ($! != $exp_bang);
die "Failed to read the configuration: error code $?" if ($? != $exp_err);

chomp $TRICEPS_CONF;
chomp $TRICEPS_XLIB;
chomp $TRICEPS_LIBRARY;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Triceps',
    VERSION_FROM      => 'lib/Triceps.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Triceps.pm', # retrieve abstract from module
       AUTHOR         => 'Sergey Babkin <babkin@users.sf.net>') : ()),
    LIBS              => [$TRICEPS_XLIB], # e.g., '-lm'
    DEFINE            => $TRICEPS_CONF, # e.g., '-DHAVE_SOMETHING'
    INC               => '-I../../cpp', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    MYEXTLIB          => '../../cpp/build/lib' . $TRICEPS_LIBRARY . '$(LIB_EXT)', # embed the static version into Perl shared module
	CC                => 'g++ -Wno-unused-variable',
	LD                => 'g++',
);

sub MY::postamble {
"
# This may not work very well on all machines because the Perl parser leaves
# a lot of dynamically allocated stuff unfreed, and your luck with valgrind
# suppressions may vary.
# Also I've copy-pasted the actual command from Makefile target test_dynamic 
# which might not work so well with a different version of MakeMaker
vtest: pure_all
	PERL_DL_NONLAZY=1 valgrind --leak-check=full -v --gen-suppressions=all --suppressions=vg.supp /\$(FULLPERLRUN) \"-MExtUtils::Command::MM\" \"-e\" \"test_harness(1, '\$(INST_LIB)', '\$(INST_ARCHLIB)')\" \$(TEST_FILES) 2>test.vg
	\@grep \"ERROR SUMMARY: .*[^0].* errors from\" test.vg && { echo \"  FAIL MEMCHK\" >&2; exit 1; } || true
	\@grep \"are definitely lost\" test.vg && { echo \"  FAIL LEAK\" >&2; exit 1; } || true
	\@echo 'Valgrind test OK'

# the quick test is the default one
qtest: test

clean::
	rm -f core.* *.core core vgcore.* test.vg Makefile.old

clobber:
	rm -f \$(O_FILES) \$(INST_DYNAMIC) \$(INST_STATIC)

Triceps.c: const-c.inc const-xs.inc

\$(O_FILES): TricepsPerl.h 

AggregatorType.o IndexType.o: PerlAggregator.h

AggregatorType.o Label.o Unit.o UnitTracer.o IndexType.o: PerlCallback.h

TricepsPerl.o: PerlCallback.h

PerlCallback.o: PerlCallback.h PerlValue.h

PerlApp.o: PerlApp.h

PerlValue.o: PerlValue.h

TrackedFile.o: TrackedFile.h

PerlAggregator.o: PerlCallback.h PerlAggregator.h WrapAggregatorContext.h

AggregatorContext.o: WrapAggregatorContext.h

TricepsOpt.o: TricepsOpt.h

FnReturn.o: PerlCallback.h TricepsOpt.h

FnBinding.o: PerlCallback.h

App.o: PerlApp.h

TrieadOwner.o: PerlApp.h PerlTrieadJoin.h PerlCallback.h TricepsOpt.h TrackedFile.h

";
}

if (0) {
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Triceps',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
}
