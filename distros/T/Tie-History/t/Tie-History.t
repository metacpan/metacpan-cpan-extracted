use Test::More tests => 50;
use strict;
use warnings;
BEGIN { use_ok('Tie::History') };

### Scalar tests
my $scalar;
ok(my $scalar_tobj = tie($scalar, 'Tie::History'), 'Actual tie of scalar');
ok($scalar = 'This is a test', 'Entering data');
is($scalar, 'This is a test', 'Retreving data');
is($scalar_tobj->current, 'This is a test', '->current()');
ok($scalar_tobj->commit, '->commit()');
is($scalar_tobj->{PREVIOUS}[0], 'This is a test', 'Commited data is there');
$scalar = "this is a new test";
$scalar_tobj->commit;
is($scalar_tobj->previous, 'This is a test', '->previous()');
is($scalar_tobj->get(0), 'This is a test', '->get(0)');
is($scalar_tobj->get(1), 'this is a new test', '->get(1)');
is_deeply($scalar_tobj->getall, ['This is a test', 'this is a new test'], '->getall()');
ok($scalar_tobj->revert, '->revert');
is($scalar, 'This is a test', 'revert worked');

{
  no warnings;
  my $test;
  my $test_tobj = tie($test, 'Tie::History');
  
  if($test_tobj->previous()) {
    fail("->previous on empty tie");
  }
  else {
    pass("->previous on empty tie");
  }

  if($test_tobj->commit()) {
    fail("->commit on empty value");
  }
  else {
    pass("->commit on empty value");
  }

  $test = "value";
  $test_tobj->commit;
  if ($test_tobj->commit) {
    fail("->commit on previous commit");
  }
  else {
    pass("->commit on previous commit");
  }
  $test = "value";
  if($test_tobj->commit) {
    fail("->commit on same value as previous");
  }
  else {
    pass("->commit on same value as previous");
  }
}

### Array tests
my @array;
ok(my $array_tobj = tie(@array, 'Tie::History'), 'Actual tie of array');
ok(@array = qw/one two three/, 'Entering data');
is(scalar(@array), 3, 'scalar(@array)');
is_deeply($array_tobj->current(), ['one', 'two', 'three'], '->current()');
ok($array_tobj->commit, '->commit()');
is_deeply($array_tobj->{PREVIOUS}[0], ['one', 'two', 'three'], 'Commited data is there');
@array = qw/three two four/;
$array_tobj->commit;
is_deeply($array_tobj->previous, ['one', 'two', 'three'], '->previous');
is_deeply($array_tobj->get(0), ['one', 'two', 'three'], '->get(0)');
is_deeply($array_tobj->get(1), ['three', 'two', 'four'], '->get(1)');
is_deeply($array_tobj->getall, [['one', 'two', 'three'],['three', 'two', 'four']], '->getall()');
is(push(@array, 'this'), 4, 'push()');
is(pop(@array), 'this', 'pop()');
is(shift(@array), 'three', 'shift()');
is(unshift(@array, 'other'), 3, 'unshift()');
@array = qw/one two three four five six seven eight nine ten/;
is(splice(@array, -1), 'ten', 'splice(@array, -1)');
is(splice(@array, 0, 1), 'one', 'splice(@array, 0, 1)');
#TODO add more splice tests

{
  no warnings;
  my @test;
  my $test_tobj = tie(@test, 'Tie::History');
  
  if($test_tobj->previous()) {
    fail("->previous on empty tie");
  }
  else {
    pass("->previous on empty tie");
  }

  if($test_tobj->commit()) {
    fail("->commit on empty value");
  }
  else {
    pass("->commit on empty value");
  }

  @test = qw/value of array/;
  $test_tobj->commit;
  if ($test_tobj->commit) {
    fail("->commit on previous commit");
  }
  else {
    pass("->commit on previous commit");
  }
  @test = qw/value of array/;
  if($test_tobj->commit) {
    fail("->commit on same value as previous");
  }
  else {
    pass("->commit on same value as previous");
  }
}

### Hash tests
my %hash;
ok(my $hash_tobj = tie(%hash, 'Tie::History'), 'Actual tie of hash');
ok($hash{'key'} = 'value', 'Entering data');
is_deeply($hash_tobj->current(), {'key' => 'value'}, '->current()');
ok($hash_tobj->commit, '->commit()');
is_deeply($hash_tobj->{PREVIOUS}[0], {'key' => 'value'}, 'Commited data is there');
$hash{newkey} = 'newvalue';
$hash_tobj->commit;
is_deeply($hash_tobj->previous, {'key' => 'value'}, '->previous');
is_deeply($hash_tobj->get(0), {'key' => 'value'}, '->get(0)');
is_deeply($hash_tobj->get(1), {'key' => 'value', 'newkey' => 'newvalue'}, '->get(1)');
is_deeply($hash_tobj->getall, [{'key' => 'value'}, {'key' => 'value', 'newkey' => 'newvalue'}], '->getall()');

{
  no warnings;
  my %test;
  my $test_tobj = tie(%test, 'Tie::History');
  
  if($test_tobj->previous()) {
    fail("->previous on empty tie");
  }
  else {
    pass("->previous on empty tie");
  }

  if($test_tobj->commit()) {
    fail("->commit on empty value");
  }
  else {
    pass("->commit on empty value");
  }

  $test{key} = "value";
  $test_tobj->commit;
  if ($test_tobj->commit) {
    fail("->commit on previous commit");
  }
  else {
    pass("->commit on previous commit");
  }
  $test{key} = "value";
  if($test_tobj->commit) {
    fail("->commit on same value as previous");
  }
  else {
    pass("->commit on same value as previous");
  }
}

