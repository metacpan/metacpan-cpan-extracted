# -*- perl -*-
use ExtUtils::MakeMaker;

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
    'NAME'	   => 'Tk::WidgetDump',
    'VERSION_FROM' => 'lib/Tk/WidgetDump.pm',
    'PREREQ_PM'    => { 'Tk' => 800,
			# The following are only CORERQUISITES
			'Tk::FontDialog' => 0,
			'Tk::ObjScanner' => 0,
			'Tk::More' => 0,
			'Tk::Pod' => 0,
			'Tk::HistEntry' => 0.33,
			'Tk::NumEntry' => 0,
		      },
    'LICENSE'	   => 'perl',
    'AUTHOR'       => 'Slaven Rezic (srezic@cpan.org)',
    ($eumm_recent_enough
     ? (META_MERGE => { resources => { repository => 'git://github.com/eserte/tk-widgetdump.git' },
		      })
     : ()
    ),
);

sub MY::postamble {
    my $postamble = '';

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
