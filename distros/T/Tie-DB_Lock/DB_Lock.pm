package Tie::DB_Lock;

use strict;
use Carp;
use Fcntl(':flock');
use DB_File;
use FileHandle;

use vars qw($VERSION $WAIT_TIME $RETRIES $TEMPDIR $VERBOSE $TIEPACK);
$VERSION = '0.07';

$TEMPDIR   = '/tmp'    unless defined $TEMPDIR;
$TIEPACK   = 'DB_File' unless defined $TIEPACK;
$WAIT_TIME = 1         unless defined $WAIT_TIME;
$RETRIES   = 15        unless defined $RETRIES;
$VERBOSE   = 0         unless defined $VERBOSE;  # Print out diagnostics on STDERR?

# For internal use only:
my $READ_WRITE = O_CREAT|O_RDWR;
my $READ_ONLY = O_RDONLY;

# Values acceptable to lock_file:
my %LOCKS = (
	     "ex" => LOCK_EX|LOCK_NB,   # Exclusive
	     "sh" => LOCK_SH|LOCK_NB,   # Shared
	     "un" => LOCK_UN|LOCK_NB,   # Unlock
	    );

sub jabber ($) { carp("$$: $_[0]") if $VERBOSE }

sub TIEHASH {
  my $class = shift;
  my $filename = shift;
  my $mode = shift() . '';
  my $self = {'db' => {},
	      'fh' => undef,
	      'mode' => $mode,
	     };
  
  if ($mode eq 'rw') {
    # Open a hashfile and put an exclusive lock on it.
    
    jabber "Attempting to gain read/write access to $filename";
    
    if (not -e $filename) {
      jabber "$filename doesn't exist, creating it";
      # Create it in the proper format.  This is necessary for locking:
      unless (defined ($self->{'db'} = $TIEPACK->TIEHASH($filename, $READ_WRITE, 0660)) ) {
	jabber "Couldn't create $filename: $!";
	return;
      }
      delete $self->{'db'};
    }
    
    # Try to lock the file:
    if ($self->{'fh'} = new FileHandle($filename,$READ_WRITE)) {
      jabber "Opened $filename";
    } else {
      jabber "Couldn't open $filename for locking: $!";
      return;
    }
    unless (lock_file($self->{'fh'}, 'ex')) {
      jabber "Couldn't lock $filename";
      close $self->{'fh'};
      return;
    }
    
    # Tie a hash to the file:
    $self->{'db'} = $TIEPACK->TIEHASH($filename, $READ_WRITE, 0660);
    
  } else {
    jabber "Attempting to gain read-only access to $filename";
    
    
    my $tempfile = "$TEMPDIR/" . _random_string();
    
    # Try to lock the file:
    my $temp_fh = new FileHandle($filename);
    unless (defined $temp_fh) {
      jabber "Couldn't open $filename for reading: $!";
      return;
    }
    unless (lock_file($temp_fh, 'sh')) {
      jabber "Couldn't lock $filename, aborting dbm_open_ro";
      close $temp_fh;
      return;
    }
    
    # Copy to a tempfile:
    
    unless (system ("cp $filename $tempfile") == 0) {
      jabber "cp of $filename to $tempfile failed: $!";
      return;
    }
    jabber "Copied $filename to $tempfile";
    
    
    # Unlock & close:
    unless ( lock_file($temp_fh, 'un')) {
      jabber "Couldn't unlock $filename: $!";
      close $temp_fh;
      unless (unlink $tempfile) {
	jabber "IMPORTANT! Couldn't unlink tempfile $tempfile: $!";
      }
      return;
    }
    close $temp_fh;
    
    
    # Tie the tempfile:
    $self->{'db'} = $TIEPACK->TIEHASH($tempfile, $READ_ONLY, 0660);
    $self->{tempfile} = $tempfile;
    
    # Delete the tempfile (don't worry, it will appear to remain
    # around until you close it, at least on UNIX):
    unless (unlink $tempfile) {
      warn("Couldn't remove tempfile $tempfile: $!");
      return;
    }
  }
  
  unless ($self->{'db'}) {
    carp "$TIEPACK->TIEHASH failed: $!";
    return;
  }
  
  return bless $self, $class;
}

sub tempfile { $_[0]->{tempfile} }

sub DESTROY {
  # Called to close, unlock, and untie a hashfile:
  
  my $self = shift;
  
  jabber "Database closing process begun";
  
  delete $self->{'db'};
  
  if ($self->{'mode'} eq 'rw') {
    jabber "Closing read/write file";
    
    # Close the file - this removes the lock too
    close $self->{'fh'} or croak "Couldn't unlock & close database: $!";
  }
  
  jabber "dbm_close completed";
  
  return 1;
}

#line 161
sub FETCH      { my $self=shift; $self->{'db'}->FETCH(@_) }
sub STORE      { my $self=shift; $self->{'db'}->STORE(@_) }
sub DELETE     { my $self=shift; $self->{'db'}->DELETE(@_) }
sub FIRSTKEY   { my $self=shift; $self->{'db'}->FIRSTKEY(@_) }
sub NEXTKEY    { my $self=shift; $self->{'db'}->NEXTKEY(@_) }
sub EXISTS     { my $self=shift; $self->{'db'}->EXISTS(@_) }
sub CLEAR      { my $self=shift; $self->{'db'}->CLEAR(@_) }


sub _random_string {
  # Usage: $filehandle = _random_string($n_chars);
  #
  # Returns a string made of $n_chars (default 9) random letters.
  
  my $chars = @_ ? shift() : 9;
  my $string_chars = "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm";
  
  my $string_out = '';
  my $i;
  for($i=0; $i<$chars; $i++) {
    $string_out .= substr($string_chars, int(rand length $string_chars), 1);
  }
  return $string_out;
}

sub lock_file($$) {
  # Usage: lock_file FILEHANDLE, lock_type;
  #        where FILEHANDLE is an _open_ filehandle, 
  #        and lock_type is "ex" or "sh" for exclusive or shared locks.
  
  my $filehandle = shift;
  my $type       = shift;
  my ($i, $didlock) = (0,0);
  
  unless (exists $LOCKS{$type}) { croak("Invalid lock type: '$type'"); }
  
  # Try to apply the lock:
  while (1) {
    if (flock ($filehandle, $LOCKS{$type})) {
      jabber "Lock successfully obtained";
      $didlock = 1;
      last;
    } else {
      jabber "Lock attempt $i failed: $!";
    }

    last if ++$i > $RETRIES;
    jabber "Sleeping for $WAIT_TIME seconds";
    sleep $WAIT_TIME;
  }
    
  unless ($didlock) {
    jabber "Lock ($type) attempt $i (final) failed ($!), aborting";
    return 0;
  }
  
  return 1;
}

1;
__END__

=head1 NAME

Tie::DB_Lock - ties hashes to databases using shared and exclusive locks

=head1 SYNOPSIS

 use Tie::DB_Lock;
 use DB_File;
 
 tie(%hash, 'Tie::DB_Lock', $filename, 'rw');  # Open for writing
 $hash{'key'} = 'value';
 untie %hash;
 
 tie(%hash2, 'Tie::DB_Lock', $filename); # Default is read-only
 print("Value is $hash2{'key'}\n");
 untie %hash;

=head1 DESCRIPTION

This is a front-end for the DB_File package.

If you tie a hash in read-only mode, this module puts a shared lock on
the database file, copies it to a temporary file, unlocks the original 
database, and then ties the tempfile using DB_File.

If you tie the hash in read-write mode, we put an exclusive lock on the
database and tie it directly using DB_File.

The reason I copy the whole file every time I read from it is that this
allows the program to read from the file for as long as it wants to, without
interfering with other people's writes.  This works well if you typically
have long, sustained reads, and short, bursty writes.  See the README file
for help in deciding whether you want to use this package.

You don't always need to call untie() explicitly - it will be called for
you when %hash goes out of scope.  And if all goes as planned, you'll never
know the temporary file ever existed, since it will evaporate when %hash
goes away.




=head1 OPTIONS

=over 4

=item * $Tie::DB_Lock::TEMPDIR

You can specify the directory in which to place the temporary files that
get created when you open a database for read-only access.  To do so, 
set the variable C<$Tie::DB_Lock::TEMPDIR> to the directory you want
to use.  You may get the best results if your temporary directory resides
on the same disk (or filesystem) as your databases.

=item * $Tie::DB_Lock::WAIT_TIME

=item * $Tie::DB_Lock::RETRIES

By default, DB_Lock will try once every second for fifteen seconds to
put locks on the things it's trying to lock.  After that it will give
up.  Change the number of seconds between attempts by setting the
value of C<$Tie::DB_Lock::WAIT_TIME> (must be an integer), and change
the number of attempts by setting the value of
C<$Tie::DB_Lock::RETRIES>.


=item * $Tie::DB_Lock::VERBOSE

If you think something funny is going on with your database and you
want to watch the locking process happening, you can set the variable
C<$Tie::DB_Lock::VERBOSE> to a true value.  A bunch of diagnostic
messages will get printed to STDERR.


=item * $Tie::DB_Lock::TIEPACK

Don't change this unless you're sure.  If you change it, DB_Lock will
use a different back-end database TIEHASH package instead of DB_File.
Any database you want to use must reside entirely in a single file so
that it can be locked properly and copied to the temporary directory.
Support for other database formats should be considered experimental.

=back

=head1 WARNINGS

Whenever a tie() fails because a lock blocked your access, tie() will
return the undefined value.  CHECK THE RETURN VALUE from tie()!

  tie(%hash, 'Tie::DB_Lock', $file, 'rw') or die $!;

If you don't check the return value, you'll probably continue on your
merry way, thinking that you opened the database when in fact you
didn't.

=head1 A NOTE ON DEADLOCK, by Jay Scott

Deadlock is rare, but it's awful when it happens.

If each process wants more than one DB file before it can start work,
and processes do not all ask for their DB files in the same order, and
the processes write, then there's a risk of deadlock. The simplest
case is that process 1 wants files A and B and holds A, and process 2
wants A and B and holds B. Neither process can get what it needs, and
they both wait forever. To avoid this, do one of the following: (1)
Have all processes open DB files in the same order, first A, then
B. (2) Use a special locking or coordination scheme.

Deadlock can happen pretty much whenever you're using locks on a
resource.

=head1 TO DO

Maybe change from using FileHandle to IO::File?  Benchmarks involved.

Allow other database back-ends than DB_File.


=head1 AUTHOR

Ken Williams				ken@forum.swarthmore.edu

Copyright (c) 1998 Ken Williams. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), perltie(1), perlfunc(1), DB_File(3)

=cut
