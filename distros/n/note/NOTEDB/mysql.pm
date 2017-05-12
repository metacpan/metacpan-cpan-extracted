#
# Perl module for note
# mysql database backend. see docu: perldoc NOTEDB::mysql
#


package NOTEDB::mysql;

$NOTEDB::mysql::VERSION = "1.51";

use DBI;
use strict;
#use Data::Dumper;
use NOTEDB;

use Exporter ();
use vars qw(@ISA @EXPORT);
@ISA = qw(NOTEDB Exporter);




sub new {
    my($this, %param) = @_;

    my $class = ref($this) || $this;
    my $self = {};
    bless($self,$class);

    my $dbname   = $param{dbname}   || "note";
    my $dbhost   = $param{dbhost}   || "localhost";
    my $dbuser   = $param{dbuser}   || "";
    my $dbpasswd = $param{dbpasswd} || "";
    my $dbport   = $param{dbport}   || "";
    my $fnum     = "number";
    my $fnote    = "note";
    my $fdate    = "date";
    my $ftopic   = "topic";

    my $database;
    if ($dbport) {
	$database = "DBI:mysql:$dbname;host=$dbhost:$dbport";
    }
    else {
	$database = "DBI:mysql:$dbname;host=$dbhost";
    }

    $self->{table}         = "note";

    $self->{sql_getsingle} = "SELECT $fnote,$fdate,$ftopic FROM $self->{table} WHERE $fnum = ?";
    $self->{sql_all}       = "SELECT $fnum,$fnote,$fdate,$ftopic FROM $self->{table}";
    $self->{sql_nextnum}   = "SELECT max($fnum) FROM $self->{table}";
    $self->{sql_incrnum}   = "SELECT $fnum FROM $self->{table} ORDER BY $fnum";
    $self->{sql_setnum}    = "UPDATE $self->{table} SET $fnum = ? WHERE $fnum = ?";
    $self->{sql_edit}      = "UPDATE $self->{table} SET $fnote = ?, $fdate = ?, $ftopic = ? WHERE $fnum = ?";
    $self->{sql_insertnew} = "INSERT INTO $self->{table} VALUES (?, ?, ?, ?)";
    $self->{sql_del}       = "DELETE FROM $self->{table} WHERE $fnum = ?";
    $self->{sql_del_all}   = "DELETE FROM $self->{table}";

    $self->{DB} = DBI->connect($database, $dbuser, $dbpasswd) or die DBI->errstr();

    return $self;
}


sub DESTROY
{
    # clean the desk!
    my $this = shift;
    $this->{DB}->disconnect;
}


sub lock {
    my($this) = @_;
    # LOCK the database!
    my $lock = $this->{DB}->prepare("LOCK TABLES $this->{table} WRITE")
      || die $this->{DB}->errstr();
    $lock->execute() || die $this->{DB}->errstr();
}


sub unlock {
    my($this) = @_;
    my $unlock = $this->{DB}->prepare("UNLOCK TABLES") || die $this->{DB}->errstr;
    $unlock->execute() || die $this->{DB}->errstr();
}


sub version {
    my $this = shift;
    return $this->{version};
}


sub get_single {
    my($this, $num) = @_;

    my($note, $date, $topic);
    my $statement = $this->{DB}->prepare($this->{sql_getsingle}) || die $this->{DB}->errstr();

    $statement->execute($num) || die $this->{DB}->errstr();
    $statement->bind_columns(undef, \($note, $date, $topic)) || die $this->{DB}->errstr();

    while($statement->fetch) {
      $note = $this->ude($note);
      if ($topic) {
	$note = "$topic\n" . $note;
      }
      return $note, $this->ude($date);
    }
}


sub get_all
{
    my $this = shift;
    my($num, $note, $date, %res, $topic);

    if ($this->unchanged) {
	return %{$this->{cache}};
    }

    my $statement = $this->{DB}->prepare($this->{sql_all}) or die $this->{DB}->errstr();

    $statement->execute or die $this->{DB}->errstr();
    $statement->bind_columns(undef, \($num, $note, $date, $topic)) or die $this->{DB}->errstr();

    while($statement->fetch) {
	$res{$num}->{'note'} = $this->ude($note);
	$res{$num}->{'date'} = $this->ude($date);
	if ($topic) {
	  $res{$num}->{'note'} = "$topic\n" . $res{$num}->{'note'};
	}
    }

    $this->cache(%res);
    return %res;
}


sub get_nextnum
{
    my $this = shift;
    my($num);
    if ($this->unchanged) {
	$num = 1;
	foreach (keys %{$this->{cache}}) {
	    $num++;
	}
	return $num;
    }

    my $statement = $this->{DB}->prepare($this->{sql_nextnum}) || die $this->{DB}->errstr();

    $statement->execute || die $this->{DB}->errstr();
    $statement->bind_columns(undef, \($num)) || die $this->{DB}->errstr();

    while($statement->fetch) {
	return $num+1;
    }
}

sub get_search
{
    my($this, $searchstring) = @_;
    my($num, $note, $date, %res, $match, $use_cache, $topic);

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

    my $statement = $this->{DB}->prepare($this->{sql_all}) or die $this->{DB}->errstr();

    $statement->execute or die $this->{DB}->errstr();
    $statement->bind_columns(undef, \($num, $note, $date, $topic)) or die $this->{DB}->errstr();

    while($statement->fetch) {
	$note = $this->ude($note);
	$date = $this->ude($date);
	if ($topic) {
	  $note = "$topic\n" . $note;
	}
	$_ = $note;
	eval $regex;
	if($match) {
	    $res{$num}->{'note'} = $note;
	    $res{$num}->{'date'} = $date;
	}
	$match = 0;
    }
    return %res;
}




sub set_edit
{
    my($this, $num, $note, $date) = @_;

    $this->lock;
    my $statement = $this->{DB}->prepare($this->{sql_edit}) or die $this->{DB}->errstr();
    $note =~ s/'/\'/g;
    $note =~ s/\\/\\\\/g;
    $statement->execute($this->uen($note), $this->uen($date), $num)
      or die $this->{DB}->errstr();
    $this->unlock;
    $this->changed;
}


sub set_new
{
    my($this, $num, $note, $date) = @_;
    $this->lock;
    my $statement = $this->{DB}->prepare($this->{sql_insertnew}) || die $this->{DB}->errstr();

    my ($topic, $note) = $this->get_topic($note);

    $note =~ s/'/\'/g;
    $note =~ s/\\/\\\\/g;
    $topic =~ s/\\/\\\\/g;
    $statement->execute($num, $this->uen($note), $this->uen($date), $topic) || die $this->{DB}->errstr();
    $this->unlock;
    $this->changed;
}


sub set_del
{
    my($this, $num) = @_;
    my($note, $date, $T);

    $this->lock;
    ($note, $date) = $this->get_single($num);

    return "ERROR"  if ($date !~ /^\d/);

    # delete record!
    my $statement = $this->{DB}->prepare($this->{sql_del}) || die $this->{DB}->errstr();
    $statement->execute($num) || die $this->{DB}->errstr();
    $this->unlock;
    $this->changed;
    return;
}


sub set_del_all
{
    my($this) = @_;
    $this->lock;
    my $statement = $this->{DB}->prepare($this->{sql_del_all}) || die $this->{DB}->errstr();
    $statement->execute() || die $this->{DB}->errstr();
    $this->unlock;
    $this->changed;
    return;
}

sub set_recountnums {
    my $this = shift;

    $this->lock;

    my(@count, $i, $num, $setnum, $pos);
    $setnum = 1;
    $pos=0; $i=0; @count = ();

    my $statement = $this->{DB}->prepare($this->{sql_incrnum}) || die $this->{DB}->errstr();
    $statement->execute || die $this->{DB}->errstr();
    $statement->bind_columns(undef, \($num)) || die $this->{DB}->errstr();
    # store real id's in an array!
    while($statement->fetch) {
	$count[$i] = $num;
	$i++;
    }
    # now recount them! 
    my $sub_statement = $this->{DB}->prepare($this->{sql_setnum}) || die $this->{DB}->errstr();
    for($pos=0;$pos<$i;$pos++) {
	$setnum = $pos +1;
	$sub_statement->execute($setnum,$count[$pos]) || die $this->{DB}->errstr();
    }
    $this->unlock;
    $this->changed;
}

sub import_data {
  my ($this, $data) = @_;
  foreach my $num (keys %{$data}) {
    my $pos = $this->get_nextnum();
    $this->set_new($pos, $data->{$num}->{note}, $data->{$num}->{date});
  }
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

sub get_topic {
  my ($this, $data) = @_;
  if ($data =~ /^\//) {
    my($topic, $note) = split /\n/, $data, 2;
    return ($topic, $note);
  }
  else {
    return ("", $data);
  }
}

1; # keep this!

__END__

=head1 NAME

NOTEDB::mysql - module lib for accessing a notedb from perl

=head1 SYNOPSIS

	# include the module
	use NOTEDB;

	# create a new NOTEDB object (the last 4 params are db table/field names)
	$db = new NOTEDB("mysql","note","localhost","username","password","note","number","note","date");

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

	# turn on encryption. CryptMethod must be IDEA, DES or BLOWFISH
	$db->use_crypt("passphrase", "CryptMethod");

	# turn off encryption. This is the default.
	$db->no_crypt();

=head1 DESCRIPTION

You can use this module for accessing a note database. There are currently
two versions of this module, one version for a SQL database and one for a
binary file (note's own database-format).
However, both versions provides identical interfaces, which means, you do
not need to change your code, if you want to switch to another database format.

Currently, NOTEDB module is only used by note itself. But feel free to use it
within your own project! Perhaps someone want to implement a webinterface to
note...

=head1 USAGE

please see the section SYNOPSIS, it says it all.

=head1 AUTHOR

Thomas Linden <tom@daemon.de>.



=cut
