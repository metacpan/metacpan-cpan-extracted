##############################################################################
##
##  Web::Reactor application machinery
##  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade"
##        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
##  http://cade.noxrun.com
##  
##  LICENSE: GPLv2
##  https://github.com/cade-vs/perl-web-reactor
##
##############################################################################
package Web::Reactor::Sessions;
use strict;
use Exception::Sink;
use Data::Tools 1.24;

use parent 'Web::Reactor::Base'; 

##############################################################################
##
##  public interface methods, should be used via Reactor object, see specs
##

# create new session id of given type and length and allocate storage for it
# args:
#       type -- alphanumeric type name (selects storage only)
#       len  -- session id length
# returns:
#       new session id or undef when failed
sub create
{
  my $self = shift;
  my $type = uc shift;
  my $len  = shift || 97;

  die "Web::Reactor::Sessions::create: invalid type, expected ALPHANUMERIC, got [$type]" unless $type =~ /^[A-Z0-9]+$/;
  die "Web::Reactor::Sessions::create: invalid length, expected len > 0, got [$len]" unless $len > 0;

  my $cfg  = $self->get_cfg();

  my $id;
  my $t  = time();
  my $to = $cfg->{ 'SESS_CREATE_TIMEOUT' } || 5; # seconds
  while(4)
    {
    $id = $self->create_id( $len );

    my @key = $self->compose_key_from_id( $type, $id );
    last if $self->_storage_create( @key );

    if ( time() - $t > $to )
      {
      $id = undef;
      # FIXME: report error
      die "Web::Reactor::Sessions::create: cannot create new session: timeout, key[@key]";
      return undef;
      }
    }
 
  return $id;
};

# loads session data from the storage
# args:
#       type -- alphanumeric type name (selects storage only)
#       id   -- session id
# returns:
#       hashref of session data or undef if error
sub load
{
  my $self = shift;
  my $type = shift;
  my $id   = shift;

  return 0 unless $id;

  my @key = $self->compose_key_from_id( $type, $id );

  return $self->_storage_load( @key );
}

# saves session data to the storage
# args:
#       type -- alphanumeric type name (selects storage only)
#       id   -- session id
#       data -- hashref of session data
# returns:
#       1 if successful, undef if failed
sub save
{
  my $self = shift;
  my $type = shift;
  my $id   = shift;
  my $data = shift;

  return 0 unless $id;

  my @key = $self->compose_key_from_id( $type, $id );

  return $self->_storage_save( $data, @key );
}

# deletes a session from the storage
# args:
#       type -- alphanumeric type name (selects storage only)
#       id   -- session id
# returns:
#       1 if successful, undef if failed
sub delete
{
  my $self = shift;
  my $type = shift;
  my $id   = shift;

  return 0 unless $id;

  my @key = $self->compose_key_from_id( $type, $id );

  return $self->_storage_delete( @key );
}

# checks if session exists in the storage
# args:
#       type -- alphanumeric type name (selects storage only)
#       id   -- session id
# returns:
#       1 if exists, undef if not
sub exists
{
  my $self = shift;
  my $type = shift;
  my $id   = shift;

  return 0 unless $id;

  my @key = $self->compose_key_from_id( $type, $id );

  return $self->_storage_exists( @key );
}


##############################################################################
##
##  methods, which must be implemented in sub-classes!
##  they are all internal to this package
##

# create new session storage indexed by the given key components
# it is important that this function try to do atomic create in the storage.
# it must (and expected to) fail if session with the same key exists and never
# overwrite existing session storage!
# args:
#       @key (i.e. @_) -- key components array, usually filled with 2 or 3 elements
#                         when 2: TYPE, SESS7c87y32d78asa4
#                         when 3: TYPE, SESS187yc5v87thccf, SESS2jdhfh74yc3847
#                         usually it is simple to $key = join '.' @_;
#
# returns:
#       1 if successful or 0 or undef if not possible or session id already exists
sub _storage_create { die "Web::Reactor::Sessions::*::_storage_create() is not implemented!"; }

# loads session data from the storage
# args:
#       @key (i.e. @_) -- key components array, example: $key = join '.' @_;
# returns:
#       hashref of session data or undef if error
sub _storage_load   { die "Web::Reactor::Sessions::*::_storage_load() is not implemented!"; }

# saves session data to the storage
# args:
#       data -- hashref of session data
#       @key (i.e. @_) -- key components array, example: $key = join '.' @_;
# returns:
#       1 if successful, undef if failed
sub _storage_save   { die "Web::Reactor::Sessions::*::_storage_save() is not implemented!"; }

# checks if session exists in the storage
# args:
#       @key (i.e. @_) -- key components array, example: $key = join '.' @_;
# returns:
#       1 if exists, undef if not
sub _storage_exists { die "Web::Reactor::Sessions::*::_storage_exists() is not implemented!"; }

##############################################################################
##
##
##

# return string with new session id with given LEN argument or default length
# args:
#       len  --  session id length (optional, 0 or undef for default length)
#       letters -- letters to be used for session id creation (optional)
#                  must be non-whitespace characters string with no duplicates
# returns:
#       id -- session id string
sub create_id
{
  my $self = shift;
  my $cfg  = $self->get_cfg();
 
  my $len = shift() || $cfg->{ 'SESS_LENGTH'  } || 128;
  my $let = shift() || $cfg->{ 'SESS_LETTERS' } || 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  return create_random_id( $len, $let );
};

sub compose_key_from_id
{
  my $self = shift;
  my $type = uc shift;
  my $id   = shift;

  boom "Web::Reactor::Sessions::compose_key_from_id: invalid type, expected ALPHANUMERIC" unless $type =~ /^[A-Z0-9]+$/;
 
  my @key;
 
  push @key, $type;
  push @key, $self->get_user_sid() if $type ne 'USER'; # FIXME: not only! UPDs also! (user permanent data)
  push @key, $id;
 
  return @key;
}

##############################################################################
##
##  helpers
##

sub get_user_sid
{
  my $self = shift;
  my $user_sid = $self->{ 'REO_REACTOR' }->{ 'SESSIONS' }{ 'SID'  }{ 'USER' };

  boom "missing USER SESSION" unless $user_sid;

  return $user_sid;
}

#sub DESTROY
#{
#  my $self = shift;
#
#  print "DESTROY: $self\n";
#}

##############################################################################
1;
###EOF########################################################################
