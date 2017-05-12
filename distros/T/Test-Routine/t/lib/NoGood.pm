package t::lib::NoGood;
use Test::Routine;

test "this will be duplicated" => sub { die 'Unimplemented' };

test "this will be duplicated" => sub { die 'Unimplemented' };

1;
