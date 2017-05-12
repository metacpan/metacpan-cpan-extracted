use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 6;

# This tests some fixes to the Context loading code that was being sloppy with
# objects with stringify overloading.  A simple boolean test on an object like
#    if ($object) {...
# would stringify the object and then test that string for truthness.  If the
# string was "" or "0", then it would be boolean false

package URT::Thing;

use overload ( '""' => \&stringify );
UR::Object::Type->define(
    class_name => 'URT::Thing',
    is => 'UR::Value',
);
sub stringify { return "" }; # always stringify to false

package main;

my $o = URT::Thing->get(1);
ok(defined($o), 'Got Thing with id 1');
is($o->id, 1, 'It has the right ID');

$o = URT::Thing->get(0);
ok(defined($o), 'Got Thing with id 0');
is($o->id, 0, 'It has the right ID');

my @o = URT::Thing->get([4,7,10,99,1]);
is(scalar(@o), 5, 'Got 5 Things by ID');
is_deeply([map { $_->id} @o],
          [1,10,4,7,99],
          'All the IDs were correct');

