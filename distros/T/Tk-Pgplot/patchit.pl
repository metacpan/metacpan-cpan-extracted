#!/usr/bin/perl -w

use FileHandle;
use strict;
use File::Basename;
use Getopt::Long;

sub nextfile ($$);
sub checkdir ($@);
sub patchdir ($@);

my $debug = 0;
GetOptions('debug'=>\$debug);

(@ARGV==1) || die "Usage: patchit.pl <pgplot source dir>\n";
my $pgplotdir = shift;

$pgplotdir =~ s[/$][];

(-d 'pgplot.patch') ||
    die "This script should be run from the TK-Pgplot source directory\n";

(-d $pgplotdir) ||
    die "Pgplot dir \"$pgplotdir\" does not exist!\n";

my $prog = basename($0);
if (-e "$pgplotdir/$prog") {
  die "Your trying to patch the Tk::Pgplot directory!\n";
}

my @files;
my $fh = new FileHandle;
opendir($fh, 'pgplot.patch') || die "Cannot open 'pgplot.patch': $!\n";

# CD to the patch dir to make life a little easier
chdir './pgplot.patch' || die "Could not cd to pgplot.patch\n";

# Suck up the files and directory structure of the patch
# directory. Ignore hidden directories and CVS directory, if any.
while (my $f = nextfile($fh, '')) {

    push @files, $f;
}

closedir($fh);

#printdir('', @files);

# Check all the expected files exist and no .orig files exist
checkdir('', @files);

# Copy over the patches
patchdir('', @files);

sub nextfile ($$) {
    my ($fh, $currentdir) = @_;
    my $f;
    while ($f = readdir $fh) {
      # Ignore hidden directories and CVS directory.
      last unless ($f =~ /^\.|CVS/);
    }

    return undef if (!defined $f);

    if ($f eq '.' || $f eq '..') {
	return nextfile $fh, $currentdir;
    }

    (-r "${currentdir}$f") || die "Cannot read ${currentdir}$f\n";

    # Is the file a directory, if so we need to enter is and return 
    # an array reference to the included files
    if (-d "${currentdir}$f") {
	my @newdir = ("${currentdir}$f/"); # First element is the directory name
	my $nfh = new FileHandle;
	opendir($nfh, "${currentdir}$f") 
	    || die "Cannot open '${currentdir}$f': $!\n";
	while (my $f = nextfile($nfh, "${currentdir}$f/")) {
	    push @newdir, $f;
	}
	closedir($nfh);
	return \@newdir;
    }
    return $f;
}

sub checkdir ($@) {
    my $dir = shift;
    my @files = @_;

    foreach (@files) {
	if (ref) {
	    (ref eq 'ARRAY') || die "Internal error!";
	    my @newdir = @$_;
	    my $newdir = shift @newdir;
	    if (-d "$pgplotdir/${dir}$newdir") {
		(-w "$pgplotdir/${dir}$newdir") || 
		    die "$pgplotdir/${dir}$newdir is not writeable!\n";
	    } else { # Directory does not exist, but maybe it is
		     # the ptk directory
		($newdir eq 'drivers/ptk/') ||
		    die "$pgplotdir/${dir}$newdir dones not exist!\n";
	    }
	    #print "d $pgplotdir/${dir}$newdir\n";
	    checkdir($newdir, @newdir);
	} else {
	    #print "f $pgplotdir/${dir}$_\n";
	    # Does the files exist and is backup not
	    if (-e "$pgplotdir/${dir}$_") {
		(! -e "$pgplotdir/${dir}${_}.orig") ||
		    die "$pgplotdir/${dir}${_}.orig already exists\n".
			"Have you already run this script?\n";
	    } else {
		# We allow the new ptk files
		($dir eq "drivers/ptk/" || $_ eq "pkdriv.c") || 
		    die "$pgplotdir/${dir}${_} does not exists!\n";
	    }
	}
    }
}

# Actually go through and apply the patches
sub patchdir ($@) {
  my $dir = shift;
  my @files = @_;

  foreach (@files) {
    if (ref) {
      (ref eq 'ARRAY') || die "Internal error!";
      my @newdir = @$_;
      my $newdir = shift @newdir;

      if ($newdir eq 'drivers/ptk/') {
	if ($debug) {
	  print "mkdir $pgplotdir/$newdir\n";
	} else {
	  mkdir "$pgplotdir/$newdir", 0777
	    || die "Failed to create $pgplotdir/$newdir";
	}
      }
      patchdir($newdir, @newdir);

    } else {
      # Backup the file unless it is one of the new ones
      if (! ($dir eq "drivers/ptk/" || $_ eq "pkdriv.c")) {
	if ($debug) {
	  print "rename $pgplotdir/${dir}$_ $pgplotdir/${dir}${_}.orig\n";
	} else {
	  rename "$pgplotdir/${dir}$_", "$pgplotdir/${dir}${_}.orig"
	    || die "Failed to rename $pgplotdir/${dir}$_: $!\n";
	}
      }
      # Copy the new file
      if ($debug) {
	print "system cp ${dir}$_ $pgplotdir/${dir}$_\n";
      } else {
	print "patch ${dir}$_\n";
	system "cp ${dir}$_ $pgplotdir/${dir}$_";
	($?==0) || die "copy failed\n";
      }
    }
  }
}

#  sub printdir ($@) {
#      my $dir = shift;
#      my @files = @_;

#      foreach (@files) {
#  	if (ref) {
#  	    (ref eq 'ARRAY') || die "Internal error!";
#  	    my @newdir = @$_;
#  	    printdir(shift @newdir, @newdir);
#  	} else {
#  	    print "$dir$_\n";
#  	}
#      }
#  }
