##
#
#    Copyright 2005, AllAfrica Global Media
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
#    http://xml-comma.org/, or read the tutorial included with the
#    XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::SQL::DBH_User;
@ISA = qw( XML::Comma::SQL::Base );

use strict;
use XML::Comma;
use XML::Comma::Util qw( dbg );
use XML::Comma::SQL::Base;
use Class::ClassDecorator;

# inherit from our sql syntax class
# my $sql_class;
# BEGIN {
#   my $which_db = XML::Comma->system_db();
#   my $db_struct = XML::Comma->$which_db();
#   $sql_class = "XML::Comma::SQL::" . $db_struct->{ sql_syntax };
#   dbg 'using syntax', $sql_class;
# }

#use base $sql_class;

###
#
# DBH_User: Mixin class for routines that need access to the Comma
# database connection. (Index, Lock, etc.)
#
# This class provides ping(), get_dbh() and disconnect() methods.
#
# NOTE: It is a good idea to call disconnect() from an inheriting
# class's DESTROY -- you have to do that by hand.
###

# _DBH_which_db_reader
# _DBH_which_db_writer : hold the 'names' of the Comma config variable
#                        that specifies how to connect and talk to the
#                        db. if there isn't a value set for this, it
#                        defaults to 'system_db'
#
# _DBH       : handle reference
# _DBH_pid   : pid of process on last connect -- used to re-init
#                    connections after a fork
#
# DBH_connect_check : inheritors can set this to the name of a method
#                       to call on _connect. this is useful for making
#                       sure db schemas are still what we think they
#                       are, et.

##
# this may need to be modified as we begin to separate writer and
##reader functionalities, and when we settle on a syntax handling
##different databases.
sub decorate_and_bless {
  my ( $self, $class, %args ) = @_;
  my $sql_definition = XML::Comma->system_db();
  my $sql_class = 'XML::Comma::SQL::' .
    XML::Comma->$sql_definition->{ sql_syntax };
  eval "require $sql_class";
  my $composite_class = Class::ClassDecorator::decorate ( $class, $sql_class );
  bless ( $self, $composite_class );
}

sub ping_writer {}
sub ping_reader {}

sub ping {
  my $self = shift();
  # dbg 'ping from dbh_user';
  # if not pingable, do a connect
  unless ( $self->get_dbh()->ping() ) {
    $self->_connect();
  }
  return 1;
}

sub get_dbh_writer {
  my $self = shift;
  $self->ping()  and  return $self->get_dbh();
}

sub get_dbh_reader {
  my $self = shift;
  $self->ping()  and  return $self->get_dbh();
}

sub get_dbh {
  if ( $_[0]->{_DBH} and $_[0]->{_DBH_pid} == $$ ) {
    return $_[0]->{_DBH};
  } else {
    # dbg 'connecting', $$, $_[0]->{_DBH}||'', $_[0]->{_DBH_pid}||'';
    return $_[0]->_connect();
  }
}

# BOTH
sub disconnect {
  my $self = shift;
  if  ( $self->{_DBH} ) {
    undef $self->{_DBH}; # let DBI's DESTROY do all the work
  }
}

# throws a public error -- functional routines elsewhere are, in
# general, not expected to worry about connectivity, so they couldn't
# recover from problems, anyway.
sub _connect {
  my $self = shift();
  # try to deal nicely with a currently-connected handle (which we may
  # have inherited from a fork, etc.  This eval is on the raw database 
  # handle, not our housekeeping disconnect.  We want the database error
  # to avoid the sleep, if we aren't connected.
  eval { $self->{_DBH}->disconnect(); sleep 1; };
  my $db_struct = $self->db_struct();
  my @connect_array = @{ $db_struct->{dbi_connect_info} };

  # try to connect -- looping to try again if we fail
  my $max_attempts = 30;
  for my $attempt ( 1 .. $max_attempts ) {
    eval { $self->{_DBH} = DBI->connect( @connect_array ); };
    last  unless  $@;
    if ( $attempt < $max_attempts ) {
      XML::Comma::Log->warn ( 'Couldn\'t connect to database ' .
                              "(attempt $attempt) -- $@" );
      sleep 2;
    } else {
      XML::Comma::Log->err ( 'DB_CONNECTION_ERROR', "$@" );
    }
  }

  #DBI->trace( 3, "trace.out" );

  $self->{_DBH_pid} = $$;
  #dbg 'setting pid to', $self->{_DBH_pid};
  my $check_method = $self->{DBH_connect_check};
  $self->$check_method()  if  $check_method;
  return $self->{_DBH};
}


# callable as a class or instance method: if called as a class method,
# always returns the 'system_db' struct (or throws an error). if
# called as an instance method, checks _DBH_which_db to figure out
# which struct to return -- defaults to 'system_db'
sub db_struct {
  my $self = shift();
  my $which_db;
  if ( ref($self) && $self->isa('XML::Comma::SQL::DBH_User') ) {
    $which_db = $self->{_DBH_which_db} || 'system_db';
  } else {
    $which_db = 'system_db';
  }
  my $struct_name = XML::Comma->$which_db() ||
    XML::Comma::Log->err ( 'DB_CONFIG_ERROR', 
                           "could not find database info for '$which_db'" );
  return XML::Comma->$struct_name() ||
    XML::Comma::Log->err ( 'DB_CONFIG_ERROR',
                           "could not find database info for '$struct_name'" );
}

1;
