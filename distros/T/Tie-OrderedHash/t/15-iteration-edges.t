use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# FIRSTKEY/NEXTKEY use a single integer cursor stashed alongside the
# storage. This file pokes at the cases where the cursor's lifecycle
# matters: explicit reset, mid-loop modification, exhaustion-then-
# restart.

# ---- each() returns (k,v) pairs in insertion order ----------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{$_} = uc $_ for qw(a b c d);
    my @out;
    while (my ($k, $v) = each %h) {
        push @out, [$k, $v];
    }
    is_deeply(\@out,
              [['a','A'],['b','B'],['c','C'],['d','D']],
              'each() yields pairs in insertion order');

    # After exhaustion the iterator implicitly resets, so the next
    # each() restarts from the front. This is standard Perl behaviour
    # that we should match for a tied hash.
    my @restart = each %h;
    is_deeply(\@restart, ['a', 'A'],
              'each() after exhaustion implicitly resets and restarts');
}

# ---- keys %h resets the iterator ---------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{$_} = $_ for qw(x y z);
    # Advance the cursor partway
    my ($k, $v) = each %h;     # cursor at position 1
    is($k, 'x', 'partial-iter cursor at first key');

    # `keys` resets it back to the start
    my @ks = keys %h;
    is_deeply(\@ks, [qw(x y z)], 'keys returns full list mid-iteration');

    # Now each() restarts from the front
    ($k, $v) = each %h;
    is($k, 'x', 'each() restarts from front after keys reset');
}

# ---- starting a new for/foreach starts a new traversal -----------
{
    tie my %h, 'Tie::OrderedHash';
    $h{$_} = $_ for qw(p q r);

    my @run1; for my $k (keys %h) { push @run1, $k }
    my @run2; for my $k (keys %h) { push @run2, $k }
    is_deeply(\@run1, [qw(p q r)], 'first foreach: full ordered keys');
    is_deeply(\@run2, [qw(p q r)], 'second foreach: full ordered keys');
}

# ---- delete during foreach over keys() is safe -------------------
# `keys %h` materialises a list snapshot, so the loop body can delete
# entries without disturbing the iteration.
{
    tie my %h, 'Tie::OrderedHash';
    $h{$_} = $_ for qw(a b c d e);
    for my $k (keys %h) {
        delete $h{$k} if $k eq 'b' || $k eq 'd';
    }
    is_deeply([keys %h], [qw(a c e)],
              'delete during foreach(keys): order maintained, even keys gone');
    is(scalar keys %h, 3, 'count reduced as expected');
}

# ---- modify-only during each() preserves count + structure -------
{
    tie my %h, 'Tie::OrderedHash';
    $h{$_} = 0 for qw(a b c);
    while (my ($k) = each %h) {
        $h{$k} = uc $k;
    }
    is_deeply({%h}, { a=>'A', b=>'B', c=>'C' },
              'value mutation inside each() takes effect');
    is_deeply([keys %h], [qw(a b c)],
              'value mutation inside each() leaves order intact');
}

# ---- exhausted each() then store-then-iterate again --------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{$_} = 1 for qw(a b);
    1 while each %h;             # drain
    $h{c} = 1;
    my @after = keys %h;
    is_deeply(\@after, [qw(a b c)],
              'new key appended after drained iteration is visible');

    # Iterator reset (via keys above) means each() restarts at 'a'
    my ($k) = each %h;
    is($k, 'a', 'each() after keys reset starts at the front');
}

# ---- empty hash never enters the loop body ----------------------
{
    tie my %h, 'Tie::OrderedHash';
    my $entered = 0;
    while (each %h) { $entered++ }
    is($entered, 0, 'each() on empty: loop body never runs');
}

done_testing;
