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
package Web::Reactor::Preprocessor;
use strict;

use parent 'Web::Reactor::Base'; 
 
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
