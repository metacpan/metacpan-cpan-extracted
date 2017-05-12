use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 8;

my $animal = UR::Object::Type->define(
    class_name => 'Animal',
);
ok($animal, 'defined Animal');

my %subclass_loaded;
my $observer = Animal->add_observer(
    aspect => 'subclass_loaded',
    callback => sub {
        my ($classname, $aspect, $subclassname) = @_;
        $subclass_loaded{$subclassname}++;
    },
);
ok($observer, 'defined subclass_loaded observer on Animal');

my $cat = UR::Object::Type->define(
    class_name => 'Cat',
    is => 'Animal',
);
is($cat->class, 'Cat::Type', 'defined Cat');
ok($subclass_loaded{Cat}, q(Animal's subclass_loaded observer fired when Cat was defined));

$cat = UR::Object::Type->define(
    class_name => 'Tiger',
    is => 'Cat',
);
is($cat->class, 'Tiger::Type', 'defined Tiger');
ok($subclass_loaded{Tiger}, q(Animal's subclass_loaded observer fired when Tiger was defined));

my $rock = UR::Object::Type->define(
    class_name => 'Rock',
);
is($rock->class, 'Rock::Type', 'defined Rock');
ok(!$subclass_loaded{Rock}, q(Animal's subclass_loaded observer did not fire when Rock was defined));
