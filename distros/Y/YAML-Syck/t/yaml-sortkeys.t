use strict;
use warnings;
use Test::More tests => 6;
use YAML::Syck;

# $YAML::Syck::SortKeys defaults to 1 (true).
# When true, hash keys in Dump output are sorted lexicographically.
# When false, hash keys appear in Perl's internal iteration order.

# Use enough keys that Perl's random hash ordering is extremely unlikely
# to coincidentally produce sorted output.
my %data = map { $_ => 1 } 'a' .. 'z';

# Helper to extract keys from YAML output.
# Handles both bare keys (a: 1) and quoted keys ("n": 1, "y": 1).
sub extract_keys {
    my ($yaml) = @_;
    my @keys;
    while ($yaml =~ /^"?([a-z])"?: /mg) {
        push @keys, $1;
    }
    return @keys;
}

{
    # Default: SortKeys = 1
    local $YAML::Syck::SortKeys = 1;
    my $yaml = YAML::Syck::Dump(\%data);
    my @keys_in_yaml = extract_keys($yaml);
    is_deeply(\@keys_in_yaml, [sort @keys_in_yaml],
        'SortKeys=1 emits hash keys in sorted order');
    is(scalar @keys_in_yaml, 26, 'all 26 keys present in sorted output');
}

{
    # SortKeys = 0 — keys are NOT guaranteed sorted.
    # We can't assert a specific order (it's perl-internal), but we can
    # verify that Dump still produces valid YAML with all keys present.
    local $YAML::Syck::SortKeys = 0;
    my $yaml = YAML::Syck::Dump(\%data);
    my @keys_in_yaml = extract_keys($yaml);
    is(scalar @keys_in_yaml, 26, 'SortKeys=0 still emits all 26 keys');

    # Roundtrip: Load the unsorted output and verify data integrity
    my $loaded = YAML::Syck::Load($yaml);
    is_deeply($loaded, \%data, 'SortKeys=0 output roundtrips correctly');
}

{
    # Nested hashes: sorted keys at every level
    local $YAML::Syck::SortKeys = 1;
    my %nested = (
        zebra  => { charlie => 1, alpha => 2, beta => 3 },
        apple  => { zulu    => 1, mike  => 2 },
    );
    my $yaml = YAML::Syck::Dump(\%nested);

    # Top-level keys should be sorted
    my @top_keys;
    while ($yaml =~ /^([a-z]+):/mg) {
        push @top_keys, $1 if $1 eq 'apple' || $1 eq 'zebra';
    }
    is_deeply(\@top_keys, ['apple', 'zebra'],
        'SortKeys=1 sorts top-level keys');

    # The inner keys of "zebra" should be alpha, beta, charlie
    my ($zebra_block) = $yaml =~ /^zebra:\n((?:  .+\n)+)/m;
    my @inner_keys = ($zebra_block =~ /^\s+([a-z]+):/mg);
    is_deeply(\@inner_keys, ['alpha', 'beta', 'charlie'],
        'SortKeys=1 sorts nested hash keys too');
}
