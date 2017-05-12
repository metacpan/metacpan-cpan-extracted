use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use jQuery::Loader::Location;

my $location = jQuery::Loader::Location->new(uri => URI->new("http://localhost/\%l"), file => "/www/\%l", location => "\%j");

is($location->file, "/www/jquery.js");
is($location->uri, "http://localhost/jquery.js");
is($location->uri->path, "/jquery.js");
