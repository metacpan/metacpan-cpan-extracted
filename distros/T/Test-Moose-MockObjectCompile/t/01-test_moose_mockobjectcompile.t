use Test::More;
use Test::Exception;
use Test::Moose;

package Test::Role;
use Moose::Role;

1;
package Test::Role1;
use Moose::Role;

1;
package Test::Role2;
use Moose::Role;

requires 'Baz';
excludes 'Test::Role1';

1;
package main;

BEGIN: {
    plan tests => 10;

    use_ok('Test::Moose::MockObjectCompile');
}

{
    has_attribute_ok('Test::Moose::MockObjectCompile', 'roles');
    has_attribute_ok('Test::Moose::MockObjectCompile', 'extend');
    
    can_ok('Test::Moose::MockObjectCompile', qw{_build_code compile mock});
    
}

my $mock;
{
    ok($mock = Test::Moose::MockObjectCompile->new(), 'Instantiated a mock Moose Object');
    
    $mock->roles([qw{Bar Baz}]);
    dies_ok {$mock->compile} 'compile with fictional roles dies';

    #test that the compile succeeds when it should
    my $mock2 = Test::Moose::MockObjectCompile->new({package => 'Tester'});
    $mock2->roles([qw{Test::Role}]);
    lives_ok {$mock2->compile} 'compile of valid role requirement succeeds';
    $mock2->roles([qw{Test::Role2}]);
    dies_ok {$mock2->compile} 'compile of valid role with missing required method dies';
    $mock2->mock('Baz');
    lives_ok {$mock2->compile} 'compile of valid role with required method succeeds';
    $mock->roles([qw{Test::Role2 Test::Role1}]);
    $mock->mock('Baz');
    dies_ok {$mock->compile} 'compile of role with clashing roles dies';
}
