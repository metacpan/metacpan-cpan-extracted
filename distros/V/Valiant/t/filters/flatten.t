use Test::Lib;
use Test::Most;

{
  package Local::Test;

  use Moo;
  use Valiant::Filters;

  has 'pick_first' => (is=>'ro', required=>1);
  has 'pick_last' => (is=>'ro', required=>1);
  has 'join' => (is=>'ro', required=>1);
  has 'sprintf' => (is=>'ro', required=>1);
  has 'pattern' => (is=>'ro', required=>1);

  filters pick_first =>  (flatten=>+{pick=>'first'});
  filters pick_last =>  (flatten=>+{pick=>'last'});
  filters join =>  (flatten=>+{join=>','});
  filters sprintf =>  (flatten=>+{sprintf=>'%s-%s-%s'});
  filters pattern =>  (flatten=>+{pattern=>'hi {{a}} there {{b}}'});
}

my $object = Local::Test->new(
  pick_first => [1,2,3],
  pick_last => [1,2,3],
  join => [1,2,3],
  sprintf => [1,2,3],
  pattern => +{a=>'now', b=>'john'},
);

is $object->pick_first, 1;
is $object->pick_last, 3;
is $object->join, '1,2,3';
is $object->sprintf, '1-2-3';
is $object->pattern, 'hi now there john';

done_testing;
