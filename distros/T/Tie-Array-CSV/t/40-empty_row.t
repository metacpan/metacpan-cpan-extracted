use strict;
use warnings;

use Test::More;
use File::Temp;

use Tie::Array::CSV;

{
  my $file = File::Temp->new;
  tie my @array, 'Tie::Array::CSV', $file;

  eval { my $tmp = $array[0][0] };
  ok ! $@, 'Accessing empty row lives';
}

{
  my $file = File::Temp->new;
  tie my @array, 'Tie::Array::CSV', $file;

  eval { $array[0][0] = 1 };
  ok ! $@, 'Assigning to empty row lives';

  eval { $array[4][0] = 1 };
  ok ! $@, 'Assigning to later empty row lives';

  is $array[4][0], 1, 'Assignment successful';
}

done_testing;

