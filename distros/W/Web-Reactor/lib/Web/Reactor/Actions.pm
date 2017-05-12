##############################################################################
##
##  Web::Reactor application machinery
##  2013-2016 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
package Web::Reactor::Actions;
use strict;

use parent 'Web::Reactor::Base'; 

sub new
{
  my $class = shift;
  my %env = @_;
  
  $class = ref( $class ) || $class;
  my $self = {
             'ENV'           => \%env,
             'ACT_PKG_CACHE' => {},
             };
  bless $self, $class;
  # rcd_log( "debug: $self created" );
  
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
