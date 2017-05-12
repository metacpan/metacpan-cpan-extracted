#!/usr/bin/perl
use strict;
use warnings;
use Text::Prefix::XS;
use Test::More;
use Devel::Peek;

use Time::HiRes qw(sleep);

my $can_use_threads = eval 'use threads; 1';
if(!$can_use_threads) {
    print '1..0 # SKIP: Perl not threaded';
    exit(0);
}

my @prefixes = qw(foo bar baz);
my $xs_search = prefix_search_create(@prefixes);

my $loop_count = 10;
my @threads;

foreach my $i  (0..$loop_count) {
    push @threads, threads->create(sub {
        sleep(0.1);
        defined $xs_search && defined $$xs_search or die "wtf?";
        
        my $ret = prefix_search($xs_search,'foo');
        undef $xs_search;
        return $ret;
    });    
}

is(prefix_search($xs_search, 'foo'), 'foo', "OK In parent");
note "Undefining xs_search";
undef $xs_search;
note "Done!";

while ( my $thread = pop @threads) {
    is($thread->join(), "foo", "Thread matched ok. " . scalar @threads .
        " threads remaining");
}
done_testing();