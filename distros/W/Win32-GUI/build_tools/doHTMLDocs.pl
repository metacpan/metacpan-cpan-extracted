#!perl -w

# This file is part of the build tools for Win32::GUI
# It expects to be run in the same directory as the make
# command is run from, and performs the following functions:
# (1) converts all POD documentation in the blib/lib directory, and puts
#     it in the blib/html/site/lib directory
# (2) Copies any GIF files from the document source to the relavent location
#     in the blib/html tree
# (3) converts all POD documentation in the blib/script directory, and puts
#     it in the blib/html/bin directory

# it is typically invoked as
#  make htmldocs
# or automatically as part of the ppm distribution build
# process
#
# Author: Robert May , rmay@popeslane.clara.co.uk
# $Id: doHTMLDocs.pl,v 1.3 2006/07/16 11:09:32 robertemay Exp $

use strict;
use warnings;

use BuildTools;
use Pod::Html;
use Pod::Find  qw(pod_find);
use File::Path qw(mkpath);
use File::Spec qw();
use File::Find qw(find);
use File::Copy qw(copy);

my $DEBUG = 0;

my $srcdir = "blib/lib";
my $srcbindir = "blib/script";
my $destrootdir  = "blib/html";
my $destsubdir = "site/lib";
my $destbinsubdir = "bin";
my $imgsrcdir = "docs";

print BuildTools::macro_subst(
    "Converting POD documentation to HTML for Win32::GUI v__W32G_VERSION__ on __W32G_DATE__\n"
);

# recursively traverse everything inside the source directory, find .pod files
# convert to html and put in a corresponding location in the blib/html directory
doHtml($srcdir, $destrootdir, $destsubdir);
doHtml($srcbindir, $destrootdir, $destbinsubdir);

# remove pod2html cache files; 5.6 uses ".x~~" and 5.8 uses ".tmp" extensions
unlink("pod2htmd.$_", "pod2htmi.$_") for qw(x~~ tmp);

# copy all GIF files from docs directy to html tree
doGIF($imgsrcdir, File::Spec->catfile($destrootdir, $destsubdir, "Win32"));

exit(0);

sub doHtml
{
    my ($srcdir, $htmlrootdir, $htmlsubdir) = @_;

    # Tidy the passed params:
    $srcdir      = File::Spec->canonpath($srcdir);
    $htmlrootdir = File::Spec->canonpath($htmlrootdir);
    $htmlsubdir  = File::Spec->canonpath($htmlsubdir);

    # Find POD files:
    my %pods = pod_find( {-perl => 1}, $srcdir);

    for my $srcfile (keys %pods) {

        # Ignore any demo files:
        next if $srcfile =~ /demos[\/\\]/;

        # Relative and tidy srcfile
        $srcfile = File::Spec->abs2rel($srcfile);
        $srcfile = File::Spec->canonpath($srcfile);

        # Strip common prefix:
        my $tmp = $srcfile;
        $tmp =~ s/^\Q$srcdir\E//;
        $tmp = File::Spec->catfile($htmlrootdir, $htmlsubdir, $tmp);
        $tmp = File::Spec->canonpath($tmp);

        # generate html file name
        (my $htmlfile = $tmp) =~ s/\.[^.]*$/.html/;
        print STDERR "Converting $srcfile to $htmlfile\n" if $DEBUG;

        # ensure the destination directory exists
        my (undef, $dstdir, undef) = File::Spec->splitpath($htmlfile);
        print STDERR "Creating directory $dstdir\n" if $DEBUG;
        mkpath($dstdir);

        # calculate the relative path to the html root dir
        my $path2root = File::Spec->abs2rel($htmlrootdir, $dstdir);

        # Unixify path seperators
        (my $u_srcfile    = $srcfile)    =~ s|\\|/|g;
        (my $u_htmlfile   = $htmlfile)   =~ s|\\|/|g;
        (my $u_dstdir     = $dstdir)     =~ s|\\|/|g;

        (my $u_htmlroot = File::Spec->catdir($path2root, $htmlsubdir))   =~ s|\\|/|g;
        (my $u_css      = File::Spec->catfile($path2root, "Active.css")) =~ s|\\|/|g;

        # and convert the source POD to destination HTML
        my @options = (
            "--infile=$u_srcfile",
            "--outfile=$u_htmlfile",
            "--htmldir=$u_dstdir",
            "--htmlroot=$u_htmlroot",
            "--css=$u_css",
            "--header",
        );
        print STDERR "pod2html @options\n" if $DEBUG;
        pod2html(@options);
    }

    return 1;
}

{
    my ($srcrootdir, $dstrootdir);

    sub doGIF
    {
        my ($src, $dst) = @_;

        # Tidy the passed params:
        $srcrootdir = File::Spec->canonpath($src);
        $dstrootdir = File::Spec->canonpath($dst);

        find({wanted =>\&found, no_chdir => 1}, $srcrootdir);

        return 1;
    }

    sub found {
        my $file  = File::Spec->canonpath($_);

        # copy .gif files
        if($file =~ /\.gif$/) {
            (my $dstfile = $file) =~ s/^\Q$srcrootdir\E//;
            $dstfile = File::Spec->catfile($dstrootdir, $dstfile);
            print STDERR "Copying $file to $dstfile\n" if $DEBUG;
            copy($file, $dstfile);
        }
    }
}
