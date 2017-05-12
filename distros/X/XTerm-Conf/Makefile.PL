use 5.006;
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
    NAME                => 'XTerm::Conf',
    VERSION_FROM        => 'lib/XTerm/Conf.pm',
    EXE_FILES           => ['xterm-conf'],
    PREREQ_PM		=> {
	'Getopt::Long'  => 2.24,
	'Term::ReadKey' => 0,
    },
    AUTHOR              => 'Slaven Rezic <srezic@cpan.org>',
    ABSTRACT_FROM       => 'lib/XTerm/Conf.pm',
    ($eumm_recent_enough ?
	(META_ADD => { resources => { repository => 'git://github.com/eserte/xterm-conf.git' } }) : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48 ?
	(MIN_PERL_VERSION => 5.006) : ()),
);

sub MY::postamble {
    my $postamble = '';

    if ($is_devel_host) {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
