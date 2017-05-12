=head1 CLASS
Title:	POP::Id_factory.pm
Desc:	Abstract class for all id factories.  Derived classes should call
	constructor with an argument for the file.  Derived class may
	(and should) use $ENV{'FACTORY_HOME'}, which is set to a default value
	here.
Author:	B. Holzman
=cut

package POP::Id_factory;

$VERSION = do{my(@r)=q$Revision: 1.2 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

# Get, or set to default, the directory holding the ID file.
BEGIN {
	$ENV{'FACTORY_HOME'} ||= '.';
      }

use strict;
use Carp;
use Symbol;
use SelectSaver;
use POSIX qw/EBADF EDEADLK/;
use File::lockf;
use vars qw/$VERSION/;

# PUBLIC METHODS

=head2 CONSTRUCTOR
Title:	Id_Factory::new
Desc:	Constructor
Error:  YES
=cut

sub new {
  my($type, $file) = @_;
  my $no;
  my $this = {'file' => $file};

  # Open the ID file.
  my $sym = gensym;
  unless (open($sym, "+<$file")) {
    croak "Couldn't open [$file]: $!";
  }
  my $old = new SelectSaver $sym;
  $| = 1;
  $this->{'fh'} = $sym;
  return bless $this, $type;
}

=head2 DESTRUCTOR
Title:	Id_factory::DESTROY
Desc:	Destructor
Error:	NO
=cut

sub DESTROY { }

=head2 METHOD
Title:	Id_factory::next
Desc:	Locks factory file, reads in current id, increments, writes it back
	out, and unlocks.
Error:	YES
=cut

sub next {
  my $this = shift;
  my $fh = $this->{'fh'};

  # First, seek to the beginning:
  seek($fh,0,0);
  $this->_lock;

  # Read in current ID
  my $old_id;
  chomp($old_id = <$fh>);

  # Increment ID
  my $new_id = $this->_id_increment($old_id);
  unless ($new_id) {
    croak "Couldn't increment [$old_id]";
  }
  # Write ID out
  seek($fh,0,0);
  print $fh "$new_id\n";
  truncate($fh,length($new_id)+1);
  $this->_unlock;

  return $new_id;
}

=head2 METHOD
Title:	Id_factory::set
Desc:	Sets the current value in the ID file to the given arg. 
	Primarily a maintenance tool.
Error:	YES
=cut
sub set {
  my($this, $value) = @_;
  my $fh = $this->{'fh'};
  unless (defined($value)) {
    croak "No value supplied";
  }
  seek($fh,0,0);
  
  $this->_lock;

  print $fh "$value\n";
  truncate($fh,length($value) + 1);
  $this->_unlock;
}

# PRIVATE METHODS

=head2 METHOD
Title:	Id_factory::_lock
Desc:	Carefully locks filehandle; will use $this->{'fh'} by default, or Arg1.
	For message logging, uses $this->{'file'} as filename, or Arg2.
Error:	YES
=cut

sub _lock {
  my $this = shift;
  my $fh = shift || $this->{'fh'};
  my $file = shift || $this->{'file'};
  my $retries = 3;
  my $status = undef;
  my $no;
  do { 
    $status = File::lockf::lock($fh);
    if ($status == EBADF) {
      croak "Bad filehandle error locking [$file]";
    } elsif ($status == EDEADLK) {
      unless (--$retries) {
	croak "Deadlock error locking [$file]";
      }
      # let's take a nap and try again...
      sleep 2;
    } elsif ($status) { # This should be ECOMM, but it's not in POSIX
      unless (--$retries) {
	croak "Communication error (NFS?) locking [$file]";
      }
      # let's give NFS a little time...
      sleep 10;
    } else {
      $retries = 0;
    }
  } while ($retries);
}

=head2 METHOD
Title:	Id_factory::_unlock
Desc:	Unlocks filehandle. Filehandle is $this->{'fh'} or Arg1.
	Filename is $this->{'file'} or Arg2.
Error:  NO
=cut

sub _unlock {
  my $this = shift;
  my $fh = shift || $this->{'fh'};
  my $file = shift || $this->{'file'};
  my $status = undef;
  seek($fh,0,0);
  $status = File::lockf::ulock($fh);
  if ($status == EBADF) {
    croak "Bad filehandle error unlocking [$file]";
  } elsif ($status == EDEADLK) {
    croak "Lock table full error unlocking [$file]";
  } elsif ($status) { # Should be ECOMM, not defined in POSIX
    # XXX This ain't portable, no doubt.
    croak "Communication error (NFS?) unlocking [$file]";
  }
}

=head2 METHOD
Title:	Id_factory::_id_increment
Desc:	Default ID incrementing method. (numeric)
Error:  NO
=cut

sub _id_increment {
  my($this,$old_id) = @_;
  if (!defined($old_id) or $old_id < 0) {
    return;
  }
  return $old_id + 1;
}

$VERSION=$VERSION;
