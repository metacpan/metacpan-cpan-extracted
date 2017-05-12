use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    'NAME'	=> 'Tk::FontDialog',
    'VERSION_FROM' => 'lib/Tk/FontDialog.pm', # finds $VERSIO
    'ABSTRACT_FROM' => 'lib/Tk/FontDialog.pm',
    'MIN_PERL_VERSION' => 5.004,
    'PREREQ_PM' => {'Tk'             => 800},
    'dist'      => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    ($eumm_recent_enough
     ? (META_MERGE => { resources => { repository => 'git://github.com/eserte/tk-fontdialog.git' },
		      })
     : ()
    ),
);

sub MY::postamble {
    my($MY) = @_;

    my $postamble = "";

    if ($MY && UNIVERSAL::can($MY, "oneliner")) {
	my $demo_oneliner = $MY->oneliner("use blib; use Tk; use Tk::FontDialog; tkinit->FontDialog->Show");
	$postamble = <<EOF;
demo :: pure_all
	$demo_oneliner

EOF
    } elsif ($^O ne "MSWin32") {
	$postamble = <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -Mblib -MTk -MTk::FontDialog -e 'tkinit->FontDialog->Show'

EOF
    }

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

# Test::Distribution complains about Tk::Font which is part of Tk
PERL_TEST_DISTRIBUTION_OPTS=not podcover,prereq

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
