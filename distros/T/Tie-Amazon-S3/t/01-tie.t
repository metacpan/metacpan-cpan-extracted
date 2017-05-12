#!perl -T

use warnings;
use strict;

use Test::More;
use Tie::Amazon::S3;

unless ( $ENV{AMAZON_S3_EXPENSIVE_TESTS} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 12;
}

my $aws_access_key_id = $ENV{AWS_ACCESS_KEY_ID};
my $aws_secret_access_key = $ENV{AWS_ACCESS_KEY_SECRET};
my $aws_s3_bucket = $ENV{AWS_ACCESS_S3_BUCKET};

tie my %t, 'Tie::Amazon::S3',
    $aws_access_key_id, $aws_secret_access_key, $aws_s3_bucket;
isa_ok( tied %t, 'Tie::Amazon::S3', 'hash variable tied' );

my $data = "This is Tie::Amazon::S3 version $Tie::Amazon::S3::VERSION";

$t{testfile} = $data;
is( $t{testfile}, $data, 'hash key fetch and store' );

ok( exists $t{testfile}, 'testfile exists in S3' );
is( delete $t{testfile}, $data, 'testfile removed in S3' );

my %key = (
    foo => 'this is foo.',
    bar => 'this is bar.',
    baz => 'this is baz.  This is getting too old.',
);

$t{$_} = $key{$_} foreach keys %key;
is( scalar %t, 3, 'count of keys in bucket' );
while( my( $k, $v ) = each %t ) {
    is( $t{$k}, $key{$k}, "iterating over $k" );
    is( $key{$k}, $v, "checking value of $k" );
}

%t = ();
ok( !exists $t{foo}, 'hash cleared' );
