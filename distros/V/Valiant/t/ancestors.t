use Test::Lib;
use Test::Most;
use Retiree;

ok my $retiree = Retiree->new(
  name=>'B',
  age=>4,
  retirement_date=>'2020');

ok $retiree->invalid;
is_deeply +{ $retiree->errors->to_hash(full_messages=>1) },
  {
    '*' => [
      "Just Bad",
      "Failed TestRole",
    ],
    age => [
      "Age Logged a 4",
      "Age Too Young",
    ],
    name => [
      "Name Too Custom: 123",
      "Name Logged a B",
      "Name is too short (minimum is 3 characters)",
      "Name just weird name",
      "Name Too Short 100",
      "Name Is Invalid",
      "Name Just Bad",
    ],
    retirement_date => [
      "Retires On Failed Retiree",
    ],     
  };

done_testing;
