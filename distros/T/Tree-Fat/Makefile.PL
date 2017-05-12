use 5.005; # not strictly necessary but upgrading is healthy
use ExtUtils::MakeMaker;

my $testmode = 0;
my $insure = 0;

my @tvlib = (qw/tv.code tv.seek tv.private tv.public tv.sym tv.setup
	     tvcommon.h tvcommon.c tvcommon0.h/);

@OBJ = ();
@PREREQ = ();
@FLAGS = ();
unlink "tietv.tmpl", "tvcommon0.h";
if ($testmode) {
    warn "...setting symlinks for testing\n";
    symlink "setup/tv.test", "tietv.tmpl";
    symlink "setup/tvcommon0.test", "tvcommon0.h";
    if (0) {
	push(@OBJ, qw(cover1.o cover2.o ccov_registry.o));
	push(@PREREQ, 'Devel::CCov' => 0.08, 'Time::HiRes' => '01.16');
    } else {
	push(@OBJ, qw(tietv.o tvcommon.o));
    }
    push @FLAGS, OPTIMIZE => '-g';
    push @FLAGS, CC => 'insure', LD => 'insure' if $insure;
} else {
    warn "...setting symlinks for launch\n";
    symlink "setup/tv.prod", "tietv.tmpl";
    symlink "setup/tvcommon0.prod", "tvcommon0.h";
    push @OBJ, qw(tietv.o tvcommon.o);
}

#my $prof = '-fprofile-arcs -ftest-coverage';

my @PREFIX = (PREFIX => $ENV{PERL5PREFIX})
	if exists $ENV{PERL5PREFIX};

WriteMakefile(
	      @PREFIX,
	      @FLAGS,
	      NAME		=> 'Tree::Fat',
	      PREREQ_PM		=> { Test => 1, @PREREQ },
	      EXE_FILES		=> [qw(tvgen.pl)],
	      INC => '-I.',
	      VERSION_FROM	=> 'Fat.pm',
	      OBJECT		=> join(' ', qw(Fat.o), @OBJ),
	      PM		=> { 
				    'Fat.pm' => '$(INST_LIBDIR)/Fat.pm',
				    (map { $_=>'$(INST_LIBDIR)/Fat/'.$_ } @tvlib)
				   },
);

sub MY::postamble {
    '
tvgen.pl :: pm_to_blib

Fat.xs :: tietv.h

tietv.c tietvpriv.h tietvpub.h tietv.h :: $(INST_SCRIPT)/tvgen.pl tietv.tmpl
	$(PERL) -Mblib $(INST_SCRIPT)/tvgen.pl -t -p tie

cover1.c :: tvcommon.c
	ccovinstrument -c tvcommon.c -o $*.c -e $*.err

cover2.c :: tietv.c
	ccovinstrument -c tietv.c -o $*.c -e $*.err

ccov_registry$(OBJ_EXT): .ccov-timestamp
	ccovinstrument -r
	$(CCCMD) $(CCCDLFLAGS) $*.c

clean ::
	-rm -rf tietv*.[ch] *.ch cover[12].c *.err tvcommon0.h tietv.tmpl
	-rm -f ccov_registry.* .ccov-timestamp

';
}

#sub MY::makeaperl {
#    my $s = shift->MY::SUPER::makeaperl(@_);
#    $s =~ s/^MAP_LINKCMD.*$/MAP_LINKCMD = \$(PURIFY)/;
#    $s;
#}

__END__


