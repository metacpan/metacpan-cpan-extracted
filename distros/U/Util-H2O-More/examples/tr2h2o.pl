#/usr/bin/env perl

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};
use Util::H2O::More qw/h2o tr4h2o ddd/;

my $hash = { "foo bar" => 123, "quz-ba%z" => 456 };
my $obj  = h2o tr4h2o $hash;
print $obj->foo_bar, $obj->quz_ba_z, "\n";    # prints "123456

ddd $obj;
ddd $obj->__og_keys;
