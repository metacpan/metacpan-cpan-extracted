##############################################################################
##
##  Web::Reactor application machinery
##  2013-2016 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
package Web::Reactor::Preprocessor;
use strict;

use parent 'Web::Reactor::Base'; 
 
sub new
{
  my $class = shift;
  my %env = @_;
  
  $class = ref( $class ) || $class;
  my $self = {
             'ENV'       => \%env,
             };
  bless $self, $class;
  # rcd_log( "debug: rcd_rec:$self created" );
  
  return $self;
}

sub load_file
{
  my $self = shift;

}

# constructs real filesystem/storage file name and load the page_text
# args:
#       $page_name  -- page name, it should be sanitized and load from file,
#                      storage, or sth.
#
# returns:
#       page text
sub load_file { die "Web::Reactor::Preprocessor::*::load_file() is not implemented!"; }

# preprocesses page text to include sub-pages or execute actions inside
# args:
#       $page_text  -- page text, already load with load_file()
#
# returns:
#       preprocessed page text
sub process { die "Web::Reactor::Preprocessor::*::process() is not implemented!"; }

#sub DESTROY
#{
#  my $self = shift;
#
#  print "DESTROY: $self\n";
#}

##############################################################################
1;
###EOF########################################################################
