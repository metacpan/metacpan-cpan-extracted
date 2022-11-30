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
##
## base class for all reactor's pawns
##
##############################################################################
package Web::Reactor::Base;
use strict;
use Scalar::Util;
use Hash::Util qw( lock_ref_keys );
use Exception::Sink;

sub new
{
  my $class = shift;
  my $reo   = shift;
  my $cfg   = shift;
 
  $class = ref( $class ) || $class;
  my $self = {};
  bless $self, $class;

  $self->{ 'CFG' } = $cfg;
  $self->__set_reo( $reo );
 
  return $self;
}

sub __lock_self_keys
{
  my $self = shift;

  for my $key ( @_ )
    {
    next if exists $self->{ $key };
    $self->{ $key } = undef;
    }
  lock_ref_keys( $self );  
}

sub __set_reo
{
  my $self = shift;

  my $reo = shift;

  # note: well, should be only reactor subclasses, not pawns but...
  if( ref( $reo ) =~ /^Web::Reactor(::|$)/ )
    {
    $self->{ 'REO_REACTOR' } = $reo;

    # weaken backlinks to reactor, needed for proper destruction
    Scalar::Util::weaken( $self->{ 'REO_REACTOR' } );
    }
  else
    {
    boom "missing REO reactor object";
    }
  
  return 1;  
}

sub get_reo
{
  my $self = shift;

  return $self->{ 'REO_REACTOR' } or boom "missing REO object reference";
}

sub get_cfg
{
  my $self = shift;

  return $self->{ 'CFG' }
}

#sub DESTROY
#{
#  my $self = shift;
#
#  print "DESTROY: Reactor: $self\n";
#}

### EOF ######################################################################
1;
