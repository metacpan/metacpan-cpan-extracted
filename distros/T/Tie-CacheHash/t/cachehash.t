#!/usr/bin/perl -w

# Test file for Tie::CacheHash.
#
# This complement of tests may take up to a minute, regardless of
# your CPU speed (on faster machines it may even decide it's entitled
# to take longer).  Be patient.

############################################################

use strict;
use Config;
use Test;
use Tie::CacheHash;

use vars qw(

	$db_file_present
	%hash
	%par
	$hashobj
	$i
	$lastval
	$is_ok
	$f
	$start_time
	$elapsed_time
	$size

	);

BEGIN	{

	# If DB_File is present, use it for a test.
	my %extensions = map { $_ => 1 } split " ", $Config{extensions};
	$db_file_present = defined($extensions{DB_File});
	use DB_File;

	my $n_tests = $db_file_present ? 14 : 13;
	plan tests => $n_tests;

	}

############################################################

# 1
# Was the module successfully parsed?

ok($Tie::CacheHash::VERSION);

# 2
# Can an object be successfully created?

$hashobj = tie %hash, 'Tie::CacheHash', { 
	min		=> 10,
	min_margin	=> 10,
	max_margin	=> 50,
	max		=> 100,
};
ok($hashobj and ref $hashobj eq 'Tie::CacheHash');

# 3
# Can a custom sort string be assigned?

$hashobj->{sort_func} = '<=>';
ok($hashobj->{sort_func} and not ref $hashobj->{sort_func});

# 4
# Does the keys function return the right number of items?

&load_entries(0, 200, 100_000);
ok(scalar(keys %hash) == 200);

# 5
# Does the values function return the right number of items?

ok(scalar(values %hash) == 200);

# 6
# Does the built-in counter have the right number of items?

ok($hashobj->{num_keys} == 200);

# 7
# Are there an appropriate number of items in the cache?

$i = scalar(@{$hashobj->{cache}});
ok($i >= 10 and $i <= 100);

# 8
# Is the cache in order?

$is_ok = 1;
$lastval = 0;
for $i (0..$#{$hashobj->{cache}}) {
    $is_ok = 0 if $hash{$hashobj->{cache}[$i]} < $lastval;
    $lastval = $hash{$hashobj->{cache}[$i]};
}
ok($is_ok);

# 9
# Delete some keys;  still the right number of items?

&delete_entries(50);
ok(scalar(keys %hash) == 150 and $hashobj->{num_keys} == 150);

# 10
# Clean up that hash.

undef $hashobj;
untie %hash;
ok(!%hash and !tied %hash);

# 11
# Try a smallish hash;  cycle some entries through it.

$Tie::CacheHash::DEBUG = 1;
$hashobj = tie %hash, 'Tie::CacheHash', {
	min		=> 5,
	max		=> 40,
};
$hashobj->{sort_func} = sub { $Tie::Cache::a <=> $Tie::Cache::b };
$start_time = time;
ok($hashobj eq tied %hash and &load_and_unload(\%hash, 30, 100_000));
$elapsed_time = time - $start_time;
undef $hashobj;
untie %hash;

# 12
# Try another smallish hash, this time with a straight sort and
# more collisions among the values.

$hashobj = tie %hash, 'Tie::CacheHash', {
	min		=> 20,
	max		=> 40,
};
ok($hashobj eq tied %hash and &load_and_unload(\%hash, 30, 100));
undef $hashobj;
untie %hash;
$Tie::CacheHash::DEBUG = 0;

# 13
# Try a slightly larger hash, based on how long the previous test
# took (so we don't swamp slow CPUs);  cycle a lot of entries.

$size = int(5000/(($elapsed_time+2)**3));
$size = 15 if $size < 15;
$size = 50 if $size > 50;
$hashobj = tie %hash, 'Tie::CacheHash', {
	min		=> $size,
	max		=> int($size*1.5),
};
$hashobj->{sort_func} = '<=>';
ok($hashobj eq tied %hash and &load_and_unload(\%hash, $size*2, 10_000));
undef $hashobj;
untie %hash;

if ($db_file_present) {

    # 14
    # A test of DB_File.

    $Tie::CacheHash::DEBUG = 2;
    $is_ok = 1;
    local $f = "/tmp/cachehash_db_file_$$";
    my %db_hash;
    my $db_hash_is_tied = 0;
    my $hash_is_tied = 0;
    unlink $f;
    $is_ok = 0 if -e $f;

    if ($is_ok) {
	tie %db_hash, 'DB_File', $f, 66, 0644, $DB_HASH;
	$is_ok = $db_hash_is_tied = (tied %db_hash and ref tied %db_hash eq 'DB_File');
    }
    if ($is_ok) {
	$hashobj = tie %hash, 'Tie::CacheHash', {
	    min		=> 20,
	    max		=> 40,
	    sub_hash	=> \%db_hash,
	};
	$is_ok = $hash_is_tied = $hashobj eq tied %hash;
    }
    if ($is_ok) {
	# Load up the database with 500 entries or so, through the CacheHash.
	for $i (1..10) {
	    &load_entries( int(rand(1_000)), 50, int(rand(10_000)) );
	}
	$is_ok = ($hashobj->{num_keys} == scalar(keys %db_hash));
    }
    if ($is_ok) {
	# Untie the CacheHash from the DB_File hash.  The DB_File hash will
	# remain accessible.
	undef $hashobj;
	untie %hash;
	$hash_is_tied = 0;
	$db_hash{abc123} = '000';
	# Test to be sure the entries were written OK (at least 200 -- there
	# may be some overlap of keys so not the full 500).
	$is_ok = scalar(keys %db_hash) > 200;
    }
    if ($is_ok) {
	# Re-tie the db_hash to a new CacheHash.
	$hashobj = tie %hash, 'Tie::CacheHash', {
	    min		=> 10,
	    max		=> 40,
	    sub_hash	=> \%db_hash,
	};
	$is_ok = $hash_is_tied = $hashobj eq tied %hash;
	print STDERR "cachetest.t new CacheHash, num_entries=$hashobj->{num_keys} db_hashkeys=", scalar(keys %db_hash), "\n";
    }
    if ($is_ok) {
	# OK, that worked.  Now try it when we forget about the db_hash
	# (untie it) and reload it from scratch.
	undef $hashobj;
	untie %hash;
	$hash_is_tied = 0;
	untie %db_hash;
	$db_hash_is_tied = 0;
	print STDERR "cachetest.t untied db_hash, scalar(keys)=" . scalar(keys %db_hash) . "\n";
	$is_ok = (scalar(keys(%db_hash)) == 0);
    }
    if ($is_ok) {
	undef %db_hash;
	sleep 2; # let the disk settle, probably unnecessary
	tie %db_hash, 'DB_File', $f, 66, 0644, $DB_HASH;
	$is_ok = $db_hash_is_tied = (tied %db_hash and ref tied %db_hash eq 'DB_File'
	    and scalar(keys(%db_hash)) > 200);
	print STDERR "cachetest.t retied db_hash, scalar(keys)=" . scalar(keys %db_hash) . "\n";
    }
    if ($is_ok) {
	$hashobj = tie %hash, 'Tie::CacheHash', {
	    min		=> 10,
	    max		=> 40,
	    sub_hash	=> \%db_hash,
	};
	$is_ok = $hash_is_tied = $hashobj eq tied %hash;
	print STDERR "cachetest.t new CacheHash, num_entries=$hashobj->{num_keys} db_hashkeys=", scalar(keys %db_hash), "\n";
    }
    if ($is_ok) {
	# Load up the database with another 500 entries or so.
	for $i (1..5) {
	    &load_entries( int(rand(1_000)), 100, int(rand(10_000)) );
	}
	# Test to be sure the entries were written OK (at least 400).
	$is_ok = scalar(keys %db_hash) > 400;
	print STDERR "cachetest.t num_entries=$hashobj->{num_keys} db_hashkeys=", scalar(keys %db_hash), "\n";
    }
    if ($is_ok) {
	# Make sure our old entry is still there.
	$is_ok = ($db_hash{abc123} eq '000');
    }
    if ($is_ok) {
	# Thrash the DB_File database around a bit.
	$is_ok = &load_and_unload(\%hash, 10, 1000);
	print STDERR "cachetest.t num_entries=$hashobj->{num_keys} db_hashkeys=", scalar(keys %db_hash), "\n";
    }

    if ($hash_is_tied) {
	undef $hashobj;
	untie %hash;
	$hash_is_tied = 0;
    }
    if ($db_hash_is_tied) {
	untie %db_hash;
    }
    unlink $f; # and ignore any error

    ok($is_ok);

}

# All done!

print "END\n";

exit 0;

############################################################

sub load_and_unload {
    my($hashref, $n_cycles, $range) = @_;
    my $is_ok = 1;
    %par = %$hashref;
    my $check_freq = int($n_cycles/10);
    $check_freq = 3 if $check_freq < 3;
    $check_freq = 20 if $check_freq > 20;
    $i = 1;
    while ($is_ok and $i <= $n_cycles) {
	if (rand($n_cycles) < $i) {
	    &delete_entries( int(rand($n_cycles/4)) );
	} else {
	    &load_entries(
		int(rand($n_cycles*5)),
		int(rand($n_cycles/2)*rand($n_cycles/2)),
		$range
	    );
	}
	if (scalar(keys %hash) != scalar(keys %par)) {
	    $is_ok = 0;
	    warn "load_and_unload not OK at n_cycles=$n_cycles, i=$i, keys(hash)=" . scalar(keys %hash) . ", keys(par)=" . scalar(keys %par) . "\n";
	}
	if ($i == 1 or $i % $check_freq == 0 or $i == $n_cycles) {
	    for (keys %hash) {
		if (!defined($par{$_}) or $par{$_} ne $hash{$_}) {
		    $is_ok = 0;
		    warn "load_and_unload not OK at n_cycles=$n_cycles, i=$i, key=$_: '$hash{$_}' '$par{$_}'\n";
		}
	    }
	    for (keys %par) {
		if (!defined($hash{$_}) or $hash{$_} ne $par{$_}) {
		    $is_ok = 0;
		    warn "load_and_unload not OK at n_cycles=$n_cycles, i=$i, key=$_: '$hash{$_}' '$par{$_}'\n";
		}
	    }
	}
	++$i;
    }
    if ($is_ok) {
	&delete_entries(scalar(keys %$hashref));
    }
    %par = ( );
    $is_ok;
}

sub load_entries {
    my($start_entry, $n_entries, $range) = @_;
    srand($start_entry*$n_entries);
    rand();
    for $i ($start_entry..$start_entry+$n_entries-1) {
	my $key = "key$i";
	my $value = int(rand($range));
	$hash{$key} = $value;
	$par{$key} = $value;
    }
}

sub delete_entries {
    my($n_to_delete) = @_;
    my $n_keys = $hashobj->{num_keys};
    return if !$n_keys;
    $n_to_delete = $n_keys if $n_to_delete > $n_keys;
    if (rand() < 0.5) {
	# Delete by zapping "old" entries out of the cache.
	while ($n_to_delete) {
	    my $key = $hashobj->{cache}[0];
	    delete $hash{$key};
	    delete $par{$key};
	    --$n_to_delete;
	}
    } else {
	# Delete by picking random entries.
	my $prob = ($n_to_delete*1.01+2)/$n_keys;
	if ($prob > 1) {
	    $prob = 1;
	} else {
	    $prob /= 2;
	}
	my($key, $value);
	while ($n_to_delete) {
	    DEL: while (($key, $value) = each %hash) {
		if (rand() < $prob) {
		    delete $hash{$key};
		    delete $par{$key};
		    --$n_to_delete;
		    if (!$n_to_delete) {
			last DEL;
		    }
		}
	    }
	    $prob *= 1.2;
	    $prob = 1 if $prob > 1;
	}
    }
}

