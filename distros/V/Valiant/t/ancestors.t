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
    "*" => [
      "Just Bad",
      "Failed Retiree validation",
      "Failed TestRole",
    ],
    age => [
      "Age Too Young",
      "Age Logged a 4",
    ],
    name => [
      "Name Too Short 100",
      "Name Too Custom: 123",
      "Name bad retiree name",
      "Name Logged a B",
      "Name is too short (minimum is 3 characters)",
      "Name just weird name",
      "Name Is Invalid",
      "Name Just Bad",
    ],
    retirement_date => [
      "Retirement Date Failed Retiree",
    ],
  };

is_deeply [$retiree->i18n_lookup], [qw/Retiree Person TestRole/];

done_testing;
