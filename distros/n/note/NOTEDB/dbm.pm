#!/usr/bin/perl
# $Id: dbm.pm,v 1.3 2000/08/11 00:05:58 zarahg Exp $
# Perl module for note
# DBM database backend. see docu: perldoc NOTEDB::dbm
#

package NOTEDB::dbm;

$NOTEDB::dbm::VERSION = "1.41";

use DB_File;
use NOTEDB;
use strict;
use Exporter ();
use vars qw(@ISA @EXPORT %note %date);
@ISA = qw(NOTEDB Exporter);






sub new
{
    my($this, %param) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self,$class);

    my $notefile = "note.dbm";
    my $timefile = "date.dbm";
    my $dbm_dir = $self->{dbname} = $param{dbname} || File::Spec->catfile($ENV{HOME}, ".note_dbm");

    if (! -d $dbm_dir) {
      # try to make it
      mkdir $dbm_dir || die "Could not create $dbm_dir: $!\n";
    }

    tie %note,  "DB_File", "$dbm_dir/$notefile"  || die "Could not tie $dbm_dir/$notefile: $!\n";
    tie %date,  "DB_File", "$dbm_dir/$timefile"  || die "Could not tie $dbm_dir/$timefile: $!\n";

    $self->{LOCKFILE} = $param{dbname} . "~LOCK";

    return $self;
}


sub DESTROY
{
    # clean the desk!
    untie %note, %date;
}

sub version {
    my $this = shift;
    return $this->{version};
}


sub get_single
{
    my($this, $num) = @_;
    my($note, $date);
    return $this->ude ($note{$num}), $this->ude($date{$num});
}


sub get_all
{
    my $this = shift;
    my($num, $note, $date, %res, $real);
    foreach $num (sort {$a <=> $b} keys %date) {
	$res{$num}->{'note'} = $this->ude($note{$num});
	$res{$num}->{'date'} = $this->ude($date{$num});
    }
    return %res;
}

sub import_data {
  my ($this, $data) = @_;
  foreach my $num (keys %{$data}) {
    my $pos = $this->get_nextnum();
    $note{$pos} = $this->ude($note{$num}->{note});
    $date{$pos} = $this->ude($date{$num}->{date});
  }
}

sub get_nextnum
{
    my($this, $num);
    foreach (sort {$a <=> $b} keys %date) {
	$num = $_;
    }
    $num++;
    return $num;
}

sub get_search
{
    my($this, $searchstring) = @_;
    my($num, $note, $date, %res, $match);

    my $regex = $this->generate_search($searchstring);
    eval $regex;
    if ($@) {
	print "invalid expression: \"$searchstring\"!\n";
	return;
    }
    $match = 0;
    foreach $num (sort {$a <=> $b} keys %date) {
	$_ = $this->ude($note{$num});
	eval $regex;
	if ($match) {
	    $res{$num}->{'note'} = $this->ude($note{$num});
	    $res{$num}->{'date'} = $this->ude($date{$num});
	}
	$match = 0;
    }

    return %res;
}



sub set_recountnums
{
    my $this = shift;
    my(%Note, %Date, $num, $setnum);
    $setnum = 1;
    foreach $num (sort {$a <=> $b} keys %note) {
	$Note{$setnum} = $note{$num};
	$Date{$setnum} = $date{$num};
	$setnum++;
    }
    %note = %Note;
    %date = %Date;
}



sub set_edit
{
    my($this, $num, $note, $date) = @_;
    $note{$num} = $this->uen($note);
    $date{$num} = $this->uen($date);
}


sub set_new
{
    my($this, $num, $note, $date) = @_;
    $this->set_edit($num, $note, $date); # just the same thing
}


sub set_del
{
    my($this, $num) = @_;
    my($note, $date, $T);
    ($note, $date) = $this->get_single($num);
    return "ERROR"  if ($date !~ /^\d/);
    delete $note{$num};
    delete $date{$num};
}

sub set_del_all
{
    my($this) = @_;
    %note = ();
    %date = ();
    return;
}

sub uen
{
    my $this = shift;
    my($T);
    if($NOTEDB::crypt_supported == 1) {
	eval {
	    $T = pack("u", $this->{cipher}->encrypt($_[0]));
	};
    }
    else {
	$T = $_[0];
    }
    chomp $T;
    return $T;
}

sub ude
{
    my $this = shift;
    my($T);
    if($NOTEDB::crypt_supported == 1) {
	eval {
	    $T = $this->{cipher}->decrypt(unpack("u",$_[0]))
	};
	return $T;
    }
    else {
	return $_[0];
    }
}



1; # keep this!

__END__

=head1 NAME

NOTEDB::dbm - module lib for accessing a notedb from perl

=head1 SYNOPSIS

	# include the module
	use NOTEDB;
	
	# create a new NOTEDB object (the last 4 params are db table/field names)
	$db = new NOTEDB("mysql","note","/home/user/.notedb/");

	# get a single note
	($note, $date) = $db->get_single(1);

	# search for a certain note 
	%matching_notes = $db->get_search("somewhat");
	# format of returned hash:
	#$matching_notes{$numberofnote}->{'note' => 'something', 'date' => '23.12.2000 10:33:02'}

	# get all existing notes
	%all_notes = $db->get_all();
	# format of returnes hash like the one from get_search above

	# get the next noteid available
	$next_num = $db->get_nextnum();

	# recount all noteids starting by 1 (usefull after deleting one!)
	$db->set_recountnums();

	# modify a certain note
	$db->set_edit(1, "any text", "23.12.2000 10:33:02");

	# create a new note
	$db->set_new(5, "any new text", "23.12.2000 10:33:02");

	# delete a certain note
	$db->set_del(5);

=head1 DESCRIPTION

You can use this module for accessing a note database. This is the dbm module.
It uses the DB_FILE module to store it's data and it uses DBM files for tis purpose.

Currently, NOTEDB module is only used by note itself. But feel free to use it
within your own project! Perhaps someone want to implement a webinterface to
note...

=head1 USAGE

please see the section SYNOPSIS, it says it all.

=head1 AUTHOR

Thomas Linden <tom@daemon.de>.



=cut
