use Test::Most;
use Test::Lib;

#eval "use OP::Person; 1" || do { plan skip_all => "Can't run Object::Pad tests: $@"};

plan skip_all => 'Object::Pad not yet supported';

ok my $p = OP::Person->new(
  name=>'B',
  age=>4,
  alive=>1);

ok $p->invalid;
is_deeply +{ $p->errors->to_hash(full_messages=>1) }, +{
  "age" => [
    "Age Too Young",
  ],
  "name" => [
    "Name Too Short 100",
  ],
  "*" => [
    "Just Bad",
  ],
};

done_testing;
