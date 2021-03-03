use Test::Lib;
use Test::Most;

{
  package Local::Test;

  use Moo;
  use Valiant::Filters;

  has 'string' => (is=>'ro', required=>1);
  has 'array' => (is=>'ro', required=>1);
  has 'split' => (is=>'ro', required=>1);

  filters ['string', 'array'] => (to_array => 1);
  filters split => (to_array => +{ split_on=>','} );
}

my $object = Local::Test->new(
  string => 'foo',
  array => ['bar', 'baz'],
  split => '1,2,3',
);

is_deeply $object->string, ['foo'];
is_deeply $object->array, ['bar', 'baz'];
is_deeply $object->split, [1,2,3];

done_testing;
