#!/usr/bin/perl -w

#    edit-db - Edit a Berkley DBM file keeping the sequence during edit.
#    Copyright (C) 1997  Michael De La Rue
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

#TODO
#
# add more control - commit, reset, first.


use strict;
$::VERSION="0.03";

=head1 NAME

edit-db - edit any kind of Berkley DB file

=head1 SYNOPSYIS

  edit-db.pl [options] <file>
  --version -V                print version info
  --usage --help -h           print usage info
  --verbose -verbose          debugging messages
  --type=[type] -t [type]     type of db file to use (btree/hash/recno)

=head1 DESCRIPTION

This program is designed to allow the contents of a DBM file to be
edited.  It provides several commands for exploring and adding to the
dbm file.

=head1 OVERVIEW

Once the program is running, the following commands can be used to examine and
change the contents of the database.

  key - choose the next key.. (not needed?) and show the value

  show - show the value for the present key

  seq - go through the dbm file in sequence (the present location is
        always remembered)

  edit - edit the value of the current key in the editor

  add - add a key (with a string the string becomes the new key, with
        nothing the editor is opened to allow the value to be input)

  delete - delete a key/value pair

  help - list the available commands
  
  quit - quit from the program.

Any changes you make are only written when the program quits, so
typing ctrl-C aborts with no changes under the present version.

=head1 COPYING

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

=cut


$::edit_prefix="/tmp/edit-db-temp.";

$::check_key="";

use DB_File;
use Tie::TransactHash;
use Fcntl;
use Getopt::Mixed 1.006, 'nextOption';

Getopt::Mixed::init( "version V>version",
		     "usage help>usage h>usage",
		     "verbose:i v>verbose", 
		     "verbose-hash:i h>verbose-hash", 
		     "file=s f>file",
		     "type=s t>type");
$::db_type=$::DB_HASH;
$::verbose=0;
my $option;
my $value;
my $asEntered;
while (($option, $value, $asEntered) = nextOption()) {
  if ($option eq "usage") {
    usage();
    exit();
  } elsif ($option eq "version" ) {
    version();
    exit();
  } elsif ($option eq "verbose" ) {
    if ( $value eq "" ) {
      $::verbose=4;
    } else {
      $::verbose=$value;
    }
  } elsif ($option eq "verbose-hash" ) {
    print STDERR "setting the TransactHash to be verbose\n";
    if ( $value eq "" ) {
      $TransactHash::verbose=4;
    } else {
      $TransactHash::verbose=$value;
    }
  } elsif ($option eq "type") {
    ($value =~ m/^hash$/) && ($::db_type = $::DB_HASH);
    ($value =~ m/^btree$/) && ($::db_type = $::DB_BTREE);
    ($value =~ m/^recno$/) && ($::db_type = $::DB_RECNO);
  } 
#TODO add a system choice to allow use of gdbm.  Remember gdbm doesn't
#do btrees.
}
sub usage() {
  print <<EOF;
explore-db.pl [options] <filename>
  --version -V                print version info
  --usage --help -h           print usage info
  --verbose -v                debugging messages
  --verbose-hash              debugging messages from TransactHash
  --type=[type] -t [type]     type of db file to use (btree/hash/recno)
Allows exploration of a Berkley DB file.
EOF
}
sub version() {
  print <<'EOF';
edit-db.pl version $::VERSION - Copyright (c) Michael De La Rue 1997
EOF
}
#command-line-end

$::dbname=shift;
unless ($::dbname) {
  print "Need to specify the DBfile.\n";
  usage();
  exit();
}

if (@ARGV) {
  print "Only one DBfile for now.  Sorry\n";
  usage();
  exit();
}

$::db = tie %::db, "DB_File", $::dbname, O_RDWR|O_CREAT, 0640, $::db_type
  or die $!;

$::edit_db = tie %::edit_db, "Tie::TransactHash", \%::db, $::db;

sub help {
  print "Commands: key seq edit show delete add help quit\n";
}

#FIXME silent mode?? - don't see the need.. yet
print <<EOF;
    edit-db version $::VERSION, Copyright (C) 1997 Michael De La Rue
    edit-db comes with ABSOLUTELY NO WARRANTY; for details see the 
    file COPYING which should have been distributed with the program
    This is free software, and you are welcome to redistribute it.
EOF
print "Welcome to edit_db : editing database ", $::dbname, "\n";

help;

my $present_key;

print 'command>';
COMMAND: while ( <> ) {
  m/\s*key\s/ && do { 
    s/\s*key\s*//;
    s/\n$//; 
    my @keys=m/\S\S*/g;
    my $key;
    foreach $key (@keys) {
      print "key $_ gives value\n", $::edit_db{$_}, "\n\n";
      $present_key=$key;
    }
    next COMMAND;
  };
    
  m/\s*seq/ && do { 
    my ($key, $value) = each %::edit_db;
    unless (defined $key) {
      print "End of sequence.  Use seq again to restart.\n" ;
      next COMMAND 
    }
    print "key $key gives value\n", $value, "\n\n";
    $present_key=$key;
    next COMMAND;
  };

  m/\s*edit/ && do { 
    s/\s*edit\s*//;
    s/\n$//; 
    $present_key = $_ if $_;
    unless ( $present_key ) {
      print STDERR "You have to select a record with seq or key first\n";
      next COMMAND;
    } 
    unless ( defined $::edit_db{$present_key} ) {
      print STDERR "There's no record for key $present_key\n";
      next COMMAND;
    }
    $value=$::edit_db{$present_key};
    $::edit_db{$present_key}=edit($value);
    $value=$::edit_db{$present_key};
    print "key $present_key gives value\n", $value, "\n\n";
    next COMMAND;
  };

  m/\s*show/ && do { 
    s/\s*show\s*//;
    s/\n$//; 
    $present_key = $_ if $_;
    unless ( $present_key ) {
      print STDERR "You have to select a record with seq or key first\n";
      next COMMAND;
    } 
    unless ( defined $::edit_db{$present_key} ) {
      print STDERR "There's no record for key $present_key\n";
      next COMMAND;
    }
    $value=$::edit_db{$present_key};
    print "key $present_key gives value\n", $value, "\n\n";
    next COMMAND;
  };

  m/\s*delete/ && do { 
    s/\s*delete\s*//;
    s/\n$//; 
    $present_key = $_ if $_;
    unless ( $present_key ) {
      print STDERR "You have to select a record with seq or key first\n";
      next COMMAND;
    } 
    unless ( defined $::edit_db{$present_key} ) {
      print STDERR "There's no record for key $present_key\n";
      next COMMAND;
    }
    print STDERR "deleting record in edithash\n";
    delete $::edit_db{$present_key};
    next COMMAND;
  };

  m/\s*add/ && do { 
    s/\s*add\s*//;
    s/\n$//; 
    #keys can include spaces here, which isn't generally true?
    $present_key = $_; 
    unless ( $_ ) {
      print STDERR "You have to give a new key name to add\n";
      next COMMAND;
    } 
    if ( defined $::edit_db{$present_key} ) {
      print STDERR "There's already record for key $present_key\n";
      next COMMAND;
    }
    $value="";
    $::edit_db{$present_key}=edit($value);
    $value=$::edit_db{$present_key};
    print "key $present_key gives value\n", $value, "\n\n";
    next COMMAND;
  };

  m/^\s*help/ && do { 
      help;
      next COMMAND;
  };

  m/^\s*$/ && do {
      next COMMAND;
  };

  $::dohack=1; #not needed in perl 5.003_25 it seems
  m/^\s*quit/ && do { 
      if ($::dohack) {
	  #FIXME*** seems we have to do this before exit?
	  #there's some big problem with destructors.
	  # should be able to delete from here.....
	  $::edit_db=undef;
	  untie %::edit_db; 

#to allow for debugging
#		      print STDERR "check key " . $::check_key . "\n";
#		      print STDERR "check value " . $::db{check_key} . "\n";
	  $::db->sync;
	  $::db=undef;
	  untie %::db;
	  #to here.....
      }
      exit 0;
  };
    
  print "Unknown command\n";
  help;
} continue {
  print 'command>';
}

exit 0;

sub edit {
  my $value=shift;
  my $filename=$::edit_prefix . $$;
  my $editor=$ENV{"EDITOR"};
  $editor="vi" unless defined $editor;
  open(EDITTMP, ">$filename");
  print EDITTMP $value;
  close EDITTMP;
  system($editor, "$filename");
  open(EDITTMP, "$filename");
  my $return="";
  my $line;
  while (<EDITTMP>) {
    $return = $return . $_;
  }
  close EDITTMP;
  unlink $filename;
  return $return;
}



#we should really have a show command.


