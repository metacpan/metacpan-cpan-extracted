#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Classification;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get classification' => sub {
    my $classification = $bz->classification->get(1);
    isa_ok($classification, 'WebService::Bugzilla::Classification', 'returned Classification object');
    is($classification->id, 1, 'classification id');
    is($classification->name, 'MyClassification', 'classification name');
    is($classification->description, 'A test classification', 'classification description');
    is($classification->sort_key, 0, 'classification sort_key');
    is($classification->products->[0]{name}, 'TestProduct', 'first product name');
};

done_testing();
