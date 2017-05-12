#!perl

# This file is part of the build tools for Win32::GUI
# It expects to be run in the same directory as the make
# command is run from, and writes Readme and Readme.html
# for inclusion with distributions.

# it is typically invoked as
#  make readmedocs
# or automatically as part of the ppm distribution build
# process

#
# Author: Robert May , rmay@popeslane.clara.co.uk, 20 June 2005
# $Id: doReadme.pl,v 1.2 2005/06/30 22:36:22 robertemay Exp $

use strict;
use warnings;

use BuildTools;

use Pod::Text;
use Pod::Html;

my $src = "docs/GUI/UserGuide/Readme.pod";  # The name of the source file to read from
my $tmp = "README.pod";       # Temporary POD document as intermediate (removed)
my $txt = "README";       # The name of the output TXT file to generate
my $htm = "README.html";      # The name of the output HTML file to generate
my $postamble_file  = "docs/pod_postamble.tpl";  # template for the POD postamble macro

# set up the pod POSTAMBLE
BuildTools::macro_set_file("POSTAMBLE", $postamble_file);

print BuildTools::macro_subst(
    "Generating Readme files for Win32::GUI v__W32G_VERSION__ on __W32G_DATE__\n"
    );

BuildTools::macro_subst_cp($src, $tmp);


# save old copies of the Readme files
BuildTools::mv($txt,"$txt.old");
BuildTools::mv($htm,"$htm.old");

# Do the text doc
my $parser = Pod::Text->new(
                loose => 1,
              );

$parser->parse_from_file($tmp, $txt);
undef $parser;

# Do the HTML doc
pod2html(
  "--infile=$tmp",
  "--outfile=$htm",
);

# remove pod2html cache files; 5.6 uses ".x~~" and 5.8 uses ".tmp" extensions
unlink("pod2htmd.$_", "pod2htmi.$_") for qw(x~~ tmp);

BuildTools::rm_f($tmp);

exit(0);
