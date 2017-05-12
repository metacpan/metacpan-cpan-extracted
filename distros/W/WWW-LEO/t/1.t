#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 8;

# 1)
BEGIN { use_ok('WWW::LEO') };

my $leo = WWW::LEO->new; 
# be nice to LEO and tell that we are doing make test
$leo->agent->agent("Mozilla/5.0 (compatible; WWW::LEO/$WWW::LEO::VERSION (make test))");

# 2)
ok(ref $leo eq 'WWW::LEO');

# num_results should be undef before first query
# 3)
ok(not defined $leo->num_results);

# sincerely hoping that this word will get no more translations :)
$leo->query('Selbstfangfadenführung');
# 4)
ok($leo->num_results == 1);
# the results array should contain 1 element
# 5)
ok(@{$leo->en_de} == 1);

# this query should not produce any hits
$leo->query('adsflkjadsflkjfdgjhsdfg');
# 6)
ok($leo->num_results == 0);

# this should reset the object to the state before the first query
$leo->reset;
# 7)
ok(not defined $leo->num_results);

# this query should produce a maximum number of results (100)
$leo->query('car');
# 8)
ok($leo->num_results == 100);

# vim:ft=perl
