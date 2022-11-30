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
##  Adapted from Web::Reactor::Actions::Decor
##  Decor application machinery core
##  Copyright (c) 2014-2022 Vladi Belperchinov-Shabanski "Cade"
##        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
##  http://cade.noxrun.com
##
##  LICENSE: GPLv2
##  https://github.com/cade-vs/perl-decor
##
##############################################################################
package Web::Reactor::Actions::Alt;
use strict;
use Exception::Sink;
use Web::Reactor::Actions;
use Data::Dumper;

use parent 'Web::Reactor::Actions';

# calls an action (function) by name
# args:
#       name   -- function/action name
#       %args  -- array used as named hash arguments
# args hash keys:
#       ARGS   -- hash reference of attributes/arguments passed to the action
# returns:
#       result text to be replaced in output
sub call
{
  my $self  = shift;

  my $name = lc shift;
  my %args = @_;

  my $reo = $self->get_reo();
  
  if( $name !~ /^[a-z_\-0-9]+$/ )
    {
    $reo->log( "error: invalid action name [$name] expected ALPHANUMERIC" );
    return undef;
    }

  my $cr = $self->__load_action_file( $name );

  if( ! $cr )
    {
    $reo->log( "error: cannot load action [$name]" );
    return undef;
    }

  my $data = $cr->( $reo, %args );

  return $data;
}

sub __load_action_file
{
  my $self  = shift;

  my $name = shift;

  my $reo = $self->get_reo();
  my $cfg = $self->get_cfg();
  
  return $self->{ 'ACTIONS_CODE_CACHE' }{ $name } if exists $self->{ 'ACTIONS_CODE_CACHE' }{ $name };
  
  my $dirs = $cfg->{ 'ACTIONS_DIRS' } || [ $cfg->{ 'APP_ROOT' } . '/actions' ];
  my $pkgs = $cfg->{ 'ACTIONS_PKGS' } || 'reactor::actions::';
  
  my $found;
  for my $dir ( @$dirs )
    {
    my $file = "$dir/$name.pm"; # TODO: subdirs?
    next unless -e $file;
    $found = $file;
    last;
    }

  return undef unless $found;

  my $ap = $pkgs . $name;

  eval
    {
    delete $INC{ $found };
    require $found;
    };

  if( ! $@ )  
    {
    $reo->log_debug( "status: load action ok: $ap [$found]" );
    my $cr = $self->{ 'ACTIONS_CODE_CACHE' }{ $name } = \&{ "${ap}::main" }; # call/function reference
    return $cr;
    }
  elsif( $@ =~ /Can't locate $found/)
    {
    $reo->log( "error: action not found: $ap [$found]" );
    }
  else
    {
    $reo->log( "error: load action failed: $ap: $@ [$found]" );
    }  

  return undef;
}

##############################################################################
1;
###EOF########################################################################

