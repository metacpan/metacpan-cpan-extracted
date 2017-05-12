# Perl module for note
# pwsafe3 backend. see docu: perldoc NOTEDB::pwsafe3

package NOTEDB::pwsafe3;

$NOTEDB::pwsafe3::VERSION = "1.08";
use strict;
use Data::Dumper;
use Time::Local;
use Crypt::PWSafe3;

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

    $self->{dbname}  = $param{dbname}   || File::Spec->catfile($ENV{HOME}, ".notedb");

    $self->{mtime}    = $self->get_stat();
    $self->{unread}   = 1;
    $self->{data}     = {};
    $self->{LOCKFILE} = $param{dbname} . "~LOCK";
    $self->{keepkey} = 0;

    return $self;
}


sub DESTROY {
  # clean the desk!
}

sub version {
    my $this = shift;
    return $NOTEDB::pwsafe3::VERSION;
}

sub get_stat {
  my ($this) = @_;
  if(-e $this->{dbname}) {
    return (stat($this->{dbname}))[9];
  }
  else {
    return time;
  }
}

sub filechanged {
  my ($this) = @_;
  my $current = $this->get_stat();

  if ($current > $this->{mtime}) {
    $this->{mtime} = $current;
    return $current;
  }
  else {
    return 0;
  }
}

sub set_del_all {
    my $this = shift;
    unlink $this->{dbname};
    open(TT,">$this->{dbname}") or die "Could not create $this->{dbname}: $!\n";
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
	($res{$num}->{date}, $res{$num}->{note}) = $this->_pwsafe3tonote($data{$num}->{note});
    }

    $this->cache(%res);
    return %res;
}

sub import_data {
  my ($this, $data) = @_;

  my $fh;

  if (-s $this->{dbname}) {
    $fh = new FileHandle "<$this->{dbname}" or die "could not open $this->{dbname}\n";
    flock $fh, LOCK_EX;
  }

  my $key   = $this->_getpass();

  eval {
    my $vault = new Crypt::PWSafe3(password => $key, file => $this->{dbname});

    foreach my $num (keys %{$data}) {
      my $checksum = $this->get_nextnum();
      my %record = $this->_notetopwsafe3($checksum, $data->{$num}->{note}, $data->{$num}->{date});

      my $rec = new Crypt::PWSafe3::Record();
      $rec->uuid($record{uuid});
      $vault->addrecord($rec);
      $vault->modifyrecord($record{uuid}, %record);
    }

    $vault->save();
  };
  if ($@) {
    print "Exception caught:\n$@\n";
    exit 1;
  }

  eval {
    flock $fh, LOCK_UN;
    $fh->close();
  };

  $this->{keepkey} = 0;
  $this->{key} = 0;
}

sub get_nextnum {
    my $this = shift;
    my($num, $te, $me, $buffer);

    my $ug    = new Data::UUID;

    $this->{nextuuid} =  unpack('H*', $ug->create());
    $num = $this->_uuid( $this->{nextuuid} );

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

    my %record = $this->_notetopwsafe3($num, $note, $date);

    if (exists $data{$num}) {
      $data{$num}->{note} = \%record;
      $this->_store(\%record);
    }
    else {
      %record = $this->_store(\%record, 1);
    }

    $this->changed;
}


sub set_new {
    my($this, $num, $note, $date) = @_;
    $this->set_edit($num, $note, $date);
}


sub set_del {
  my($this, $num) = @_;

  my $uuid  = $this->_getuuid($num);
  if(! $uuid) {
    print "Note $num does not exist!\n";
    return;
  }

  my $fh = new FileHandle "<$this->{dbname}" or die "could not open $this->{dbname}\n";
  flock $fh, LOCK_EX;

  my $key   = $this->_getpass();
  eval {
    my $vault = new Crypt::PWSafe3(password => $key, file => $this->{dbname});
    delete $vault->{record}->{$uuid};
    $vault->markmodified();
    $vault->save();
  };
  if ($@) {
    print "Exception caught:\n$@\n";
    exit 1;
  }

  eval {
    flock $fh, LOCK_UN;
    $fh->close();
  };

  # finally re-read the db, so that we always have the latest data
  $this->_retrieve($key);
  $this->changed;
  return;
}

sub set_recountnums {
    my($this) = @_;
    # unsupported
    return;
}


sub _store {
  my ($this, $record, $create) = @_;

  my $fh;

  if (-s $this->{dbname}) {
    $fh = new FileHandle "<$this->{dbname}" or die "could not open $this->{dbname}\n";
    flock $fh, LOCK_EX;
  }

  my $key;
  my $prompt = "pwsafe password: ";

  foreach my $try (1..5) {
    if($try > 1) {
      $prompt = "pwsafe password ($try retry): ";
    }
    $key   = $this->_getpass($prompt);
    eval {
      my $vault = new Crypt::PWSafe3(password => $key, file => $this->{dbname});
      if ($create) {
        my $rec = new Crypt::PWSafe3::Record();
        $rec->uuid($record->{uuid});
        $vault->addrecord($rec);
        $vault->modifyrecord($record->{uuid}, %{$record});
      }
      else {
        $vault->modifyrecord($record->{uuid}, %{$record});
      }
      $vault->save();
    };
    if ($@) {
      if($@ =~ /wrong pass/i) {
        $key = '';
        next;
      }
      else {
        print "Exception caught:\n$@\n";
        exit 1;
      }
    }
    else {
      last;
    }
  }
  eval {
    flock $fh, LOCK_UN;
    $fh->close();
  };

  if(!$key) {
    print STDERR "Giving up after 5 failed password attempts.\n";
    exit 1;
  }

  # finally re-read the db, so that we always have the latest data
  $this->_retrieve($key);
}

sub _retrieve {
  my ($this, $key) = @_;
  my $file = $this->{dbname};
  if (-s $file) {
    if ($this->filechanged() || $this->{unread}) {
      my %data;
      if (! $key) {
	$key   = $this->_getpass();
      }
      eval {
	my $vault = new Crypt::PWSafe3(password => $key, file => $this->{dbname});

	my @records = $vault->getrecords();

	foreach my $record (sort { $a->ctime <=> $b->ctime } @records) {
	  my $num = $this->_uuid( $record->uuid );
	  my %entry = (
		       uuid   => $record->uuid,
		       title  => $record->title,
		       user   => $record->user,
		       passwd => $record->passwd,
		       notes  => $record->notes,
		       group  => $record->group,
		       lastmod=> $record->lastmod,
		       ctime  => $record->ctime,
		       );
	  $data{$num}->{note} = \%entry;
	}
      };
      if ($@) {
	print "Exception caught:\n$@\n";
	exit 1;
      }

      $this->{unread} = 0;
      $this->{data}   = \%data;
      return %data;
    }
    else {
      return %{$this->{data}};
    }
  }
  else {
    return ();
  }
}

sub _pwsafe3tonote {
  #
  # convert pwsafe3 record to note record
  my ($this, $record) = @_;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($record->{ctime});
  my $date = sprintf("%02d.%02d.%04d %02d:%02d:%02d", $mday, $mon+1, $year+1900, $hour, $min, $sec);
  chomp $date;
  my $note;
  if ($record->{group}) {
    my $group = $record->{group};
    # convert group separator
    $group =~ s#\.#/#g;
    $note = "/$group/\n";
  }

  # pwsafe3 uses windows newlines, so convert ours
  $record->{notes} =~ s/\r\n/\n/gs;

  #
  # we do NOT add user and password fields here extra
  # because if it is contained in the note, from were
  # it was extracted initially, where it remains anyway
  $note .= "$record->{title}\n$record->{notes}";

  return ($date, $note);
}

sub _notetopwsafe3 {
  #
  # convert note record to pwsafe3 record
  # only used on create or save
  #
  # this one is the critical part, because the two
  # record types are fundamentally incompatible.
  # we parse our record and try to guess the values
  # required for pwsafe3
  #
  # expected input for note:
  # /path/          -> group, optional
  # any text        -> title
  #     User: xxx   -> user
  # Password: xxx   -> passwd
  # anything else   -> notes
  #
  # expected input for date:
  # 23.02.2010 07:56:27
  my ($this, $num, $text, $date) = @_;
  my ($group, $title, $user, $passwd, $notes, $ts, $content);
  if ($text =~ /^\//) {
    ($group, $title, $content) = split /\n/, $text, 3;
  }
  else {
    ($title, $content) = split /\n/, $text, 2;
  }

  if(!defined $content) { $content = ""; }
  if(!defined $group) { $group = ""; }

  $user = $passwd = '';
  if ($content =~ /(user|username|login|account|benutzer):\s*(.+)/i) {
    $user = $2;
  }
  if ($content =~ /(password|pass|passwd|kennwort|pw):\s*(.+)/i) {
    $passwd = $2;
  }

  #               1       2       3       4      5      6      
  if ($date =~ /^(\d\d)\.(\d\d)\.(\d{4}) (\d\d):(\d\d):(\d\d)$/) {
    # timelocal($sec,$min,$hour,$mday,$mon,$year);            
    $ts = timelocal($6, $5, $4, $1, $2-1, $3-1900);
  }

  # make our topics pwsafe3 compatible groups
  $group =~ s#^/##;
  $group =~ s#/$##;
  $group =~ s#/#.#g;

  # pwsafe3 uses windows newlines, so convert ours
  $content =~ s/\n/\r\n/gs;
  my %record = (
		uuid   => $this->_getuuid($num),
		user   => $user,
		passwd => $passwd,
		group  => $group,
		title  => $title,
		ctime  => $ts,
		lastmod=> $ts,
		notes  => $content,
		);
  return %record;
}

sub _uuid {
  my ($this, $uuid) = @_;
  if (exists $this->{uuidnum}->{$uuid}) {
    return $this->{uuidnum}->{$uuid};
  }

  my $max = 0;

  if (exists $this->{numuuid}) {
    $max = (sort { $b <=> $a } keys %{$this->{numuuid}})[0];
  }

  my $num = $max + 1;

  $this->{uuidnum}->{$uuid} = $num;
  $this->{numuuid}->{$num}  = $uuid;

  return $num;
}

sub _getuuid {
  my ($this, $num) = @_;
  return $this->{numuuid}->{$num};
}

sub _getpass {
  #
  # We're doing this here ourselfes
  # because the note way of handling encryption
  # doesn't work with pwsafe3, we can't hold a cipher
  # structure in memory, because pwsafe3 handles this
  # itself.
  # Instead we ask for the password everytime we want
  # to fetch data from the actual file OR want to write
  # to it. To minimize reads, we use caching by default.
  my($this, $prompt) = @_;

  if ($this->{key}) {
    return $this->{key};
  }
  else {
    my $key;
    print STDERR $prompt ? $prompt : "pwsafe password: ";
    eval {
      local($|) = 1;
      local(*TTY);
      open(TTY,"/dev/tty") or die "No /dev/tty!";
      system ("stty -echo </dev/tty") and die "stty failed!";
      chomp($key = <TTY>);
      print STDERR "\r\n";
      system ("stty echo </dev/tty") and die "stty failed!";
      close(TTY);
    };
    if ($@) {
      $key = <>;
    }
    if ($this->{keepkey}) {
      $this->{key} = $key;
    }
    return $key;
  }
}

1; # keep this!

__END__

=head1 NAME

NOTEDB::pwsafe3 - module lib for accessing a notedb from perl

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
a text file for storage and Config::General for accessing the file.

Currently, NOTEDB module is only used by note itself. But feel free to use it
within your own project! Perhaps someone want to implement a webinterface to
note...

=head1 USAGE

please see the section SYNOPSIS, it says it all.

=head1 AUTHOR

Thomas Linden <tom AT linden DOT at>


=cut


