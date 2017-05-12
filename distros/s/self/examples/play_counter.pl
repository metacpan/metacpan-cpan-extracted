#!/usr/bin/env perl


use lib '.';

use Counter;

$\="\n";
my $c = Counter->new;

# 1
$c->inc;
print $c->out;

# 5
$c->set(5);
print $c->out;

# 6
$c->inc;
print $c->out;
