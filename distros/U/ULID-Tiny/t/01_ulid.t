#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use Test::More;
use lib 'lib';
use ULID::Tiny;

###############################################################################
# Module loading
###############################################################################

ok(defined(&ulid),        'ulid() is exported');
ok(defined(&ulid_date),   'ulid_date() is importable');

###############################################################################
# Basic ULID generation
###############################################################################

my $id = ulid();
ok(defined($id),       'ulid() returns a defined value');
is(length($id), 26,    'ULID is 26 characters long');
like($id, qr/^[0-9A-HJKMNP-TV-Z]{26}$/i, 'ULID uses valid Crockford Base32 characters');

###############################################################################
# Uniqueness
###############################################################################

my %seen;
my $count = 1000;
for (1 .. $count) {
	$seen{ulid()}++;
}
is(scalar(keys %seen), $count, "$count ULIDs are all unique");

###############################################################################
# Monotonic ordering within the same millisecond
###############################################################################

{
	my $ts   = 1700000000000; # Fixed timestamp
	my $prev = ulid(time => $ts);

	for my $i (1 .. 10) {
		my $curr = ulid(time => $ts);
		cmp_ok($curr, 'gt', $prev, "Monotonic increment $i: $prev < $curr");
		$prev = $curr;
	}
}

{
	my $ts   = 1700000000001; # Another timestamp
	my $first = ulid(time => $ts);
	
	# Asking for unique => 1 should skip monotonic increment,
	# so it might be less or greater, but it should not just be $first + 1.
	my $unique_ulid = ulid(time => $ts, unique => 1);
	
	# The subsequent regular ulid should still monotonic-increment from $first,
	# because unique doesn't update the state
	my $next_regular = ulid(time => $ts);
	
	isnt($unique_ulid, $next_regular, 'unique => 1 generates a completely separate ULID');
	cmp_ok($next_regular, 'gt', $first, "Regular monotonic increment continues normally after unique call");
}

###############################################################################
# ulid_date() - timestamp extraction
###############################################################################

{
	my $ts = 1700000000000;
	my $id = ulid(time => $ts);
	my $extracted = ulid_date($id);
	is($extracted, $ts, "ulid_date() extracts correct timestamp ($ts)");
}

{
	# Current time round-trip
	my $before = int(Time::HiRes::time() * 1000);
	my $id     = ulid();
	my $after  = int(Time::HiRes::time() * 1000);
	my $got    = ulid_date($id);

	cmp_ok($got, '>=', $before, 'Extracted timestamp >= time before generation');
	cmp_ok($got, '<=', $after,  'Extracted timestamp <= time after generation');
}

###############################################################################
# ulid_date() - edge cases
###############################################################################

{
	# Timestamp 0 (Unix epoch)
	my $id = ulid(time => 0);
	is(ulid_date($id), 0, 'ulid_date() handles epoch 0');
}

{
	# A far-future timestamp
	my $ts = 2**47; # Within 48-bit range
	my $id = ulid(time => $ts);
	is(ulid_date($id), $ts, 'ulid_date() handles large timestamp');
}

###############################################################################
# ulid(binary => 1)
###############################################################################

{
	my $bytes = ulid(binary => 1);
	ok(defined($bytes),        'ulid(binary => 1) returns defined value');
	is(length($bytes), 16,     'ulid(binary => 1) returns 16 bytes');
}

###############################################################################
# binary round-trip consistency
###############################################################################

{
	my $ts    = 1700000000000;
	my $id    = ulid(time => $ts);
	my $bin   = ulid(time => $ts, binary => 1);

	# Extract timestamp from string
	my $ts_from_str = ulid_date($id);

	# Extract timestamp from binary: first 6 bytes = 48-bit big-endian timestamp
	# Pad to 8 bytes for Q> (unsigned 64-bit big-endian) unpack
	my $ts_from_bin = unpack("Q>", "\0\0" . substr($bin, 0, 6));

	is($ts_from_bin, $ts_from_str, 'Binary and string encode the same timestamp');
}

###############################################################################
# Lexicographic sorting matches time ordering
###############################################################################

{
	my @times = (1600000000000, 1650000000000, 1700000000000, 1750000000000);
	my @ids   = map { ulid(time => $_) } @times;

	my @sorted = sort @ids;
	is_deeply(\@ids, \@sorted, 'ULIDs sort lexicographically in time order');
}

###############################################################################
# Input validation
###############################################################################

eval { ulid_date("SHORT") };
like($@, qr/Invalid ULID/, 'ulid_date() rejects short strings');

eval { ulid_date(undef) };
like($@, qr/Invalid ULID/, 'ulid_date() rejects undef');

###############################################################################

done_testing();

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
