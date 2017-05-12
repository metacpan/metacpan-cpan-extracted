# -*- perl -*-

use 5.005; # new "for" syntax

if (!eval q{ use Date::Calc; 1 } && !eval q{ use Date::Pcalc; 1 }) {
    # It's possible to install Date::Calc without the XS parts, so
    # there's no need to advertize Date::Pcalc anymore.
    print <<EOF;

*** To select dates before 1970-01-01 and after year 2036, you need to
    install Date::Calc.

EOF
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

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tk::DateEntry',
    'VERSION_FROM' => 'DateEntry.pm', # finds $VERSION
    'PREREQ_PM' => {Tk => 400},
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => '.gz',
                    'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},
    ($eumm_recent_enough ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-dateentry.git' },
		     recommends => {'Date::Calc'     => 0,
				    'Encode'	     => 0,
				    ($^O eq 'MSWin32' ? ('Win32::OLE::NLS' => 0) : ('I18N::Langinfo' => 0)),
				    'Text::Bidi'     => 0,
				    'Tk::FireButton' => 0,
				   },
		   }) : ()),
);

sub MY::postamble {
    my $postamble = "";

    $postamble .= <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -Mblib t/dateentry.t -demo

EOF

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

PERL_TEST_DISTRIBUTION_OPTS=not podcover

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
