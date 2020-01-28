use strict;
use warnings;
use lib 't/';

use Test::More tests => 5;

BEGIN {
  use_ok('Test::Mock::Simple');
}

my $mock = Test::Mock::Simple->new(
    allow_new_methods => 1,
    module            => 'Namespace::Within',
    module_location   => 'TestModule.pm',
);
$mock->add(bar => sub { return 'foo'; });

my $test = Namespace::Within->new();

ok($test->can('foo'), 'Module is able to call method foo');
ok($test->can('bar'), 'Module is able to call method bar');
is($test->foo, 'bar', 'Real method foo');
is($test->bar, 'foo', 'Mocked method bar');
