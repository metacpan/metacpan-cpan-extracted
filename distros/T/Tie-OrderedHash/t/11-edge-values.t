use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Storage of every awkward value shape we expect to round-trip
# through STORE / FETCH cleanly.

# ---- undef ---------------------------------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{u} = undef;
    ok(exists $h{u},      'undef value: exists is true');
    ok(!defined $h{u},    'undef value: fetch returns undef');
    is(scalar keys %h, 1, 'undef value: still one entry');
}

# ---- falsey scalars ------------------------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    my @cases = ( zero => 0, empty_str => '', zero_str => '0' );
    while (my ($k, $v) = splice @cases, 0, 2) {
        $h{$k} = $v;
    }
    ok(exists $h{zero},      'falsey 0: exists');
    ok(exists $h{empty_str}, 'falsey "": exists');
    ok(exists $h{zero_str},  'falsey "0": exists');
    is($h{zero},      0,  'falsey 0 round-trip');
    is($h{empty_str}, '', 'falsey "" round-trip');
    is($h{zero_str},  '0', 'falsey "0" round-trip');
}

# ---- numeric / floating-point preservation -------------------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{int}    = 42;
    $h{float}  = 3.14159;
    $h{neg}    = -7;
    $h{huge}   = 2**40;
    is($h{int},   42,      'IV preserved');
    cmp_ok($h{float}, '==', 3.14159, 'NV preserved');
    is($h{neg},   -7,      'negative IV preserved');
    is($h{huge},  2**40,   'large IV preserved');
}

# ---- references: ARRAY / HASH / CODE / blessed --------------------
{
    tie my %h, 'Tie::OrderedHash';
    my $ar = [10, 20, 30];
    my $hr = { a => 1 };
    my $cr = sub { 42 };
    my $br = bless { id => 7 }, 'Some::Thing';
    $h{ar} = $ar;
    $h{hr} = $hr;
    $h{cr} = $cr;
    $h{br} = $br;

    is(ref $h{ar}, 'ARRAY',       'ARRAY ref preserved');
    is_deeply($h{ar}, [10,20,30], 'ARRAY contents preserved');

    is(ref $h{hr}, 'HASH',        'HASH ref preserved');
    is_deeply($h{hr}, { a => 1 }, 'HASH contents preserved');

    is(ref $h{cr}, 'CODE',        'CODE ref preserved');
    is($h{cr}->(), 42,            'CODE ref invocable');

    isa_ok($h{br}, 'Some::Thing', 'blessed ref class survives');
    is($h{br}{id}, 7,             'blessed ref payload survives');
}

# ---- autovivification through FETCH lands back in storage ---------
{
    tie my %h, 'Tie::OrderedHash';
    $h{nested}{a}{b} = 42;
    is($h{nested}{a}{b}, 42, 'autoviv: deep set readable via FETCH');
    is_deeply($h{nested}, { a => { b => 42 } },
              'autoviv: top-level value is the expected nested hashref');
}

# ---- storing the same ref at two keys: independent slots, shared
#      referent (newSVsv on a ref copies the ref, not the target) -----
{
    tie my %h, 'Tie::OrderedHash';
    my $shared = { count => 1 };
    $h{x} = $shared;
    $h{y} = $shared;
    $shared->{count} = 99;
    is($h{x}{count}, 99, 'shared referent: x sees mutation');
    is($h{y}{count}, 99, 'shared referent: y sees mutation');
    isnt(\$h{x}, \$h{y},  'storage SV slots are distinct');
}

# ---- storing a scalar then mutating the source: stored copy is
#      independent (STORE calls newSVsv on plain scalars) -------------
{
    tie my %h, 'Tie::OrderedHash';
    my $src = 'before';
    $h{snap} = $src;
    $src = 'after';
    is($h{snap}, 'before',
       'stored scalar is a copy: source mutation does not bleed in');
}

# ---- large string value (1 MiB) -----------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    my $big = 'x' x (1024 * 1024);
    $h{big} = $big;
    is(length $h{big}, 1024 * 1024, '1 MiB value preserved (length)');
    is(substr($h{big}, 0, 4),         'xxxx', '... start matches');
    is(substr($h{big}, -4),           'xxxx', '... end matches');
}

# ---- overwrite with the value's own FETCH (self-assign) -----------
{
    tie my %h, 'Tie::OrderedHash';
    $h{a} = 1; $h{b} = 2; $h{c} = 3;
    $h{b} = $h{b};
    is_deeply([keys %h], [qw(a b c)], 'self-assign keeps order');
    is($h{b}, 2,                       'self-assign keeps value');
    is(scalar keys %h, 3,              'self-assign keeps count');
}

done_testing;
