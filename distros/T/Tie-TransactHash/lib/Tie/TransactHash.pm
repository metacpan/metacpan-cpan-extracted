package Tie::TransactHash;

$Tie::TransactHash::VERSION = '0.03'; #BETA; not heavily tested.
use strict;
use Carp;

require Tie::IxHash;
require 5.002; #I think older versions don't have proper working tie.
# please note; perl 5.003 to something below 5.003_25 (that's a
# developers version before perl 5.004) has a bug which causes loss of
# data during the destructor calls at the end opf the program

#TransactHash - a perl module to allow editing of hashes in transactions 
#maintaining the sequence of the hash through the transaction.
#Copyright (c) 1997 Michael De La Rue
#This is free software and may be distributed under the same terms
#as perl.  There is no warantee.  See the file COPYING which should
#have been included with the distribution for one set of terms under
#which it may be distributed.

=head1 NAME

Tie::TransactHash - Edit hash in transactions not changing order during trans.

=head1 SYNOPSIS

     use Tie::TransactHash;
     $::edit_db = tie %::edit_me, TransactHash, \%::db_as_hash, $::db; 
     while (($key, $value)=each %edit_me)) {
       $::edit_me{$key} ++ if $key =~ m/counters/ ;
     }

=head1 DESCRIPTION

Tie::TransactHash is a package which provides facilities for editing
any other hash in transactions.  A transaction is a group of changes
which go together and are either all applied or none.  When working on
a standard perl hash or a hash indexed DBM file, one advantage is that
the original hash remains untouched during the transaction, so its
order (the order the each(), keys() or values functions give out) is
maintained - changes can be made to the transact hash whilst iterating
over it.

=head1 OVERVIEW

Editing a hash causes problems because it rearranges the hash.  If the
editing is to be done in sequence then this makes life difficult.  The
TransactHash class uses a fixed sequence hash class which overlays the
normal hash and allows editing in place.  It stores all of the changes
to the original hash in memory until it is told to apply them.

As a side effect of this design, the class also provides a
commit/rollback system.  When a commit is called, the order of the
hidden hash will be changed.  

A commit will normally be done as the TransactHash object is being
destroyed.  This could be undesirable if your program exits when it
discovers a failure.  You can change the.

If you can accept the re-ordering, then you can do partial
edits and commit half way through.

When working on a DBM file, if a crash occurs during the editing and
no commit has been called then the original hash will be left intact.
If however the crash occurs during the commit, bad things could
happen.

     use DB_File;
     use Tie::TransactHash;
     use Fcntl;

     $::db = tie %::db_as_hash, DB_File, $::dbname, O_RDWR|O_CREAT, 0640, $db_type
       or die $!;

     $::edit_db = tie %::edit_me, TransactHash, \%::db_as_hash, $::db; 
     #the $::db doesn't really do any good right now, but in future it might

     my $count = 0;
     my ($key,$value)
     while(($key,$_)=each %edit_me) {
       s/bouncy/bouncy, very very bouncy./;
       m/Fred/ && do { 
	 $count++;
	 $edit_me{ Fred . $count } = $key;
       }
     }
     print "Found Fred in the values $count times\n";

Generally, this package should be used if you want to occasionally do
small numbers of changes across the values of a large hash.  If you
are using it overly (often or for large numbers of changes on the
database), then you should probably switch to btree indexed hashes
(Berkley DBM) which give you the same ordering effect but don't use a
large chunk of memory.  Alternately you could consider some kind of
multi-pass algorithm (scan through the database putting planned
changes to a file then apply them afterwards all in one go).

=head1 METHODS

=cut

$TransactHash::autostore = 1; #we automatically commit at destructor time.
#$TransactHash::verbose= 0xfff; #
$TransactHash::verbose= 0; #turn this up for debugging messages

sub version { return $Tie::TransactHash::VERSION };

=head2 new( \%hidehash [,$hideobj] )

This creates a new TransactHash, hiding the hash \%hidehash.  

=cut


sub new {
  my $class=shift;
  my $self=bless {}, $class;
  #now for the underlying hash (& possibly it's object) that we are editing
  $self->{"hidehash"} = shift;
  #FIXME check that actually was a hash reference.
  #now create a place to store our changes for the transaction.  
  $self->{"hideobj"} = shift;
  my $tempstore = tie my(%temphash), "Tie::IxHash";
  $self->{"tempstore"} = $tempstore;
  $self->{"temphash"} = \%temphash;
  $self->{"deleted"} = {};
  #FIXME isn't this bad for inheritance?  what is the alternative?
  $self->{"autostore"} = $TransactHash::autostore;
  return $self;
}

=head2 TIEHASH (and other hash methods)

This is simply a call to new.  See above.  The other hash methods are just as
for a standard hash (see perltie) and act just like one.  

=cut

sub TIEHASH {
  return new(@_);
}

sub DESTROY {
  my $self=shift;
  if ($self->{"autostore"}) {
    $self->commit();
  }
}

sub FETCH {
  my $self=shift;
  my $key=shift;
  my $value;
  if (defined $self->{"temphash"}->{$key}) {
    print STDERR "Recovering changed value for key $key\n"
      if $TransactHash::verbose;
    return $self->{"temphash"}->{$key};
  }
  if (defined $self->{"deleted"}->{$key}) {
    print STDERR "Value for $key has been deleted\n"
      if $TransactHash::verbose;
    return undef;
  }
  print STDERR "Recovering value for $key from hidden hash" . 
    $self->{"hidehash"} . "\n"
      if $TransactHash::verbose;
  $value=$self->{"hidehash"}->{$key};
  print STDERR "returning" . $value . "\n"
      if $TransactHash::verbose;
  return $value;
}

sub STORE {
  my $self=shift;
  my $key=shift;
  my $value=shift;
  #if we have it marked as deleted then 
  if (defined $self->{"deleted"}->{$key}) {
    print STDERR "Value for $key no longer deleted\n"
      if $TransactHash::verbose;
    delete $self->{"deleted"}->{$key};
  }
  print STDERR "$key having value $value stored\n"
    if $TransactHash::verbose;
  $self->{"temphash"}->{$key} = $value;
}

sub DELETE {
  my $self=shift;
  my $key=shift;
  print STDERR "Doing delete of key $key\n"
    if $TransactHash::verbose;
  #if it exists in our temphash get rid of it
  delete $self->{"temphash"}->{$key};
  #if it exists in the database mark it into deletes
  if ( defined $self->{"hidehash"}->{$key} ) {
    print STDERR "Marking key deleted from database\n"
      if $TransactHash::verbose;
    $self->{"deleted"}->{$key} = 1;
  }
}

sub EXISTS {
  my $self=shift;
  my $key=shift;
  if (defined $self->{"deleted"}->{$key}) {
    return 0; #it has been deleted
  }
  if (defined $self->{"temphash"}->{$key}) {
    return 1; #it has been changed, but exists
  }
  if (defined $self->{"hidehash"}->{$key}) {
    return 1; #it exists as was
  }
  return 0; #never heard of it
}

=head2 Iterator functions (FIRSTKEY & NEXTKEY)

The iterators first iterate over the hidden hash as normal (giving out changed
values) then iterate over the storehash skipping values in the original hash.

=cut

sub FIRSTKEY {
  my $self=shift;
  $self->{"iteratehidden"} = 1;
  #FIXME checking for an empty hash..
  #don't use this cos then perl doesn't notice the start of the iteration
  print STDERR "Using hash hack to get first hidden value\n"
      if $TransactHash::verbose;
  my $count = scalar keys %{$self->{"hidehash"}}; 
  if ( $count ) { #there are elements in the hash we are editing.
      my ($key,$value);
      ($key,$value) = each %{$self->{"hidehash"}} ;
      while (defined $key && defined $self->{"deleted"}->{$key}) {
	  ($key,$value) = each %{$self->{"hidehash"}} 
      }
      return $key if defined $key;
  }      

  #none of the elements in the original hash remain, or there weren't
  #any to start with.

  $self->{"iteratehidden"}=0; 
  #reset the iteration across the temphash
  my $a = scalar keys %{$self->{"temphash"}}; 
  return each %{$self->{"temphash"}};
  #which will be undef if there is nothing at all..
}

sub NEXTKEY {
  my $self=shift;
  my $lastkey=shift;
  print STDERR "TransactHash nextkey called last key was $lastkey\n"
    if $TransactHash::verbose;
  #you could optimise by just using the NEXTKEY from the object when
  #available 
  if ($self->{"iteratehidden"}) {
    print STDERR "Getting values from underlying hash\n"
      if $TransactHash::verbose;
    my ($key, $value) = each %{$self->{"hidehash"}} ;
    #skip over the ones we've deleted
    while (defined $key && defined $self->{"deleted"}->{$key}) {
      print STDERR "$key is deleted, skipping over it\n"
	if $TransactHash::verbose;
      my ($key, $value) = each %{$self->{"hidehash"}} ;
    }
    if (defined $key && defined $self->{"temphash"}->{$key}) {
      print STDERR "$key is changed, returning new value\n"
	if $TransactHash::verbose;
      $value=$self->{"temphash"}->{$key};
    }
    if (defined $key) {
      print STDERR "Returning key $key and value $value from main sequence\n"
	if $TransactHash::verbose;
      return $key; #, $value;
    }
    print STDERR "Reached last hidden value, changing to iterating new values\n"
      if $TransactHash::verbose;
    $self->{"iteratehidden"}=0; 
    #reset the iteration across the temphash
    my $a = scalar keys %{$self->{"temphash"}}; 
  }
  #we have completed the sequence of original values and are now
  #iterating to find added values..

  my ($key, $value) = each %{$self->{"temphash"}} ;
  #skip over the ones from the main sequence
  while (defined $key && defined $self->{"hidehash"}->{$key}) {
    print STDERR "$key is only changed.  Skipping\n"
      if $TransactHash::verbose;
    ($key, $value) = each %{$self->{"temphash"}} ;
  }
  $self->{"iteratehidden"}=1 unless defined $key;
  return $key; #, $value;
}

=head2 commit() and reset()

These functions are not normally visible in the hash interface, but can be
used as object methods.  commit() updates the original hidden hash (which
changes its order) and reset() loses all of the changes that we have made.

In the hash interface commit is called as the variable is destroyed.  This
should happen at exit time, but didn't seem to to me.  Assigning undef to the
variable you stored the object in and untie()ing the hash will force it to
happen.

=cut

sub commit {
  my $self=shift;
  print STDERR "commit called on TransactHash ($self)\n"
    if $TransactHash::verbose;
  #FIXME should really validate that there is not a delete.. just to
  #be sure
  my ($key, $value);
  print STDERR "using temp database (" . $self->{"temphash"} . ")\n"
    if $TransactHash::verbose;

  my $junka = scalar keys %{$self->{"temphash"}}; 

  print STDERR "about to gen list\n"
    if $TransactHash::verbose;
  if ($TransactHash::verbose) {
    print STDERR "list of values to commit\n";
    while (($key,$value) = each %{$self->{"temphash"}}) {
      print STDERR "$key has value $value\n"
	if $TransactHash::verbose;
    }
  }
  print STDERR "about to do changes\n"
      if $TransactHash::verbose;
  while (($key,$value) = each %{$self->{"temphash"}}) {
    print STDERR "writing $key with $value to hidden hash\n"
      if $TransactHash::verbose;
    my $hashref = $self->{"hidehash"};
    $hashref->{$key} = $value;
    print STDERR "hidehash stores " . $hashref->{$key} ."\n"
	if $::TransactHash::verbose;
  }
  my $junkb = scalar keys %{$self->{"deleted"}}; 
  print STDERR "about to do deletes\n"
      if $TransactHash::verbose;
  while (($key,$value) = each %{$self->{"deleted"}}) {
    print STDERR "deleting $key from hidden hash\n"
      if $TransactHash::verbose;
    delete $self->{"hidehash"}->{$key};
  }

  #FIXME file syncronisation; warn if we can't and it's a file that
  # we're writing to .. we have to eval this because it might be a
  # normal simple perl hash that we are editing

  eval { $self->{"hideobj"}->sync() };

  #FIXME we store the old values for verification.. if we don't want
  # this then it would be worth throwing them away to avoid waste of
  # memory..

  $self->{"oldstore"}=$self->{"tempstore"};
  $self->{"oldhash"}=$self->{"temphash"};
  $self->{"olddeleted"}=$self->{"deleted"};

  #now create a place to store our changes for the next transaction.  
  my $tempstore = tie my(%temphash), "Tie::IxHash";
  $self->{"tempstore"} = $tempstore;
  $self->{"temphash"} = \%temphash;
  $self->{"deleted"} = {};
}

=head2 $transhash->autostore()

This method stores a true or false value in the object telling it
whether it should automatically commit if it is destroyed.  If this is
set to false, then the object method $transhash->commit() must be
called to store any changes, otherwise they will be lost.

If this is set to true, then be aware that exiting your program from
some kind of error condition of your program (that is, not one perl
knows about) would commit the changes.

=cut

sub autostore {
    my $self=shift;
    return $self->{"autostore"} unless defined @_;
    $self->{"autostore"} = shift;
}



=head2 $transhash->verify_write()

This function checks that a write has committed to the hash correctly.
It does this by checking that all of the values in the old temporary
stores match those in the new ones.

This function is untested since I don't have a sensible test case for
it yet and don't need it myself.  should work though.

=cut

sub verify_write {
    my $self=shift;
    my $hidehash=$self->{"hidehash"};
    my $key;
    my $value;
    my $pass=1;
    croak "Commit doesn't seem to have been called yet"
	unless defined $self->{"oldhash"};
  CHANGE: while(($key, $value)=each %{$self->{"oldhash"}}) {
      unless(defined $hidehash->{$key} ) {
	  warn "Key $key gives undefined; should be $value";
	  next CHANGE;
	  my $pass=0;
      }
      unless($value=$hidehash->{$key}) {
	  warn "Key $key has value $value, should be " . $hidehash->{$key};
	  my $pass=0;
      }

  }
  DELETE: while(($key, $value)=each %{$self->{"olddeleted"}}) {
      if(defined $hidehash->{$key}) {
	  warn "Key $key gives $value; should be undefined";
	  my $pass=0;
      }
  }
    return $pass;
}

sub reset {
  my $self=shift;
  $self->{"temphash"} = {};
  $self->{"deleted"} = {};
  #FIXME reset the sequence?
}

sub rollback {reset @_}

=head2 COPYING

 Copyright (c) 1997 Michael De La Rue

This is free software and may be distributed under the same terms as perl.
There is no warantee.  See the file COPYING which should have been included
with the distribution for one set of terms under which it may be distributed.
The artistic license, distributed with perl gives the other one.

=cut

1; #he said and rested.
