#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 11;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};

{
    my $wrap = Wrap::Sub->new;

    my $foo = $wrap->wrap('One::foo');
    my $bar = $wrap->wrap('One::bar');
    my $baz = $wrap->wrap('One::baz');

    my @objects = $wrap->wrapped_objects;

    is (@objects, 3, 'returns correct number of objects');

    $foo->unwrap;

    is ($foo->is_wrapped, 0, "unwrapped sub");

    is ($wrap->wrapped_objects, 3, "after an unwrap, return is still correct");

    $foo->rewrap;

    for my $obj (@objects){
        is ($obj->is_wrapped, 1, "objects can call state");
        like ($obj->name, qr/(?:One::foo|One::bar|One::baz)/, "name is correct on all objects");
    }
}
