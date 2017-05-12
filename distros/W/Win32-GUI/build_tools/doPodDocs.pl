#!perl

# This file is part of the build tools for Win32::GUI
# It expects to be run in the same directory as the make
# command is run from, and performs the following functions:
# (1) Parses the source files for documentation
# (2) Prepares the macros needed for generating the templated
#     POD documentation.
# (3) Takes every POD document from the docs directory tree
#     and does the macro substitution, copying it into the
#     same relative location in the blib directory tree.
# (4) Generates the per-package(class) POD documentation
#     directly in the blib directory tree.

# it is typically invoked as
#  make poddocs
# or automatically as part of the distribution build
# process

#
# Author: Robert May , rmay@popeslane.clara.co.uk, 20 June 2005
# $Id: doPodDocs.pl,v 1.6 2008/02/02 17:03:56 robertemay Exp $

use strict;
use warnings;

use SrcParser;
use BuildTools;

$SrcParser::DEBUG = 0;

my $ROOTDIR = $ARGV[0] || 'blib/lib';

my @packages_with_own_pod = qw(
    Win32::GUI::AxWindow
    Win32::GUI::BitmapInline
    Win32::GUI::Constants
    Win32::GUI::DIBitmap
    Win32::GUI::DropFiles
    Win32::GUI::Grid
    Win32::GUI::GridLayout
    Win32::GUI::Scintilla
);

######################################################################
# (1) Parse the source fies for documentation.
{
  my $src_dir = "."; # directory where the source files are

  # Set up the files that we are going to parse for embedded documentation:
  my @files;
  # GUI.pm
  push @files, "$src_dir/GUI.pm";
  # GUI_MessageLoops.cpp
  push @files, "$src_dir/GUI_MessageLoops.cpp";

  # and all the XS files
  opendir(my $DIR, $src_dir) || die "Can't open directory $src_dir: $!";
  while(my $file = readdir($DIR)) {
    push @files, "$src_dir/$file" if $file =~ /\.xs$/;
  }
  closedir($DIR);

  # Parse the files
  SrcParser::parse(@files);
}

# (2) Set up the macros that we need;
{
  my $pkgtpl_file = "docs/GUI/Reference/Packages_package.tpl";
  my $postamble_file  = "docs/pod_postamble.tpl";

  # set up the pod POSTAMBLE
  BuildTools::macro_set_file("POSTAMBLE", $postamble_file);

  # set up the PKGTPL per package template
  BuildTools::macro_set_file("PKGTPL", $pkgtpl_file);

  # set up the PACKLIST macro
  my $packages = "";

  for my $package (sort(SrcParser::get_package_list(), @packages_with_own_pod)) {
    (my $link = $package) =~ s/^Win32::GUI$/Win32::GUI::Reference::Methods/; # special case for Win32::GUI
    BuildTools::macro_set("PKGNAME", $package);
    BuildTools::macro_set("PKGLINK", $link);
    $packages .= BuildTools::macro_subst("__W32G_PKGTPL__");
  }

  $packages =~ s/\s*$//;
  BuildTools::macro_set("PACKLIST", $packages);

  my $evttpl_file = "docs/GUI/Reference/Events_event.tpl";

  # set up the EVTTPL per package template
  BuildTools::macro_set_file("EVTTPL", $evttpl_file);

  # set up the EVENTLIST macro
  my $events = "";

  for my $event (SrcParser::get_common_event_list()) {
    BuildTools::macro_set("EVENTNAME", $event);
    BuildTools::macro_set("EVENTPROTO", SrcParser::get_common_event_prototype($event));
    BuildTools::macro_set("EVENTDESCR",
      fix_description( "Win32::GUI::Reference::Events", SrcParser::get_common_event_description($event) )
    );
    $events .= BuildTools::macro_subst("__W32G_EVTTPL__");
  }

  $events =~ s/\s*$//;
  BuildTools::macro_set("EVENTLIST", $events);
}

# (3) Copy the static POD documentation
{
  my $static_pod_root = "docs";           # the starting point to find POD sources
  my $blib_pod_root   = "$ROOTDIR/Win32"; # the matching root for placing processed POD docs

  print BuildTools::macro_subst(
      "Copying static POD from $static_pod_root for Win32::GUI v__W32G_VERSION__ on __W32G_DATE__\n"
      );

  # recurvively traverse the POD directories, building the output POD docs
  cp_pod($static_pod_root, $blib_pod_root);
}

# (4) Generate the per package documentation
{
  my $blib_pod_root = $ROOTDIR;
  my $package_template_file  = "docs/per_package.tpl";
  my $package_methodsec_file  = "docs/per_package_method_section.tpl";
  my $pp_method_file  = "docs/per_package_method.tpl";
  my $package_eventsec_file  = "docs/per_package_event_section.tpl";
  my $pp_event_file  = "docs/per_package_event.tpl";

  # load the templates:
  BuildTools::macro_set_file("PKGMETHODSEC", $package_methodsec_file);
  BuildTools::macro_set_file("PKGEVENTSEC", $package_eventsec_file);
  BuildTools::macro_set_file("METHOD", $pp_method_file);
  BuildTools::macro_set_file("EVENT", $pp_event_file);

  print BuildTools::macro_subst(
      "Creating per package POD for Win32::GUI v__W32G_VERSION__ on __W32G_DATE__\n"
      );

  for my $package (SrcParser::get_package_list()) {
    (my $pkg = $package) =~ s/^Win32::GUI$/Win32::GUI::Reference::Methods/; # special case for Win32::GUI

    # set up PKGNAME macro
    BuildTools::macro_set("PKGNAME", $pkg);
    # set up PKGABSTRACT macro
    BuildTools::macro_set("PKGABSTRACT", fix_abstract( SrcParser::get_package_abstract($package) ));
    # set up PKGDESCR macro
    BuildTools::macro_set("PKGDESCR", fix_description( $package, SrcParser::get_package_description($package) ));

    # set up the PP_METHODS macro
    my $pkgmethods = "";
    for my $method (SrcParser::get_package_method_list($package)) {
      BuildTools::macro_set("METHODNAME", $method);
      BuildTools::macro_set("METHODPROTO", SrcParser::get_package_method_prototype($package, $method));
      BuildTools::macro_set("METHODDESCR", 
        fix_description( $package, SrcParser::get_package_method_description($package, $method) )
      );

      $pkgmethods .= BuildTools::macro_subst("__W32G_METHOD__");;
      # Move this to a template somehow
      $pkgmethods .= "See also the L<common options|Win32::GUI::Reference::Options>.\n\n" if $method eq "new";
    }

    $pkgmethods =~ s/\s*//;
    BuildTools::macro_set("PP_METHODS", $pkgmethods);

    # TODO set up the PP_EVENTS macro
    my $pkgevents = "";
    for my $event (SrcParser::get_package_event_list($package)) {
      BuildTools::macro_set("EVENTTITLE", $event);
      BuildTools::macro_set("EVENTNAME", SrcParser::get_package_event_name($package, $event));
      BuildTools::macro_set("EVENTPROTO", SrcParser::get_package_event_prototype($package, $event));
      BuildTools::macro_set("EVENTDESCR", 
        fix_description( $package, SrcParser::get_package_event_description($package, $event) )
      );

      $pkgevents .= BuildTools::macro_subst("__W32G_EVENT__");;
    }

    $pkgevents =~ s/\s*//;
    BuildTools::macro_set("PP_EVENTS", $pkgevents);

    my $podfile = $pkg;
    $podfile =~ s/::/\//g;
    $podfile = "$blib_pod_root/$podfile.pod";

    # copy over the template, doing substitution
    BuildTools::macro_subst_cp($package_template_file, $podfile);
  }

}

exit(0);

################################################################################
# cp_pod: recursively traverses source directory for *.pod documents. Each one
# found is copyied into the corresponing position below the destination directory
# and macro substitution is performed.
sub cp_pod
{
  my $src_dir = shift;
  my $dest_dir = shift;

  # open the directory
  opendir(my $DIR, $src_dir) || die "Can't open directory $src_dir for reading: $!";
  while(my $file = readdir($DIR)) {

    # process POD files
    if($file =~ /\.pod$/) {
      # perform the file copy and macro substitution
      BuildTools::macro_subst_cp("$src_dir/$file", "$dest_dir/$file");
    }

    # resurse into directories
    elsif (-d "$src_dir/$file" ) {
      # ignore '.' and '..'
      if ($file !~ /^\.{1,2}$/) {
        cp_pod("$src_dir/$file", "$dest_dir/$file");
      }
    }

    # ignore anything else
    else {
    }
  }
  closedir($DIR);

  return 1;
}

################################################################################
# fix_description(descr): fixes a raw description, as returned by the parser
# - remove blank lines at the start
# - trim whitespace from the end of the lines
# - throw away multiple blank line
# - ensure that there are blank lines around blocks of indented text
# - parse and resolve links
# - remove all whitespace (includes trailing \n) from end of text
sub fix_description
{
  my $package = shift;
  my $text = shift;

  my $indented = 0;
  my $lastlineblank = 1; # causes removal of blank lines from the start
  my $outtext = '';

  # add a return if there isn't one, so that the split later
  # doesn't cause any undefined warnings
  $text .= "\n" if($text !~ /\n/);

  # split into lines
  my @lines = split("\n", $text);

  for my $line (@lines) {

    # remove whitespace from end of line
    $line =~ s/\s*$//;

    if ( $line eq '' ) {

      # throw away multiple sets of blank lines, and 
      # blank lines at the start
      next if $lastlineblank == 1;

      $lastlineblank = 1;
      $outtext .= "\n";
      next;
    }

    if($lastlineblank) { # this is the first line in a new block
      $lastlineblank = 0;
      $indented = ($line =~ /^\s/);
    }
    else {
      # add lines around indented text, if necessary
      if( ($indented and $line !~ /^\s/) or
          (not $indented and $line =~ /^\s/) ) {
        $indented = not $indented;
        $outtext .= "\n";
      }
    }

    # parse the line for any links and add to the output
    $outtext .= parse_links($package, $line). "\n";
  }

  # remove any remaining whitespace from the end
  $outtext =~ s/\s*$//;

  # if we have no description left, return [TBD]
  return $outtext ? $outtext : '[TBD]';
}

################################################################################
# parse_links(text): find links to other docs
# looks for links of the form:
# - [sS]ee [also] func()
# - [sS]ee [also] new Win32::GUI::Package();
sub parse_links
{
  my $pack = shift;
  my $text = shift;

  return $text unless defined $pack; # defensive

  while ($text =~ /[sS]ee (also )?/g) {
    $text =~ s/\G(new )?([\w:]+)\(\)/create_link($pack, $2, $1)/e;
  }

  return $text;
}

sub create_link
{
  my $pack = shift;
  my $method = shift;
  my $new = shift;

  my $text;

  if($new) {
    $pack = $method;
    $method = "new";
    $text = "new $pack()";
  }
  else {
    #($pack = $method) =~ s/(.*::).*/$1/ if($method =~ /::/);
    $text = "$method()";
    if( $method  =~ /(.*)::(.*?)$/ ) {
	    $pack = $1;
	    $method = $2;
    }

  }

  # special case for Win32::GUI
  $pack = "Win32::GUI::Reference::Methods" if $pack =~ /^Win32::GUI$/;
  return "L<$text|$pack/$method>";
}

################################################################################
# fix_abstract(descr): fixes an abstract, as returned by the parser
# - remove whitesapce at tart and end
sub fix_abstract
{
  my $text = shift;

  $text =~ s/\s*(.*)\s*/$1/;

  # if we have no description left, return [TBD]
  return $text ? $text : 'A Win32::GUI package';
}
