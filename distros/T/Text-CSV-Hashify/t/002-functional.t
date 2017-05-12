# perl
# t/002_functional.t - check functional interface
use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype looks_like_number );
use Test::More tests => 6;
use lib ('./lib');
use Text::CSV::Hashify;

my ($obj, $source, $key, $href, $k);

$source = "./t/data/names.csv";
$key = 'id';

{
    local $@;
    eval { $href = hashify($source); };
    like($@, qr/^'hashify\(\)' must have two arguments/,
        "'hashify()' failed due to insufficient number of arguments");
}
    
{
    local $@;
    eval { $href = hashify($source, ''); };
    $k = 1;
    like($@, qr/^'hashify\(\)' argument at index '$k' not true/,
        "'hashify()' failed due to non-true argument");
}
    
{
    $source = "./t/data/names.csv";
    $key = 'id';

    local $@;
    eval { $href = hashify($source, $key); };
    is($@, '', "'hashify()' completed without error");
    ok($href, "'hashify()' returned true value");
    is(reftype($href), 'HASH', "'hashify()' returned hash reference"); 

    my $obj = Text::CSV::Hashify->new( {
        file    => $source,
        key     => $key,
    } );
    my $oo_href = $obj->all();
    is_deeply($href, $oo_href,
        "'hashify()' and 'all()' returned same hash");
}
