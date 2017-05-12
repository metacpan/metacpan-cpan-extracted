use Test::More;
use Test::Exception;
use strict;
use warnings;

BEGIN {
    eval q{use Tripletail qw(/dev/null)};
}

END {
}

if(!$ENV{TL_MEMCACHE_CHECK}){
   plan skip_all => "skipping tests for Tripletail::MemCached for \$ENV{TL_MEMCACHE_CHECK} being false.";
}

eval "use Cache::Memcached";
if ($@) {
    plan skip_all => "skipping tests for Tripletail::MemCached for Cache::Memcached being unavailable.";
}

plan tests => 14 + 11;

my $mem;
ok($mem = $TL->newMemCached, 'newMemCached');

is($mem->set('TLTEST' => 10), 1, 'set');
dies_ok {$mem->set} 'set die';
dies_ok {$mem->set(\123)} 'set die';
dies_ok {$mem->set(' ')} 'set die';
dies_ok {$mem->set('TLTEST')} 'set die';

is($mem->get('TLTEST'), 10, 'get');
dies_ok {$mem->get} 'get die';
dies_ok {$mem->get(\123)} 'get die';
dies_ok {$mem->get(' ')} 'get die';

is($mem->delete('TLTEST'), 1, 'delete');
dies_ok {$mem->delete} 'delete die';
dies_ok {$mem->delete(\123)} 'delete die';
dies_ok {$mem->delete(' ')} 'delete die';

my ($ref, $ref_get);

# array reference test
$ref = [1, 2, { 4 => 5, 6 => 7}, 8];
is($mem->set('TLTEST' => $ref), 1, 'set arrayref');
$ref_get = $mem->get('TLTEST');
is_deeply($ref, $ref_get, 'get arrayref has equal data');
isnt(scalar($ref), scalar($ref_get), 'get arrayref has different pointer');
isnt(scalar($ref->[2]), scalar($ref_get->[2]), 'get arrayref has different pointer');
$ref->[2]->{4} += 10;
is($ref_get->[2]->{4}, 5, 'get arrayref have copied deeply');

# hash reference test
$ref = {1 => 2, 3 => [ 4, 5, { 6 => 7 } ], 8 => { 9 => 10} };
is($mem->set('TLTEST' => $ref), 1, 'set hashref');
$ref_get = $mem->get('TLTEST');
is_deeply($ref, $ref_get, 'get hashref has equal data');
isnt(scalar($ref), scalar($ref_get), 'get hashref different pointer');
isnt(scalar($ref->{3}), scalar($ref_get->{3}), 'get hashref different pointer');
$ref->{3}->[1] += 10;
is($ref_get->{3}->[1], 5, 'get hashref have copied deeply');

is($mem->delete('TLTEST'), 1, 'delete');
