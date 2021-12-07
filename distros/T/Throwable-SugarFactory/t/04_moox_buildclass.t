use strictures 2;

use Test::More;
use Test::Fatal;

use MooX::BuildClass;

{ package TestRole; use Moo::Role }
{ package TestClass; use Moo }

BuildClass Thing => install => [ foo => sub { "foo" } ];
is Thing->new->foo, "foo";
ok $INC{"Thing.pm"};

ok exception { BuildClass "Thing" };

BuildClass Thing2 => install => [ foo => sub { "foo" } ],
  around          => [ foo   => sub   { "foo2" } ];
is Thing2->new->foo, "foo2";

BuildClass Thing3 => has => [ foo => is => ro => default => "foo5" ];
is Thing3->new->foo, "foo5";

BuildClass Thing4 => has => [ ifoo => is => rw => default => "foo5" ],
  install => [ foo => sub { shift->ifoo } ],
  before  => [ foo => sub { shift->ifoo( "foo3" ) } ];
is Thing4->new->foo, "foo3";

BuildClass Thing5 => has => [ ifoo => is => rw => default => "foo5" ],
  install => [ foo => sub { shift->ifoo } ],
  after   => [ foo => sub { shift->ifoo( "foo4" ) } ];
my $t = Thing5->new;
$t->foo;
is $t->foo, "foo4";

BuildClass Thing6 => extends => "TestClass";
ok Thing6->new->isa( "TestClass" );

BuildClass Thing7 => with => "TestRole";
ok Thing7->new->does( "TestRole" );

done_testing;
