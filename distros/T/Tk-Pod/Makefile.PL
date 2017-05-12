# -*- perl -*-

use ExtUtils::MakeMaker;

$DIST_VERSION = "0.9943";
$is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
$min_eumm_version = 6.54;
$eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= $min_eumm_version;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<EOF;
dist :
	\$(NOECHO) \$(ECHO) "Sorry, use a newer EUMM, at least version $min_eumm_version!"

EOF
    };
}

if ($is_devel_host) {
    open(P, "Pod.pm") or die "Can't open Pod.pm: $!";
 SEARCH_FOR_DIST_VERSION: {
       while(<P>) {
           if (/DIST_VERSION\s*=\s*["'](.*)["']/) {
               if ($DIST_VERSION ne $1) {
                   die "Please adjust DIST_VERSION in Makefile.PL ($DIST_VERSION vs $1)";
               }
               last SEARCH_FOR_DIST_VERSION;
           }
       }
       die "Cannot find DIST_VERSION definition in Pod.pm";
    }
}

my %add_prereq_pm;
if (eval { require Tk::Tree; 1 } && $Tk::Tree::VERSION eq '4.6') {
    warn <<EOF;
**********************************************************************
* You have Tk::Tree $Tk::Tree::VERSION, which is broken.
**********************************************************************
EOF
    $add_prereq_pm{"Tk::Tree"} = "4.7";
}

if ($] < 5.009003) {
    warn <<EOF;
**********************************************************************
* Warnings looking like
*    Unknown escape E<0x107>
* are expected and may be ignored.
**********************************************************************
EOF
}

WriteMakefile(
	'PREREQ_PM'	=> { 'Tk'             => 800.004,
			     'Pod::Simple'    => 2.05, # there at least in 2.03 bugs when processing "-f ..." output
			     'File::Temp'     => 0,
			     'File::Spec'     => 0,
			     ## the following are only corequisites, see optional_features
	                     #'Text::English'  => 0,
			     #'Tk::HistEntry'  => 0.40,
			     ## very very optional corequisites, see optional_features
			     # 'Tk::WidgetDump' => 0,
			     # 'Module::Refresh' => 0,
			     %add_prereq_pm,
			   },
	'DISTNAME'	=> 'Tk-Pod',
	'NAME'		=> 'Tk::Pod',
	'VERSION'	=> $DIST_VERSION,
	'LICENSE'	=> 'perl',

	'DIR'		=> [],	# Tk-Pod dist build dir is ignored

	'EXE_FILES'	=> [ 'tkpod', 'tkmore' ],

	'dist' 		=> {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},

	($eumm_recent_enough ?
          (ABSTRACT   => 'Pod browser widget for Tk',
           AUTHOR     => 'Slaven Rezic <srezic@cpan.org>',
	   META_MERGE => {
	    resources => { repository => 'git://github.com/eserte/tk-pod.git' },
	    optional_features => {
	      fulltext_search => {
		description => "Enable the full-text search",
		requires => {
		  'Text::English' => 0,
		},
	      },
	      nicer_gui => {
		description => "Provide a nicer GUI",
		requires => {
		  'Tk::HistEntry' => '0.4',
		  'Tk::ToolBar'   => 0,
		},
	      },
	      debugging => {
		description => "Debugging and development helper",
		requires => {
		  'Tk::WidgetDump' => 0,
		  'Module::Refresh' => 0,
		  'Devel::Hide' => 0,
		},
	      },
	      gzip_support => {
	        description => "gzip support in tkmore",
		requires => {
		  'PerlIO::gzip' => 0,
		},
	      },
	      external_links => {
	        description => "support for links using an external browser",
		requires => {
		  'URI::Escape' => 0,
		},
	      },
	    },
	  }) : ()),

);

# This rule ensures that we get UNKNOWN test results on Unix platforms
# if no X11 DISPLAY is available. This does not apply for cygwin/X11;
# the display test there is done in the test files using
# TkTest::display_test
sub MY::test_via_harness {
    my($self, $perl, $tests) = @_;
    qq{\t$perl "-It" "-MTkTest" }.
	qq{"-e" "check_display_test_harness(\$(TEST_VERBOSE), '\$(INST_LIB)', '\$(INST_ARCHLIB)')" $tests\n};
}

sub MY::postamble {
    my $postamble = <<'EOF';
demo :: pure_all
	$(FULLPERL) -w -Mblib $(INST_SCRIPT)$(DFSEP)tkpod -tree -nodebug

EOF

    if ($is_devel_host) {
	$postamble .= <<'EOF';

# Test::Distribution complains about Text::English (which is optional)
# and a number of Tk::* widgets which are part of Tk
#
# "use" fails if Text::English is not installed which is needed
# by Tk::Pod::Search_db (which is only optionally used)
#
# "version" automatically turns "use" on, so has to be turned off, too.
PERL_TEST_DISTRIBUTION_OPTS=not podcover,prereq,use,versions

.include "../../perl.release.mk"
.include "../../perl.git.mk"

update-WWWBrowser:
	perl -nle '\
	    BEGIN { print "# DO NOT EDIT\n# Created by the update-WWWBrowser makefile rule\n\n# DO NOT USE THIS MODULE IN YOUR PROJECTS\n# (That is, the module\047s code is OK, but don\047t rely on the package\n# name or the API of this module)" } \
	    s{package WWWBrowser}{package # hide from PAUSE indexer\n\tTk::Pod::WWWBrowser}; \
	    s{package Launcher::WWW}{package # hide from PAUSE indexer\n\tTk::Pod::Launcher::WWW}; \
	    if (m{#.*Forward compatibility}) { \
		$$skip_forward_compat++; \
	    } elsif ($$skip_forward_compat && m|^}|) { \
		$$skip_forward_compat = 0; next; \
	    } \
	    if (m{__END__}) { \
		$$do_not_print++; \
	    } \
	    print if (!$$do_not_print && !$$skip_forward_compat); \
	    ' \
	    < ../../perl/WWWBrowser/WWWBrowser.pm > Pod/WWWBrowser.pm~
	    perl -c Pod/WWWBrowser.pm~
	    mv Pod/WWWBrowser.pm~ Pod/WWWBrowser.pm

EOF
    }

    $postamble;
}
