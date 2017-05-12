use strictures 2;

use Test::More;
use Test::Fatal;

use MooX::BuildClass;
use MooX::BuildRole;

{ package TestRole;  use Moo::Role }
{ package TestClass; use Moo }

sub class { my $n = shift; BuildClass $n => with => $n . "Role" }

BuildRole ThingRole => install => [ foo => sub { "foo" } ];
class "Thing";
is Thing->new->foo, "foo";
ok $INC{"ThingRole.pm"};

ok exception { BuildRole "ThingRole" };

BuildRole Thing2Role => install => [ foo => sub { "foo" } ],
  around             => [ foo   => sub   { "foo2" } ];
class "Thing2";
is Thing2->new->foo, "foo2";

BuildRole Thing3Role => has => [ foo => is => ro => default => "foo5" ];
class "Thing3";
is Thing3->new->foo, "foo5";

BuildRole Thing4Role => has => [ ifoo => is => rw => default => "foo5" ],
  install => [ foo => sub { shift->ifoo } ],
  before  => [ foo => sub { shift->ifoo( "foo3" ) } ];
class "Thing4";
is Thing4->new->foo, "foo3";

BuildRole Thing5Role => has => [ ifoo => is => rw => default => "foo5" ],
  install => [ foo => sub { shift->ifoo } ],
  after   => [ foo => sub { shift->ifoo( "foo4" ) } ];
class "Thing5";
my $t = Thing5->new;
$t->foo;
is $t->foo, "foo4";

BuildRole Thing7Role => with => "TestRole";
class "Thing7";
ok Thing7->new->does( "TestRole" );

done_testing;
