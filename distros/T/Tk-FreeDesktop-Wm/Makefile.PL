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
    NAME              => 'Tk::FreeDesktop::Wm',
    VERSION_FROM      => 'lib/Tk/FreeDesktop/Wm.pm', # finds $VERSION
    PREREQ_PM         => {
        Tk => 402,
    },
    LICENSE	      => 'perl',
    ($] >= 5.005 ?
      (ABSTRACT       => 'bring Tk and freedesktop together',
       AUTHOR         => 'Slaven Rezic <srezic@cpan.org>') : ()),

    ($eumm_recent_enough
     ? (META_ADD => { resources  => { repository => 'git://github.com/eserte/tk-freedesktop-wm.git' } }) : ()),

);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_CHANGES=yes

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
