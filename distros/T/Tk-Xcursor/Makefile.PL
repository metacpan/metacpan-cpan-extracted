# -*- cperl -*-

use Tk::MMutil;

if ($^O eq 'MSWin32') {
    warn "Tk::Xcursor is not supported on non-X11 systems.\n";
    exit 0;
}

my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

use lib qw(inc);
use Devel::CheckLib;
check_lib_or_exit(lib => 'Xcursor');

Tk::MMutil::TkExtMakefile(
			  VERSION      => '0.03',
			  XS_VERSION   => '0.03', # specify explicitely, other Tk's XS_VERSION is used
			  NAME         => 'Tk::Xcursor',
			  OBJECT       => '$(O_FILES)',
			  LIBS         => ['-lXcursor'],
			  TYPEMAPS     => ['typemap'], # seems to be needed, why?
			  ($eumm_recent_enough ?
			   (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-xcursor.git' },
					  configure_requires => {
								 'Tk::MMutil' => 0,
								},
					}) : ()),
			 );

sub MY::postamble {
    my $postamble = "";

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
