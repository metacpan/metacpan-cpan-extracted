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
package Web::Reactor::Actions::Native;
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

  die "invalid action name, expected ALPHANUMERIC, got [$name]" unless $name =~ /^[a-z_\-0-9]+$/;

  my $ap = $self->__find_act_pkg( $name );

#  print STDERR Dumper( $name, $ap, \%args );

  if( ! $ap )
    {
    boom "action package for action name [$name] not found";
    return undef;
    }

  # FIXME: move to global error/log reporting
  print STDERR "reactor::actions::call [$name] action package found [$ap]\n";

  my $cr = \&{ "${ap}::main" }; # call/function reference

  my $data;

  $data = $cr->( $self->get_reo(), %args );

  # print STDERR "reactor::actions::call result: $data\n";

  return $data;
}

sub __find_act_pkg
{
  my $self  = shift;

  my $name = lc shift;
  
  my $act_cache = $self->{ 'ACT_PKG_CACHE' };
  
  return $act_cache->{ $name } if exists $act_cache->{ $name };

  my $cfg = $self->get_cfg();

  my $app_name = lc $cfg->{ 'APP_NAME' };
  my $dirs     =    $cfg->{ 'LIB_DIRS' } || [];
  if( @$dirs == 0 )
    {
    my $app_root = $cfg->{ 'APP_ROOT' };
    boom "missing APP_ROOT" unless -d $app_root; # FIXME: function? get_app_root()
    $dirs = [ "$app_root/lib" ]; # FIXME: 'act' actions ?
    }

  # actions sets list
  my @asl = @{ $cfg->{ 'ACTIONS_SETS' } || [] };
  @asl = ( $app_name, "Base", "Core" ) unless @asl > 0;

  # action package
  for my $asl ( @asl )
  {
    my $ap = 'Web::Reactor::Actions::' . $asl . '::' . $name;

    # print STDERR "testing action: $ap\n";
    my $fn = $ap;
    $fn =~ s/::/\//g;
    $fn .= '.pm';
    eval
      {
      require $fn;
      };
    if( ! $@ )  
      {
      print STDERR "LOADED! action: $ap: $fn [@INC]\n";
      $act_cache->{ $name } = $ap;
      return $ap;
      }
    elsif( $@ =~ /Can't locate $fn/)
      {
      print STDERR "NOT FOUND: action: $ap: $fn\n";
      }
    else
      {
      print STDERR "ERROR LOADING: action: $ap: $@\n";
      }  
  }

  return undef;
}

##############################################################################
1;
###EOF########################################################################

