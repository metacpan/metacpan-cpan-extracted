#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warnings 'warning';

use XML::NewsML_G2::News_Item_Text;

use lib 't';
use NewsML_G2_Test_Helpers;

my $ni =
    XML::NewsML_G2::News_Item_Text->new( %NewsML_G2_Test_Helpers::ni_std_opts,
    title => 'blah' );

sub _test_deprecated_attribute_now_arrayref {
    my ($name) = @_;

    like(
        warning { $ni->$name("something") },
        qr/$name is deprecated/,
        "using $name as setter emits warning"
    );

    my $sa;
    like(
        warning { $sa = $ni->$name->residref },
        qr/$name is deprecated/,
        "using $name as getter emits warning"
    );

    is( $sa, "something", "$name still works" );

}

subtest 'see_also is deprecated' => sub {
    _test_deprecated_attribute_now_arrayref('see_also');
};

subtest 'derived_from is deprecated' => sub {
    _test_deprecated_attribute_now_arrayref('derived_from');
};

done_testing;
