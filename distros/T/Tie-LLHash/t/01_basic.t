use strict;
use warnings;

use Test::More 0.88;
END { done_testing }
use Tie::LLHash;

{
  # Test the tie interface
  tie(my %hash, 'Tie::LLHash');
  isa_ok tied %hash, 'Tie::LLHash';

  # Add first element
  (tied %hash)->first('firstkey', 'firstval');
  is $hash{firstkey}, 'firstval';

  # Add more elements
  (tied %hash)->insert( red => 'rudolph', 'firstkey');
  (tied %hash)->insert( orange => 'julius', 'red');
  is $hash{red}, 'rudolph';
  is $hash{orange}, 'julius';
  {
    my @keys = keys %hash;
    is $keys[0], 'firstkey';
    is $keys[1], 'red';
    is $keys[2], 'orange';
  }

  # Delete first element
  delete $hash{firstkey};
  is keys %hash, 2;
  ok !exists $hash{firstkey};

  # Delete all elements
  {
    my $o = delete $hash{orange};
    is $o, 'julius';
    ok !exists $hash{orange};

    my $r = delete $hash{red};
    is $r, 'rudolph';
    ok !exists $hash{red};

    is keys %hash, 0;
    ok !scalar %hash;
  }

  # Exercise the ->last method
  {
    for my $i (0..9) {
      (tied %hash)->last($i, 1);
    }

    is_deeply [ keys %hash ], [ 0..9 ];
  }

  # Scalar context and delete all contents
  SKIP: {
     skip q{$tied_hash->SCALAR wasn't implemented on Perls < 5.8.3}, 1 if $^V lt v5.8.3;
     ok scalar %hash;
  }
  %hash = ();
  ok !%hash;

  # Combine some ->first and ->last action
  {
    my @result = qw(1 6 4 5 7 9 n r);
    (tied %hash)->first(5 => 1);
    (tied %hash)->last (7 => 1);
    (tied %hash)->last (9 => 1);
    (tied %hash)->first(4 => 1);
    (tied %hash)->last (n => 1);
    (tied %hash)->first(6 => 1);
    (tied %hash)->first(1 => 1);
    (tied %hash)->last (r => 1);

    is_deeply [ keys %hash ], \@result;
  }
}

# Create a new hash with an initialization hash
{
  my @keys = qw(zero one two three four five six seven eight);
  tie(my %hash, 'Tie::LLHash', map { $keys[$_], $_ } 0..8);

  is_deeply [ keys %hash ], \@keys;
  is_deeply [ values %hash ], [ 0..8 ];
  my $i = 0;
  is_deeply \%hash, { map { $_ => $i++ } @keys };
}

# Use insert() to add an item at the beginning
{
  my $t = tie(my %hash, 'Tie::LLHash', one => 1);
  $t->insert(zero => 0);
  is $t->first, 'zero';
  is $t->last, 'one';
}

# Lazy mode
{
  tie(my %hash, 'Tie::LLHash', { lazy => 1 }, zero => 0);
  $hash{one} = 1;
  my @keys = keys %hash;
  is $keys[0], 'zero';
  is $keys[1], 'one';
}

{
  # Test deletes in a loop
  tie(my %hash, 'Tie::LLHash', { lazy => 1 });

  $hash{one} = 1;
  $hash{two} = 2;
  $hash{three} = 3;
  is keys %hash, 3;

  my ($k, $v) = each %hash;
  is $k, 'one';
  delete $hash{$k};

  ($k, $v) = each %hash;
  is $k, 'two';
  delete $hash{$k};

  ($k, $v) = each %hash;
  is $k, 'three';
  delete $hash{$k};

  is keys %hash, 0;
}
