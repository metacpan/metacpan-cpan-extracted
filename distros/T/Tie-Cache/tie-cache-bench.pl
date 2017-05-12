#!/usr/bin/perl

use Tie::Cache;
use Tie::Cache::LRU;
use Benchmark;
use strict;

my $cache_size = 5000;
my $write_count = $cache_size * 2;
my $read_count = $write_count * 4;
my $delete_count = $write_count;

tie my %cache, 'Tie::Cache', $cache_size;
tie my %cache_lru, 'Tie::Cache::LRU', $cache_size;

my @cols;
push(@cols, \%cache, \%cache_lru);

printf " %15s", "Cache Size $cache_size";
for(@cols) {
    my $module = ref(tied(%$_));
    printf " %16s %3.2f", $module, eval "\$$module"."::VERSION";
}
print "\n";

&report("$write_count Writes", sub {
	    my $cache = shift;
	    for(1..$write_count) {
		$cache->{$_} = $_;
	    }
	},
	@cols,
	);

&report("$read_count Reads", sub {
	    my $cache = shift;
	    for(1..$read_count) {
		my $value = $cache->{$_};
	    }
	},
	@cols,
	);

&report("$delete_count Deletes", sub {
	    my $cache = shift;
	    for(1..$delete_count) {
		my $value = $cache->{$_};
	    }
	},
	@cols,
	);

sub report {
    my($desc, $sub, @caches) = @_;

    printf(" %-15s", $desc);
    for my $cache (@caches) {
	my $timed = timestr(timeit(1, sub { &$sub($cache) }));
	$timed =~ /([\d\.]+\s+cpu)/i;
	printf("%18s sec", $1);
    }
    print "\n";
}

