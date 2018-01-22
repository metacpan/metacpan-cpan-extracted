# perl
# t/002_functional.t - check functional interface
use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype looks_like_number );
use Text::CSV::Hashify;
use Test::More tests => 18;

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

{
    my ($source, $key, $h1, $h2, $h3);

    note(".csv input");
    $source = "./t/data/cpan-river.csv";
    $key = 'dist';
    local $@;
    eval { $h1 = hashify($source, $key); };
    is($@, '', "'hashify()' completed without error");
    ok($h1, "'hashify()' returned true value");
    is(reftype($h1), 'HASH', "'hashify()' returned hash reference");

    note(".psv input");
    $source = "./t/data/cpan-river.psv";
    $key = 'dist';
    local $@;
    eval { $h2 = hashify($source, $key); };
    is($@, '', "'hashify()' completed without error");
    ok($h2, "'hashify()' returned true value");
    is(reftype($h2), 'HASH', "'hashify()' returned hash reference");
    is_deeply($h1, $h2, "hashify() returned same hash reference for CSV and PSV");

    note(".tsv input");
    $source = "./t/data/cpan-river.tsv";
    $key = 'dist';
    local $@;
    eval { $h3 = hashify($source, $key); };
    is($@, '', "'hashify()' completed without error");
    ok($h3, "'hashify()' returned true value");
    is(reftype($h3), 'HASH', "'hashify()' returned hash reference");
    is_deeply($h1, $h3, "hashify() returned same hash reference for CSV and TSV");
    is_deeply($h2, $h3, "hashify() returned same hash reference for PSV and TSV");
}
