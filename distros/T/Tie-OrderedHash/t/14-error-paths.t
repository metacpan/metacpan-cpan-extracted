use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Every entry point that takes a (k, v, k, v, ...) tail must croak on
# odd-count arguments. Errors mention the method name.

# ---- TIEHASH ------------------------------------------------------
{
    my %h;
    my $err = eval {
        tie %h, 'Tie::OrderedHash', 'a';   # one arg = odd
        ''
    } || $@;
    like($err, qr/TIEHASH.*odd number of arguments/i,
         'tie with odd args croaks');
}

{
    my %h;
    my $err = eval {
        tie %h, 'Tie::OrderedHash', 'a', 1, 'b';   # 3 args = odd
        ''
    } || $@;
    like($err, qr/TIEHASH.*odd number of arguments/i,
         'tie with 3 args croaks');
}

# ---- new ----------------------------------------------------------
{
    my $err = eval {
        Tie::OrderedHash->new('only-one');
        ''
    } || $@;
    like($err, qr/new.*odd number of arguments/i,
         'new() with odd args croaks');
}

# ---- Push ---------------------------------------------------------
{
    my $obj = tie my %h, 'Tie::OrderedHash';
    my $err = eval { $obj->Push('a', 1, 'b'); '' } || $@;
    like($err, qr/Push.*odd number of arguments/i,
         'Push with odd args croaks');
    is($obj->Length, 0, 'failed Push leaves the hash unchanged');
}

# ---- Unshift ------------------------------------------------------
{
    my $obj = tie my %h, 'Tie::OrderedHash';
    my $err = eval { $obj->Unshift('a'); '' } || $@;
    like($err, qr/Unshift.*odd number of arguments/i,
         'Unshift with odd args croaks');
    is($obj->Length, 0, 'failed Unshift leaves the hash unchanged');
}

# ---- The good paths still work after the error paths above
# (the croaks shouldn't have left the package state broken). --------
{
    tie my %h, 'Tie::OrderedHash', a => 1, b => 2;
    is_deeply([keys %h], [qw(a b)], 'good path still intact');
}

done_testing;
