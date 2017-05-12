use ExtUtils::MakeMaker;

$is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
$eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(
    NAME              => 'Tk::FlatCheckbox',
    VERSION           => '0.09',
    PREREQ_PM         => { Tk => 0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Tk/FlatCheckbox.pm',
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-flatcheckbox.git' } }) : ()),
);

sub MY::postamble {
    my($MY) = @_;

    my $postamble = "";

    if ($MY && UNIVERSAL::can($MY, "oneliner")) {
	my($demo1, $demo2);
	if (eval { require File::Spec; 1; }) {
	    $demo1 = File::Spec->catfile(qw(t Tk-FlatCheckbox.t));
	    $demo2 = File::Spec->catfile(qw(t Tk-FlatRadiobutton.t));
	} else {
	    $demo1 = "t/Tk-FlatCheckbox.t";
	    $demo2 = "t/Tk-FlatRadiobutton.t";
	}
	my $demo_oneliner = $MY->oneliner(q{$$ENV{BATCH}=0; system("$$^X -Mblib } . $demo1 .q{"); system("$$^X -Mblib } . $demo2 . q{")});
	$postamble = <<EOF;
demo :: pure_all
	$demo_oneliner

EOF
    } elsif ($^O ne "MSWin32") {
	$postamble = <<'EOF';
demo :: pure_all
	env BATCH=0 ${MAKE} test

EOF
    }

    if ($is_devel_host) {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
