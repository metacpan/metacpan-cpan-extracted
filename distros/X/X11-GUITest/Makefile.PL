
# X11::GUITest ($Id: Makefile.PL 242 2014-03-16 12:11:48Z ctrondlp $)

use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;


# Optional building of additional doc formats.
if (defined($ARGV[0]) && $ARGV[0] eq 'docs') {
	BuildDocumentation();
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME' => 'X11::GUITest',
	($] ge '5.005') ? (
		'AUTHOR' => 'Dennis K. Paulsen <ctrondlp@cpan.org>',
		'ABSTRACT' => 'Collection of functions for X11 GUI testing/interaction.',
	) : (),
	'VERSION_FROM' => 'GUITest.pm', # Finds $VERSION
	($] lt '5.008') ? (
		'INST_MAN3DIR' => './blib/man3',
		'MAN3EXT' => '3pm'
	) : (),
	'MAN3PODS' => {'GUITest.pm' => '$(INST_MAN3DIR)/X11::GUITest.$(MAN3EXT)'},
	'LIBS'  => GetLibs(), # e.g., '-lm'
	# To work around an incompatibility between the XTest and the Xinerama
	# (X server) extensions, use "-DX11_GUITEST_USING_XINERAMA".
	'DEFINE' => '-DNDEBUG -DX11_GUITEST_ALT_L_FALLBACK_META_L', # e.g., '-DHAVE_SOMETHING'
	'INC'   => '-I/usr/X11R6/include -I/usr/X/include', # e.g., '-I/usr/include/other'
	'CCFLAGS' => $Config{ccflags} . ' -Wall',
	'OBJECT' => 'GUITest$(OBJ_EXT) KeyUtil$(OBJ_EXT)',
	'OPTIMIZE' => '-O2',
        'META_MERGE' => {
            resources => {
                repository => 'https://x11guitest.svn.sourceforge.net/svnroot/x11guitest',
            },
        },
        'LICENSE' => 'gpl_2',
);


sub GetLibs {
	my $un = `uname -a 2>&1` || "";
	if ($un =~ /x86_64|amd64/i && $un !~ /OpenBSD/) {
		# In case of x64, lets make sure we use x64 libs, system might have both.
		return ['-L/usr/X11R6/lib64 -L/usr/X/lib64 -lXtst -lX11'];
	} else {
		return ['-L/usr/X11R6/lib -L/usr/X/lib -lXtst -lX11'];
	}
}

# Subroutine: BuildDocumentation
# Description: This function is implemented to generate the
#			   documentation in HTML/plain-text formats.
sub BuildDocumentation {
	my $podfile = 'GUITest.pm';

	# Check POD
	if ( system("podchecker $podfile &>/dev/null") != 0 ) {
		print "POD validation failed!  Documentation will not be written.\n";
		return(0);
	}

	# Generate Text and HTML documents
	print "Writing documentation for X11::GUITest\n";
	system("pod2text $podfile docs/X11-GUITest.txt");
	system("pod2html --infile=$podfile --outfile=docs/X11-GUITest.html");
	system("cp -f docs/X11-GUITest.txt README");

	# Cleanup
	unlink <pod*.x??>;
	unlink <pod*.tmp>;

	return(1);
}
