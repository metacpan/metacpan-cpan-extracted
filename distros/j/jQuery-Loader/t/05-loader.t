use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use jQuery::Loader;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

my $loader = jQuery::Loader->new_from_internet(cache => $base);
ok($loader);
SKIP: {
    $ENV{TEST_RELEASE} or skip "Not testing going out to the Internet";
    is($loader->file, file "jquery-1.2.6.js");
}
$loader->filter_min;
SKIP: {
    $ENV{TEST_RELEASE} or skip "Not testing going out to the Internet";
    $loader->filter_min;
    is($loader->file, file "jquery-1.2.6.min.js");
}

ok(jQuery::Loader->new_from_internet);
ok(jQuery::Loader->new_from_uri(uri => "http://localhost/\%l"));
ok(jQuery::Loader->new_from_file(file => "./"));
