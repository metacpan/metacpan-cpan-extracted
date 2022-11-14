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
package Web::Reactor::Actions;
use strict;

use parent 'Web::Reactor::Base'; 

sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;

  my $self = $class->SUPER::new( @_ );
  $self->{ 'ACT_PKG_CACHE' } = {};

  return $self;
}

# calls an action (function) by name
# args:
#       name   -- function/action name
#       %args  -- array used as named hash arguments
# args hash keys:
#       ARGS   -- hash reference of attributes/arguments passed to the action
# returns:
#       result text to be replaced in output
sub call { die "Web::Reactor::Acts::*::call() is not implemented!"; }

#sub DESTROY
#{
# my $self = shift;
#
# print "DESTROY: Reactor: $self\n";
#}

##############################################################################
1;
###EOF########################################################################
