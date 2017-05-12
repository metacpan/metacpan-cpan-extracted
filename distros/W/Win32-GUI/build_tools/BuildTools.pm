#!perl
package BuildTools;

# This file is part of the build tools for Win32::GUI
# It encapsulates a number of helper functions that
# are repeatedly used in the build process
#
# Author: Robert May , rmay@popeslane.clara.co.uk, 20 June 2005
# $Id: BuildTools.pm,v 1.2 2005/08/25 19:30:17 robertemay Exp $

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

our $VERSION = "0.01";

my $pm = "GUI.pm"; # the file to extract the VERSION from 
my @monthname = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my ($mday,$mon,$year) = (localtime)[3..5];
$year += 1900;

###########################################################################
# Documentation templating
#
# This section defines the macros for replacement in the POD documentation
# while building the POD documentation
#
{
  my $prefix = "W32G_";
  my $unknown_file = '/unknown file/';
  my %MACROS = (
                 VERSION        => MM->parse_version($pm),
                 PERLVERSION    => substr($Config{version},0,3),
                 DATE           => sprintf("%02d %3s %4d", $mday, $monthname[$mon], $year),
                 YEAR           => $year,
                 FILE           => $unknown_file,
                 WEB_HOMEPAGE   => 'http://perl-win32-gui.sourceforge.net/',
                 WEB_USERMAIL   => 'http://lists.sourceforge.net/lists/listinfo/perl-win32-gui-users',
                 WEB_MAILARCHIVE => 'http://sourceforge.net/p/perl-win32-gui/mailman/perl-win32-gui-users/',
                 WEB_FILES      => 'http://sourceforge.net/projects/perl-win32-gui/files/',
                 EMAIL_USERLIST => 'perl-win32-gui-users@lists.sourceforge.net',
               );

  # macro_set
  # set a MACRO to the key,value pair sent
  # and returns the previous value (undef if it didn't exist);
  sub macro_set
  {
    my $key = shift;
    my $value = shift;

    my $old_value = $MACROS{$key};

    $MACROS{$key} = $value;

    return $old_value;
  }

  sub macro_set_file
  {
    my $key = shift;
    my $file = shift;

    my $value = '';

    # read in the macro definition from the file,
    # throwing away comments
    open(my $FILE, "<$file") || die __PACKAGE__ . " can't open $file for reading";
    while(<$FILE>) {
      next if /^#/;
      $value .= $_;
    }
    close($FILE);

    return macro_set($key, $value);
  }

  # macro_subst
  # Takes a string as input, and returns a sting with macro substitution done.
  # 2nd and 3rd agueuments ar optional, and if provided give a file and line for
  # error reporting.
  # substitution is recursive to allow macros to contain macros.
  sub macro_subst
  {
    my $in_text = shift;
    my $file = shift;
    my $line = shift;

    return $in_text if not $in_text; # cope with uninitialised input

    my $level = 0; # so we can bail out if it look like we have a macro loop

    # TODO: this next line generate warnings for undefined macro replacements.
    #  re-write to warn properly
    while( ($in_text =~ /__$prefix(\w+)__/) and (++$level < 100) ) { # there's at least one macro to substitute
      if( exists $MACROS{$1} ) {
        $in_text =~ s/__$prefix(\w+)__/$MACROS{$1}/e;
      }

      else {
        $in_text =~ s/__$prefix(\w+)__//;
        my $errstr = "undefined macro __$prefix$1__ found and removed";
        $errstr .= " while processing $file" if $file;
        $errstr .= " (line $line)" if $line;
        print STDERR "$errstr\n";
      }
    }

#    while(($in_text =~ s/__$prefix(\w+)__/$MACROS{$1}/ge) and (++$level < 100)) {};

    if($level >= 100) {
      my $errstr = "recursive macro found";
      $errstr .= " while processing $file" if $file;
      $errstr .= " (line $line)" if $line;
      die $errstr;
    }

    # warn if there's anything that looks like a macro left.
    # This will help catch typos
    my @errors = ($in_text =~ /__[\w_]+__/g);
    if(@errors) {
      my $errstr = "macros found and not substituted (@errors)";
      $errstr .= " while processing $file" if $file;
      $errstr .= " (line $line)" if $line;
      print STDERR "$errstr\n";
    }
    return $in_text;
  }

  # macro_subst_cp
  # Takes an input and output filename, and performs macro substitution
  # on all lines of the input file, while copying it to the output location.
  # Ensures that the destination directory exists.
  sub macro_subst_cp
  {
    my $in_file = shift;
    my $out_file = shift;

    # Open in file, failing if it doesnot exist
    open(my $IN, "<$in_file") or die __PACKAGE__ . " failed to open $in_file for reading: $!";

    # ensure the destination directory exists, creating it if it does not
    {
      (my $dest_dir = $out_file) =~ s|[/\\][^/\\]*$||;
      $dest_dir = "." if ($dest_dir eq $out_file);
      mkpath($dest_dir);
    }

    # open the output file
    open(my $OUT, ">$out_file") or die __PACKAGE__ . " failed to open $out_file for writing: $!";

    # Set the FILE macro
    $MACROS{FILE} = $in_file;

    while(my $line = <$IN>) {

      # remove POD comment lines, as they appear to get treated
      # by pod2html as blocks and can result in getting extra
      # <hr /> tags inserted
      next if $line =~ /^=for comment/;

      # TODO: is there any benefit in collapsing multiple blank
      # lines to a single line?

      $line = macro_subst($line, $in_file, $.);
      print $OUT $line;
    }

    # un-set the FILE macro
    $MACROS{FILE} = $unknown_file;

    close($OUT);
    close($IN);

    return 1;
  }
}

###########################################################################
use ExtUtils::Command ();
# mkpath()
#
# Create the directorys (and all missing hierarchy) passed as arguments.
# See EXtUtils::Command for more details

sub mkpath
{
  local @ARGV = @_;
  ExtUtils::Command::mkpath();
}

# cp()
#
# copy source to destination
# See EXtUtils::Command for more details
sub cp
{
  local @ARGV = @_;
  ExtUtils::Command::cp();
}

# mv()
#
# move source to destination
# See EXtUtils::Command for more details
sub mv
{
  local @ARGV = @_;
  ExtUtils::Command::mv();
}

# rm_f()
#
# forcefully remove files
# See EXtUtils::Command for more details
sub rm_f
{
  local @ARGV = @_;
  ExtUtils::Command::rm_f();
}

# rm_rf()
#
# forcefully remove directories
# See EXtUtils::Command for more details
sub rm_rf
{
  local @ARGV = @_;
  ExtUtils::Command::rm_rf();
}

1; # end of BuildTools
