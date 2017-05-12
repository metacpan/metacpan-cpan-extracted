# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Parse-GlobEvents.t'

#########################

use Test::More tests => 1;

use XML::Parser::GlobEvents;
ok(1); # If we made it this far, we're ok.

