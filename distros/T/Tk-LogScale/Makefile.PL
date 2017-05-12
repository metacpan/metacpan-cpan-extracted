use strict;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
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
    'NAME'	=> 'Tk::LogScale',
    'VERSION_FROM' => 'LogScale.pm',
    'PREREQ_PM'    => {'Tk' => 0,
		       # 'Tie::Watch' => 1.00, # usually already included in modern Tk's
		      },
    'ABSTRACT_FROM' => 'LogScale.pm',
    'AUTHOR' => 'Slaven Rezic <srezic@cpan.org>',
    'LICENSE' => 'perl',

    ($eumm_recent_enough
     ? (META_ADD => { resources  => { repository => 'git://github.com/eserte/tk-logscale.git' } }) : ()),
);

sub MY::postamble {
    my $postamble = '';

    $postamble .= <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -Mblib t/logscale.t -demo

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
