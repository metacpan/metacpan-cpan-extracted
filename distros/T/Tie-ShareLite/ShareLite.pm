# Tie::ShareLite
#
# class to tie a hash to IPC::ShareLite and automatically update using Storable
#
# This module is free software; you may redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME
                                                                                                    
Tie::ShareLite - Tied hash interface to IPC::ShareLite
                                                                                                    
=head1 SYNOPSIS
                                                                                                    
  use Tie::ShareLite qw( :lock );

  $ipc = tie %shared, 'Tie::ShareLite', -key     => 1971,
                                        -mode    => 0600,
                                        -create  => 'yes',
                                        -destroy => 'no'
    or die("Could not tie to shared memory: $!");

  $shared{'myKey'} = "This is stored in shared memory");

  $ipc->lock( LOCK_EX );
  $shared{'var1'} = 'some value';
  $shared{'var2'} = 'some other value';
  $ipc->unlock();
                                                                                                    
=head1 DESCRIPTION

Tie::ShareLite provides for a tied hash interface to the IPC::ShareLite module
that is very similar to the one provided by IPC::Shareable.  Only hashes can be
tied at this time.  The hashes can be of any complexity allowed by the Storable
module, however, there are some caveats covered below in the REFERENCES section.

To tie a hash to shared memory, use the tie command:

  $ipc = tie %shared, 'Tie::ShareLite', -key     => 1971,
                                        -mode    => 0600,
                                        -create  => 'yes',
                                        -destroy => 'no'
    or die("Could not tie to shared memory: $!");
  
Any parameters you pass (such as -key, -mode, -create, etc) are passed straight
through to IPC::ShareLite.  After this call, the contents of the hash %shared
are now in shared memory, and the $ipc variable can be used to lock the memory
segment.

To update the shared memory, simply assign something to it like you would any
other hash:
  
  $shared{'myKey'} = "This is stored in shared memory");

Each read and write to the hash is atomic.  In the background IPC::ShareLite
makes sure that each process takes their turn.

You can make several operations atomic by calling lock() and unlock():
  
  $ipc->lock( LOCK_EX );
  $shared{'var1'} = 'some value';
  $shared{'var2'} = 'some other value';
  $ipc->unlock();

I suggest locking any time you do multiple reads or writes.  If you have a
read or write operation in a loop, locking before the loop can speed things up
a lot.  This is because when a lock is in place, the module thaws the data from
shared memory once and keeps it in memory until you unlock.  The following code
illustrates how this works.  The comments show you what happens behind the
scenes.  fetch() means that the data is read from shared memory and thawed.
store() means that the data is frozen, then written to shared memory.  Both
the fetch and store operations are relatively expensive, so reducing how many
times they happen can speed up your code a lot.

  $shared{'name'}  = 'Fred';                  # fetch(), update, store()
  $shared{'title'} = 'Manager';               # fetch(), update, store()

  $ipc->lock( LOCK_EX );
  $shared{'age'}   = '45';                    # fetch(), update
  $shared{'sex'}   = 'male';                  # update
  $shared{'dept'}  = 'sales';                 # update
  $ipc->unlock();                             # store()

  print "Name:  " . $shared{'name'}  . "\n";  # fetch()
  print "Title: " . $shared{'title'} . "\n";  # fetch()

  $ipc->lock( LOCK_SH );
  print "Age:   " . $shared{'age'}   . "\n";  # fetch()
  print "Sex:   " . $shared{'sex'}   . "\n";
  print "Dept:  " . $shared{'dept'}  . "\n";
  $ipc->unlock();

Tie::ShareLite will keep tabs on locks and smartly fetch and store the data
only when needed.

=head1 METHODS

=over 4

=item lock( $mode )

Obtains a lock on the shared memory by calling IPC::ShareLite::lock().

=item unlock()

Releases a lock on the shared memory by calling IPC::ShareLite::unlock().

=item shlock( $mode )

Calls lock().  Here for drop-in compatibility with IPC::Shareable.

=item shunlock()

Calls unlock().  Here for drop-in compatibility with IPC::Shareable.

=head1 REFERENCES

Storing references in tied hashes is not very well supported by Perl.  There
are a few gotchas that are not very obvious.  When you say something like

  $shared{'key'}{'subkey'} = 'value';

Perl actually creates a real anonymous hash with nothing in it,
assigns the reference of that hash to $shared{'key'}, then finally puts the
subkey => value part into the anonymous hash.  This anonymous hash only exist
in the current process, and after the whole shared hash is serialized, that
reference is lost.  Plus the tied hash is never told about the change to the
anonymouse hash.  So in other words, it doesn't work.

IPC::Shareable "solved" this problem by tying the anonymous hash as another
shared hash.  This has the downside of using up a lot of shared memory segments
very fast.  Plus it has some weird side effects that have caused me problems
in the past.  In this module, for now I have decided to forgo any kind of
special hacks to get this to work.  So if you want to share complex hashes
then you have to copy the hash into local memory, access it as you want, then
assign it back to the shared hash.  Example:

  $ipc->lock();
  my $tmp = $shared{'key'};
  $tmp->{'subkey'} = 'value';
  $shared{'key'} = $tmp;
  $ipc->unlock();

I would suggest putting the lock there, otherwise another process could change
the contents of the 'key' between when you read it, and when you write it back
and thus your process would overwrite the others change.

Luckily, reads don't have this problem and are much simpler:

  my $value = $shared{'key'}['subkey'};

I have played around with a possible solution to this, but I have a feeling
it would add some serious overhead that would slow the whole module down.  I
would be more than happy to hear from anyone that has found a clean solution
to this.

=head1 EXPORT

Anything that IPC::ShareLite exports.

=head1 AUTHOR

Copyright 2004, Nathan Shafer E<lt>nate-tiesharelite@seekio.comE<gt>. 
All rights reserved.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself. 

=head1 CREDITS

Special thanks to Maurice Aubrey for his wonderful module, IPC::ShareLite.

=head1 SEE ALSO

L<perl>, L<IPC::ShareLite>.

=cut

package Tie::ShareLite;
use 5.006;
use strict;
use IPC::ShareLite qw(:all);
use Storable qw(freeze thaw);
use Carp;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DEBUG );

# Pass all the exports from IPC::ShareLite through.  We have none of our own.
require Exporter;
@ISA = qw(Exporter);
@EXPORT      = @IPC::ShareLite::EXPORT;
@EXPORT_OK   = @IPC::ShareLite::EXPORT_OK;
%EXPORT_TAGS = %IPC::ShareLite::EXPORT_TAGS;

$VERSION = '0.03';
$DEBUG   = 0;

sub TIEHASH {
  print STDERR "TIEHASH(@_)\n" if $DEBUG;
  my($class, @params) = @_;

  my $this = {};
  bless($this, $class);

  $this->{_lock}          = undef;
  $this->{_lock_return}   = undef;
  $this->{_internal_lock} = undef;
  $this->{_iterating}     = 0;

  $this->{share} = new IPC::ShareLite(@params)
    or croak("Could not create new IPC::ShareLite object: $!");

  return($this);
}

sub FETCH {
  print STDERR "FETCH(@_)\n" if $DEBUG;
  my($this, $key) = @_;

  $this->_get_hash();
  $this->{_iterating} = 0;
  return($this->{_hash}->{$key});
}

sub STORE {
  print STDERR "STORE(@_)\n" if $DEBUG;
  my($this, $key, $value) = @_;

  $this->_smart_lock( LOCK_EX );
  $this->_get_hash();
  $this->{_hash}->{$key} = $value;
  $this->_put_hash();
  $this->_smart_unlock();
}

sub DELETE {
  print STDERR "DELETE(@_)\n" if $DEBUG;
  my($this, $key) = @_;

  $this->_smart_lock( LOCK_EX );
  $this->_get_hash();
  delete($this->{_hash}->{$key});
  $this->_put_hash();
  $this->_smart_unlock();
}

sub CLEAR {
  print STDERR "CLEAR(@_)\n" if $DEBUG;
  my($this) = @_;

  $this->{_hash} = {};
  $this->_put_hash();
}

sub EXISTS {
  print STDERR "EXISTS(@_)\n" if $DEBUG;
  my($this, $key) = @_;

  $this->_get_hash();
  return(exists($this->{_hash}->{$key}));
}

sub FIRSTKEY {
  print STDERR "FIRSTKEY(@_)\n" if $DEBUG;
  my($this) = @_;

  $this->_get_hash();
  my $reset = keys(%{$this->{_hash}});
  my $first = each(%{$this->{_hash}});
  $this->{_iterating} = 1;
  return($first);
}

sub NEXTKEY {
  print STDERR "NEXTKEY(@_)\n" if $DEBUG;
  my($this, $lastkey) = @_;

  my $next = each(%{$this->{_hash}});
  if($next) {
    $this->{_iterating} = 1;
  }
  return($next);
}

sub DESTROY {
  print STDERR "DESTROY(@_)\n" if $DEBUG;
  my($this) = @_;

  $this->unlock();
}

sub lock {
  print STDERR "lock(@_)\n" if $DEBUG;
  my($this, $flags) = @_;

  $flags ||= LOCK_EX;

  my $return            = $this->{share}->lock($flags);
  $this->{_lock}        = $flags;
  $this->{_lock_return} = $return;

  undef($this->{_hash});

  return($return);
}

sub unlock {
  print STDERR "unlock(@_)\n" if $DEBUG;
  my($this) = @_;

  # flush any unsaved changes
  $this->_put_hash(1);

  my $return              = $this->{share}->unlock();
  $this->{_lock}          = undef;
  $this->{_lock_return}   = $return;
  $this->{_internal_lock} = 0;
  undef($this->{_hash});

  return($return);
}

sub shlock {
  print STDERR "shlock(@_)\n" if $DEBUG;
  my($this, @params) = @_;

  return($this->lock(@params));
}

sub shunlock {
  print STDERR "shunlock(@_)\n" if $DEBUG;
  my($this) = @_;

  return($this->unlock());
}

sub _get_hash {
  print STDERR "_get_hash(@_)\n" if $DEBUG;
  my($this) = @_;

  unless(defined($this->{_hash}) && ($this->{_lock} || $this->{_iterating})) {
    print STDERR "_get_hash: thawing data\n" if $DEBUG;
    my $serialized = $this->{share}->fetch();

    if($serialized) {
      $this->{_hash} = thaw($serialized);
    } else {
      $this->{_hash} = {};
    }
  }

  return();
}

sub _put_hash {
  print STDERR "_put_hash(@_)\n" if $DEBUG;
  my($this, $flush) = @_;

  if(!$flush && ($this->{_lock} == LOCK_EX ||
     ($this->{_lock} == (LOCK_EX|LOCK_NB) && $this->{_lock_return})))
  {
    print STDERR "_put_hash: setting _need_flush!\n" if $DEBUG;
    $this->{_need_flush} = 1;
  } elsif(!$flush || ($flush && $this->{_need_flush})) {
    print STDERR "_put_hash: flushing!\n" if $DEBUG;
    my $serialized = freeze($this->{_hash});
    $this->{share}->store($serialized);
    $this->{_need_flush} = 0;
  } else {
    print STDERR "_put_hash: doing nothing!\n" if $DEBUG;
  }
}

sub _smart_lock {
  print STDERR "_smart_lock(@_)\n" if $DEBUG;
  my($this, $flags) = @_;

  if($flags == LOCK_SH) {
    # we only have to check if a lock has been set successfully, we don't care
    # which
    unless($this->{_lock} && $this->{_lock_return}) {
      print STDERR "_smart_lock: setting shared lock\n" if $DEBUG;
      $this->{_internal_lock} = 1;
      return($this->lock($flags));
    }
  } elsif($flags == LOCK_EX) {
    # if the lock is LOCK_SH or LOCK_SH|LOCK_NB then we escalate it to a
    # LOCK_EX temporarily. Otherwise we just set a LOCK_EX
    if($this->{_lock} == LOCK_SH || ($this->{_lock} == (LOCK_SH|LOCK_NB) &&
        $this->{_lock_return}))
    {
      print STDERR "_smart_lock: escalating lock to exclusive\n" if $DEBUG;
      return($this->lock($flags));
    } elsif(!$this->{_lock} || !$this->{_lock_return}) {
      print STDERR "_smart_lock: setting exclusive lock\n" if $DEBUG;
      $this->{_internal_lock} = 1;
      return($this->lock($flags));
    } else {
      print STDERR "_smart_lock: lock already set\n" if $DEBUG;
    }
  }
}

sub _smart_unlock {
  print STDERR "_smart_unlock(@_)\n" if $DEBUG;
  my($this) = @_;

  # Only unlock if it was us that originally locked
  if($this->{_internal_lock}) {
    print STDERR "_smart_unlock: unlocking\n" if $DEBUG;
    $this->unlock();
  }
}

1;
