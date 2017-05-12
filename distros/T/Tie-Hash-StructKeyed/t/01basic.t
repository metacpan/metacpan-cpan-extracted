use strict; use warnings;
use Test::More tests => 16;
use Tie::Hash::StructKeyed;
use Data::Dumper;

# hakim@fotango.com 13 April 2005

tie my %hash, 'Tie::Hash::StructKeyed';

isa_ok(\%hash, 'HASH');
isa_ok(tied(%hash), 'Tie::Hash::StructKeyed');

$hash{foo} = "Foo";
$hash{bar} = "Bar";
is($hash{foo}, 'Foo',
  'Basic (non-array) thing still works');
is($hash{bar}, 'Bar');
is($hash{baz}, undef, 'undef value');

$hash{['wibble', 'foo','bar','baz']} = "WibbleFooBarBaz";
$hash{['wobble', 'foo','bar','baz']} = "WobbleFooBarBaz";

is($hash{['wibble', 'foo','bar','baz']}, 'WibbleFooBarBaz', 
  '[subscripted key] works');
is($hash{['wobble', 'foo','bar','baz']}, 'WobbleFooBarBaz');
is($hash{['wurble', 'foo','bar','baz']}, undef, "Undef");

$hash{['UK', 'English']} = 100;
$hash{['UK', 'German']}  = 10;
$hash{['DE', 'German']}  = 90;
$hash{['DE', 'English']} = 20;

is($hash{['UK', 'English']}, 100, 'multi-path tests');
is($hash{['UK', 'German']},  10);
is($hash{['DE', 'German']},  90);
is($hash{['DE', 'English']}, 20);

$hash{['foo','bar','baz']} =   "FooBarBaz";
is($hash{['foo','bar','baz']}, 'FooBarBaz', 
    '[subscripted key] works');

sub by_keys {
    my ($l, $r) = @_;

    no warnings 'uninitialized';

    return -1 unless defined $l;
    return  1 unless defined $r;
    if (! ref $l) {
        return -1 if ref $r;
        return $l cmp $r;
    } elsif (!ref $r) {
        return 1;
    }
    my @l = @$l or return -1;
    my @r = @$r or return  1;

    my ($l1, $r1) = ((shift @l), (shift @r));
    if (my $cmp = $l1 cmp $r1) { return $cmp }

    return by_keys( @l ? \@l : undef, @r ? \@r : undef );
}

my @keys = sort { by_keys($a,$b) } keys %hash;

is_deeply(\@keys, [
          'bar',
          'foo',
          [
            'DE',
            'English'
          ],
          [
            'DE',
            'German'
          ],
          [
            'UK',
            'English'
          ],
          [
            'UK',
            'German'
          ],
          [
            'foo',
            'bar',
            'baz'
          ],
          [
            'wibble',
            'foo',
            'bar',
            'baz'
          ],
          [
            'wobble',
            'foo',
            'bar',
            'baz'
          ],
    ],
    'Keys returned') or diag Dumper(\@keys);

$hash{ {anon => [1, {complex => 2}]} } = 'complex1';
$hash{ ['list', { foo => 'bar'}] }     = 'complex2';

is ($hash{ {anon => [1, {complex => 2}]} }, 'complex1', 'complex 1');
is ($hash{ ['list', { foo => 'bar'}] }    , 'complex2', 'complex 2');
