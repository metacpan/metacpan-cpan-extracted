#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 3;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $counter = '::Counter');
$placeholder->compile('Counter: [=counter=] [=counter_alphabetically=]');

my $counter1 = ${$placeholder->execute()};
ok($counter1 eq 'Counter: 1 a', 'T001: start numerically');
my $counter2 = ${$placeholder->execute()};
ok($counter2 eq 'Counter: 3 c', 'T002: increment');
$counter->reset;
my $counter3 = ${$placeholder->execute()};
ok($counter3 eq 'Counter: 1 a', 'T003: reset');

exit(0);
