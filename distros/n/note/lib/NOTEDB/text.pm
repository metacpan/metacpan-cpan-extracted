# Perl module for note
# text database backend. see docu: perldoc NOTEDB::text
# using Storable as backend.

package NOTEDB::text;

$NOTEDB::text::VERSION = "1.04";

use strict;
#use Data::Dumper;
use File::Spec;
use Storable qw(lock_nstore lock_retrieve);
use MIME::Base64;

use NOTEDB;

use Fcntl qw(LOCK_EX LOCK_UN);

use Exporter ();
use vars qw(@ISA @EXPORT);
@ISA = qw(NOTEDB Exporter);




sub new {
    my($this, %param) = @_;

    my $class = ref($this) || $this;
    my $self = {};
    bless($self,$class);

    $self->{NOTEDB} = $self->{dbname} = $param{dbname}   || File::Spec->catfile($ENV{HOME}, ".notedb");

    if(! -e $param{dbname}) {
	open(TT,">$param{dbname}") or die "Could not create $param{dbname}: $!\n";
	close (TT);
    }
    elsif(! -w $param{dbname}) {
	print "$param{dbname} is not writable!\n";
	exit(1);
    }

    $self->{LOCKFILE} = $param{dbname} . "~LOCK";
    $self->{mtime}    = $self->get_stat();
    $self->{unread}   = 1;
    $self->{data}     = {};

    return $self;
}


sub DESTROY
{
    # clean the desk!
}

sub version {
    my $this = shift;
    return $NOTEDB::text::VERSION;
}

sub get_stat {
  my ($this) = @_;
  my $mtime = (stat($this->{dbname}))[9];
  return $mtime;
}


sub set_del_all {
    my $this = shift;
    unlink $this->{NOTEDB};
    open(TT,">$this->{NOTEDB}") or die "Could not create $this->{NOTEDB}: $!\n";
    close (TT);
}


sub get_single {
    my($this, $num) = @_;
    my($address, $note, $date, $n, $t, $buffer, );

    my %data = $this->get_all();

    return ($data{$num}->{note}, $data{$num}->{date});
}


sub get_all {
    my $this = shift;
    my($num, $note, $date, %res);

    if ($this->unchanged) {
	return %{$this->{cache}};
    }

    my %data = $this->_retrieve();

    foreach my $num (keys %data) {
	$res{$num}->{note} = $this->ude($data{$num}->{note});
	$res{$num}->{date} = $this->ude($data{$num}->{date});
    }

    $this->cache(%res);
    return %res;
}

sub import_data {
  my ($this, $data) = @_;
  my %res = $this->_retrieve();
  my $pos = (scalar keys %res) + 1;
  foreach my $num (keys %{$data}) {
    $res{$pos}->{note} = $this->uen($data->{$num}->{note});
    $res{$pos}->{date} = $this->uen($data->{$num}->{date});
    $pos++;
  }
  $this->_store(\%res);
}

sub get_nextnum {
    my $this = shift;
    my($num, $te, $me, $buffer);

    if ($this->unchanged) {
      my @numbers = sort { $a <=> $b } keys %{$this->{cache}};
      $num = pop @numbers;
      $num++;
      return $num;
    }

    my %data = $this->get_all();
    my @numbers = sort { $a <=> $b } keys %data;
    $num = pop @numbers;
    $num++;
    return $num;
}

sub get_search {
    my($this, $searchstring) = @_;
    my($buffer, $num, $note, $date, %res, $t, $n, $match);

    my $regex = $this->generate_search($searchstring);
    eval $regex;
    if ($@) {
	print "invalid expression: \"$searchstring\"!\n";
	return;
    }
    $match = 0;

    if ($this->unchanged) {
	foreach my $num (keys %{$this->{cache}}) {
	    $_ = $this->{cache}{$num}->{note};
	    eval $regex;
	    if ($match) {
		$res{$num}->{note} = $this->{cache}{$num}->{note};
		$res{$num}->{date} = $this->{cache}{$num}->{date}
	    }
	    $match = 0;
	}
	return %res;
    }

    my %data =  $this->get_all();

    foreach my $num(sort keys %data) {
	$_ = $data{$num}->{note};
	eval $regex;
	if($match)
	  {
	      $res{$num}->{note} = $data{$num}->{note};
	      $res{$num}->{date} = $data{$num}->{data};
	  }
	$match = 0;
    }

    return %res;
}




sub set_edit {
    my($this, $num, $note, $date) = @_;

    my %data = $this->_retrieve();

    $data{$num} = {
		   note => $this->uen($note),
		   date => $this->uen($date)
		   };

    $this->_store(\%data);

    $this->changed;
}


sub set_new {
    my($this, $num, $note, $date) = @_;
    $this->set_edit($num, $note, $date);
}


sub set_del {
    my($this, $num) = @_;
    my(%data, $note, $date, $T, $setnum, $buffer, $n, $N, $t);

    $setnum = 1;

    %data = $this->_retrieve();
    return "ERROR" if (! exists $data{$num});

    delete $data{$num};

    $this->_store(\%data);

    $this->changed;

    return;
}

sub set_recountnums {
    # not required here
    return;
}

sub uen {
    my ($this, $raw) = @_;
    my($crypted);
    if($NOTEDB::crypt_supported == 1) {
	eval {
	    $crypted = $this->{cipher}->encrypt($raw);
	};
    }
    else {
	$crypted = $raw;
    }
    my $coded = encode_base64($crypted);
    return $coded;
}

sub ude {
    my ($this, $crypted) = @_;
    my($raw);
    if($NOTEDB::crypt_supported == 1) {
	eval {
	    $raw = $this->{cipher}->decrypt(decode_base64($crypted));
	};
    }
    else {
	$raw = decode_base64($crypted)
    }
    return $raw;
}


sub _store {
  my ($this, $data) = @_;
  lock_nstore($data, $this->{NOTEDB});
}

sub _retrieve {
  my $this = shift;
  if (-s $this->{NOTEDB}) {
    if ($this->changed() || $this->{unread}) {
      my $data = lock_retrieve($this->{NOTEDB});
      $this->{unread} = 0;
      $this->{data}   = $data;
      return %{$data};
    }
  }
  else {
    return ();
  }
}


1; # keep this!

__END__

=head1 NAME

NOTEDB::text - module lib for accessing a notedb from perl

=head1 SYNOPSIS

	# include the module
	use NOTEDB;

	# create a new NOTEDB object
	$db = new NOTEDB("text", "/home/tom/.notedb", 4096, 24);

	# decide to use encryption
	# $key is the cipher to use for encryption
	# $method must be either Crypt::IDEA or Crypt::DES
	# you need Crypt::CBC, Crypt::IDEA and Crypt::DES to have installed.
	$db->use_crypt($key,$method);

	# do not use encryption
	# this is the default
	$db->no_crypt;

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

	# modify a certain note
	$db->set_edit(1, "any text", "23.12.2000 10:33:02");

	# create a new note
	$db->set_new(5, "any new text", "23.12.2000 10:33:02");

	# delete a certain note
	$db->set_del(5);

        # turn on encryption. CryptMethod must be IDEA, DES or BLOWFISH
        $db->use_crypt("passphrase", "CryptMethod");

        # turn off encryption. This is the default.
        $db->no_crypt();


=head1 DESCRIPTION

You can use this module for accessing a note database. This backend uses
a text file for storage and Storable for accessing the file.

Currently, NOTEDB module is only used by note itself. But feel free to use it
within your own project! Perhaps someone want to implement a webinterface to
note...

=head1 USAGE

please see the section SYNOPSIS, it says it all.

=head1 AUTHOR

Thomas Linden <tom@daemon.de>.


=cut
