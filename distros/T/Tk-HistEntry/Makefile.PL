# -*- perl -*-
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && ($^O =~ /bsd/i || $ENV{PERL_RELEASE_READY}) && -f "../../perl.release.mk";
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
    'NAME'	=> 'Tk::HistEntry',
    'VERSION_FROM' => 'HistEntry.pm', # finds $VERSION
    'LICENSE'   => 'perl_5',
    'dist'      => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    'PREREQ_PM' => {
		    'Tk' => 0,
		    'Test::More' => 0,
		   },
    ($] >= 5.005 ?
        (
            ABSTRACT_FROM => 'HistEntry.pm',
            AUTHOR => 'Slaven Rezic <srezic@cpan.org>',
        ) : () ),
    ($eumm_recent_enough
      ? (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-histentry.git' },
		   }) : ()),
);

sub MY::postamble {
    my $postamble = <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -Mblib examples/1.pl
	$(FULLPERL) -w -I$(SITELIBEXP)/Tk/demos/widget_lib -Mblib examples/newclass.pl

EOF

    if ($is_devel_host) {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_CHANGES=yes

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
