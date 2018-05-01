use strict;
use warnings;
use FindBin '$Bin';

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 7) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";

use_ok('Tree::Interval::Fast::Interval');
use_ok('Tree::Interval::Fast');

no_leaks_ok {
  my $i1 = Tree::Interval::Fast::Interval->new(10, 20, 10);
  my ($low, $high, $data) = ($i1->low, $i1->high, $i1->data);
  
  my $i2 = $i1->copy;
  ($low, $high, $data) = ($i2->low, $i2->high, $i2->data);
  
  my $i3 = Tree::Interval::Fast::Interval->new(21, 30, 21);
  $i1->overlap($i3); $i3->equal($i1);
  
  my $i4 = Tree::Interval::Fast::Interval->new(5, 15, 5);
  $i1->equal($i4); $i4->overlap($i1);

  my $i5 = Tree::Interval::Fast::Interval->new(10, 20, { a => 1, b => 2 });
  ($low, $high, $data) = ($i5->low, $i5->high, $i5->data);
  $i1->overlap($i5); $i5->equal($i1);
 
} 'Interval';

no_leaks_ok {
  my $tree = Tree::Interval::Fast->new();
} 'Empty tree';

my $intervals = make_intervals();

no_leaks_ok {
  my $tree = Tree::Interval::Fast->new();
  foreach my $interval (@{$intervals}) {
    $tree->insert($interval);
  }
  $tree->size();
} 'Tree after insertion';

no_leaks_ok {
  my $tree = Tree::Interval::Fast->new();
  foreach my $interval (@{$intervals}) {
    $tree->insert($interval);
  }

  my $result = $tree->find(6., 7.);
  $result = $tree->find(1, 4);

  my $results = $tree->findall(8, 11);

} 'Tree after insertion/querying';

no_leaks_ok {
  my $tree = Tree::Interval::Fast->new();
  foreach my $interval (@{$intervals}) {
    $tree->insert($interval);
  }

  for my $i (0 .. 5) {
    $tree->remove($intervals->[$i]);
    $tree->size();
  }
} 'Tree after insertion/removal';


sub make_intervals {
  return [
	  Tree::Interval::Fast::Interval->new(15, 20, 10),
	  Tree::Interval::Fast::Interval->new(10, 30, 20),
	  Tree::Interval::Fast::Interval->new(17, 19, 30),
	  Tree::Interval::Fast::Interval->new(5, 20, 40),
	  Tree::Interval::Fast::Interval->new(12, 15, 50),
	  Tree::Interval::Fast::Interval->new(30, 40, 25)
	 ];
}
