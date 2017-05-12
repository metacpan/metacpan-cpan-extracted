##
#
#    Copyright 2001-2005, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::SQL::Lock;

@ISA = qw( XML::Comma::SQL::DBH_User );

use strict;
use XML::Comma;
use XML::Comma::Util qw( dbg );
use XML::Comma::SQL::DBH_User;

my $PROC_EXISTS_EXISTS; 
eval {
  require Proc::Exists;
  $PROC_EXISTS_EXISTS = 1;
};

my $LOCK_LOOP_WAIT_SECONDS = 0.5;

sub new {
  my $base_class = shift();
  my $self = {};
  XML::Comma::SQL::DBH_User::decorate_and_bless ( $self, $base_class );
  my $dbh = $self->get_dbh();
  # check for hold table -- setup if necessary
  eval { $self->sql_get_hold('_startup_test_hold_');
         $self->sql_release_hold('_startup_test_hold_'); };
  if ( $@ ) {
    # dbg 'hold error', $@;
    # release hold to "commit" the aborted transaction
    $self->sql_create_hold_table($dbh);
    $self->sql_release_hold('_startup_test_hold_');
  }
  # check for lock table -- setup if necessary
  eval { $self->sql_get_lock_record('++') };
  if ( $@ ) {
    $self->sql_get_hold('_startup_create_lock_');
    # check again
    eval { $self->sql_get_lock_record('++') };
    if ( $@ ) {
      $self->sql_create_lock_table();
    }
    $self->sql_release_hold('_startup_create_lock_');
  }
  return $self;
}

# $self, $key, $no_block
sub lock {
  my ( $self, $key, $no_block, $timeout ) = @_;
  # dbg 'locking', $key;
  my $dbh = $self->get_dbh();
  my $locked = $self->sql_doc_lock ( $key );
  if ( $locked || $no_block ) {
    return $locked;
  }
  my $waited = 0;
  my $lr = $self->sql_get_lock_record ( $key );
  # recurse if the doc was unlocked out from under this routine
  unless ( $lr ) {
    $self->lock ( $key, $no_block, $timeout );
  }
  # okay, now our real try-again-to-lock loop
  while ( ! defined $timeout or $waited < $timeout ) {
    # check to see if we're allowed to treat this lock as expired
    $self->maybe_unlock ( $lr->{pid}, $key );
    # try to lock again
    if ( $self->sql_doc_lock($key) ) { return 1; }
    # sleep and keep going round and round
    sleep $LOCK_LOOP_WAIT_SECONDS;
    $waited += $LOCK_LOOP_WAIT_SECONDS;
  }
  XML::Comma::Log->err ( 'LOCK_TIMEOUT', "timed out waiting for lock on $key" );
}

# $self, $key
sub unlock {
  # dbg 'unlocking', $_[1];
  $_[0]->sql_doc_unlock ( $_[1] );
}

sub maybe_unlock {
  my ( $self, $pid, $key ) = @_;
  return  unless  $PROC_EXISTS_EXISTS;
  my $lr = $self->sql_get_lock_record($key);
  return unless $lr;
  if ( $lr->{info} eq Sys::Hostname::hostname() ) {
    return if Proc::Exists::pexists($pid); 
    $self->unlock ( $key );
  }
}


####
##
## DEPRECATED -- the string-based hold methods don't really work as
## intended, given some futziness with the mysql implementation.
##
##

# generic, string-based "hold". this can be used to implement a
# temporary lock without using the special doc lock table.
sub wait_for_hold {
  $_[0]->sql_get_hold ( $_[1] );
}

sub release_hold {
  $_[0]->sql_release_hold ( $_[1] );
}

sub release_all_my_locks {
  $_[0]->sql_delete_locks_held_by_this_pid ();
}

##
##
####


# FIX: make destroy unlock all locks held by this pid?
sub DESTROY {
  # print 'D: ' . $_[0] . "\n";
  $_[0]->disconnect();
}







