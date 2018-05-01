use 5.008;
use strict;
use warnings;
use Test::More tests => 22, 'die';

use FindBin qw( $Bin );
use Data::Dumper;

BEGIN {
  use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";
  use_ok 'Tree::Interval::Fast::Interval';
}

my $interval = Tree::Interval::Fast::Interval->new(10, 20, [1,2,3]);
isa_ok($interval, "Tree::Interval::Fast::Interval");
is($interval->low, 10, 'left bound');
is($interval->high, 20, 'right bound');
is_deeply($interval->data, [1,2,3], 'interval data');

my $copy = $interval->copy;
isa_ok($copy, "Tree::Interval::Fast::Interval");
is($copy->low, 10, 'left bound');
is($copy->high, 20, 'right bound');
is_deeply($copy->data, [1,2,3], 'interval data');

my $non_overlapping = Tree::Interval::Fast::Interval->new(21, 30, 21);
ok(!$interval->overlap($non_overlapping), 'does not overlap');
ok(!$non_overlapping->overlap($interval), 'does not overlap');
ok(!$interval->equal($non_overlapping), 'not equal');
ok(!$non_overlapping->equal($interval), 'not equal');
   
my $overlapping = Tree::Interval::Fast::Interval->new(5, 15, 5);
ok($interval->overlap($overlapping), 'overlaps');
ok($overlapping->overlap($interval), 'overlaps');
ok(!$interval->equal($overlapping), 'not equal');
ok(!$overlapping->equal($interval), 'not equal');

my $interval2 = Tree::Interval::Fast::Interval->new(10, 20, { a => 1, b => 2 });
is_deeply($interval2->data, { a => 1, b => 2}, 'store any kind of data');
ok($interval->overlap($interval2), 'overlaps');
ok($interval2->overlap($interval), 'overlaps');
ok($interval->equal($interval2), 'equal');
ok($interval2->equal($interval), 'equal');

diag( "Testing Tree::Interval::Fast::Interval $Tree::Interval::Fast::VERSION, Perl $], $^X" );
