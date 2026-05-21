use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Every entry point must behave sensibly on a hash that has never had
# a value stored, and on one that's been Cleared back to empty.

sub run_empty_checks {
    my ($label, $h_ref, $obj) = @_;

    # ---- Tied-hash side -------------------------------------------
    is(scalar keys %$h_ref,   0,  "$label: scalar keys = 0");
    ok(!scalar %$h_ref,           "$label: scalar %h is false (SCALAR)");
    is_deeply([keys %$h_ref], [], "$label: keys list empty");
    is_deeply([values %$h_ref],[],"$label: values list empty");
    ok(!exists $h_ref->{nope},    "$label: exists on missing key");
    ok(!defined $h_ref->{nope},   "$label: fetch missing key is undef");

    # FIRSTKEY via each() returns empty list
    my @each = each %$h_ref;
    is_deeply(\@each, [],         "$label: each on empty returns ()");

    # delete-on-missing returns undef
    is(delete $h_ref->{nope}, undef, "$label: delete missing returns undef");

    # ---- OO side --------------------------------------------------
    is($obj->Length, 0,                       "$label: Length == 0");
    is_deeply([$obj->Keys],   [],             "$label: Keys() empty list");
    is_deeply([$obj->Values], [],             "$label: Values() empty list");
    is_deeply([$obj->Pop],    [],             "$label: Pop on empty -> ()");
    is_deeply([$obj->Shift],  [],             "$label: Shift on empty -> ()");

    # Clear on already-empty is a no-op
    $obj->Clear;
    is($obj->Length, 0,                       "$label: Clear on empty stays empty");
}

# Case A: hash that's never had a value
{
    my $obj = tie my %h, 'Tie::OrderedHash';
    run_empty_checks('fresh empty', \%h, $obj);
}

# Case B: hash filled and then Clear()'d
{
    my $obj = tie my %h, 'Tie::OrderedHash', a => 1, b => 2, c => 3;
    is(scalar keys %h, 3, 'pre-clear: 3 keys');
    $obj->Clear;
    run_empty_checks('cleared empty', \%h, $obj);
}

# Case C: hash filled and Pop'd until empty (exercises the boundary
# where the OH transitions empty without going through Clear)
{
    my $obj = tie my %h, 'Tie::OrderedHash', a => 1, b => 2;
    $obj->Pop; $obj->Pop;
    run_empty_checks('popped empty', \%h, $obj);
}

# Case D: hash filled and Shift'd until empty
{
    my $obj = tie my %h, 'Tie::OrderedHash', a => 1, b => 2;
    $obj->Shift; $obj->Shift;
    run_empty_checks('shifted empty', \%h, $obj);
}

# Case E: hash filled and DELETEd one-by-one
{
    my $obj = tie my %h, 'Tie::OrderedHash', a => 1, b => 2, c => 3;
    delete $h{a}; delete $h{b}; delete $h{c};
    run_empty_checks('all-deleted empty', \%h, $obj);
}

done_testing;
