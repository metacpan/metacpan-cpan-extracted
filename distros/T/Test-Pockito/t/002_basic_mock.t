use Test::More tests => 44;
use Test::Pockito;
use IO::String;

use warnings;
use strict;

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case1");

    $pocket->when( $mock->hello("are you there?") )->then("hi!");
    $pocket->when( $mock->hello("are you there?") )->then("hello!");

    ok( $mock->hello("are you there?") eq "hi!", "First in 2 calls correct" );
    ok( $mock->hello("are you there?") eq "hello!", "Last in 2 calls correct" );

    package Case1;

    sub hello { }
}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case2");

    ok( $mock->can("hello"),   "Propper method discovery" );
    ok( !$mock->can("hello1"), "Propper method discovery (missing method)" );
    ok( $mock->isa('Case2'),   "Proper subclassing" );

    package Case2;

    sub hello { }
}
{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case3");

    ok( ref $mock eq "Foo::Case3", "Create a mock with a namespace" );

    package Foo;
}
{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case4");

    $pocket->when( $mock->hello("are you there?") )->then("hi!");

    ok( $mock->hello("are you there?") eq "hi!", "Mock returned scalar" );

    package Case4;

    sub hello { }
}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case5");

    $pocket->when( $mock->hello("are you there?") )->then( "hi!", "hello!" );

    my ( $a, $b ) = $mock->hello("are you there?");

    ok( $a eq "hi!",    "Mock returned first part of array correctly" );
    ok( $b eq "hello!", "Mock returned second part of array correctly" );

    package Case5;

    sub hello { }
}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case6");

    $pocket->when( $mock->hello("are you there?") )->then();

    my ($foo) = $mock->hello("are you there?");

    ok( !defined $foo, "Mock method in null context" );

    package Case6;

    sub hello { }
}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case7");

    $pocket->when( $mock->hello("are you there?") )->then(1);

    my ($foo) = $mock->hello("are you there?");

    ok( $foo == 1, "AUTOLOAD works" );

    package Case7;

    sub AUTOLOAD { }

}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case7");

    $pocket->when( $mock->string("are you there?") )->then("string");
    $pocket->when( $mock->number("are you there?") )->then(9);

    my ($string) = $mock->string("are you there?");
    my ($number) = $mock->number("are you there?");

    ok( $string eq "string", "string comparison works" );
    ok( $number == 9, "number comparison works" );

    package Case7;

    sub string { }
    sub number { }

}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case8");

    $pocket->when( $mock->hi(1) )->then(2);
    $pocket->when( $mock->hi )->then(3);

    ok( $mock->hi(1) == 2, "Parameter call worked" );
    ok( $mock->hi == 3,    "Unparametered call worked" );

    package Case8;

    sub hi { }
}

{
    my $pocket = Test::Pockito->new( "Foo", \&Case10Matcher );
    my $mock = $pocket->mock("Case10");

    $pocket->when( $mock->rawr(2) )->default(3);

    ok( ( $mock->rawr(1) == 3 ), "Matcher performed as expected" );

    sub Case10Matcher {
        my $package        = shift;
        my $method         = shift;
        my $param_found    = shift;
        my $param_expected = shift;
        my $result         = shift;

        ok( "Foo::Case10" eq $package, "Package name passed as expected." );
        ok( "rawr"        eq $method,  "Method name passed as expected." );
        ok( $$param_expected[0] == 2, "Expected param passed properly" );

        return 1, 3 if $$param_found[0] == 1;
    }

    package Case10;

    sub rawr { }
}

{
    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("Case11");

    $pocket->when( $mock->hi( 'hello',   'bonjour' ) )->then(3);
    $pocket->when( $mock->hi( 'go away', 'beat it' ) )->then(2);

    my $missing_calls = $pocket->expected_calls;

    ok( $missing_calls->{'Foo::Case11'}{'hi'}[0]->{'params'}->[0] eq 'hello',
        "call 1, param 1 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[0]->{'params'}->[1] eq 'bonjour',
        "call 1, param 2 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[0]->{'result'}->[0] == 3,
        "call 1, expected result matches" );

    ok( $missing_calls->{'Foo::Case11'}{'hi'}[1]->{'params'}->[0] eq 'go away',
        "call 2, param 1 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[1]->{'params'}->[1] eq 'beat it',
        "call 2, param 2 report matches" );
    ok( $missing_calls->{'Foo::Case11'}{'hi'}[1]->{'result'}->[0] == 2,
        "call 2, expected result matches" );

    ok( $mock->hi( 'hello', 'bonjour' ) == 3, "other call after report works" );
    ok( $mock->hi( 'go away', 'beat it' ) == 2,
        "mock call after report works" );

    ok( scalar keys %{ $pocket->expected_calls } == 0,
        "Mock removed expectation" );

    package Case11;

    sub hi { }
}

{
    my $expected_pre_call_output = qq!Foo::Case12::
\tfoo(hello,bonjour);
\tfoo(go away,beat it);
Foo::Case13::
\tbar(warble);
\tbar();
!;
    my $buffer1       = "";
    my $buffer_handle = IO::String->new($buffer1);

    my $pocket   = Test::Pockito->new("Foo");
    my $mock_foo = $pocket->mock("Case12");
    my $mock_bar = $pocket->mock("Case13");

    $pocket->when( $mock_foo->foo( 'hello',   'bonjour' ) )->then(3);
    $pocket->when( $mock_foo->foo( 'go away', 'beat it' ) )->then(2);
    $pocket->when( $mock_bar->bar('warble') )->then(3);
    $pocket->when( $mock_bar->bar() )->then();

    $pocket->report_expected_calls($buffer_handle);

    ok( $buffer1 eq $expected_pre_call_output, "Expected calls reported." );

    my $buffer2 = "";
    $buffer_handle = IO::String->new($buffer2);

    $mock_foo->foo( 'hello',   'bonjour' );
    $mock_foo->foo( 'go away', 'beat it' );
    $mock_bar->bar('warble');
    $mock_bar->bar();

    $pocket->report_expected_calls($buffer_handle);

    ok( $buffer2 eq "", "No expected calls, no output." );

    package Case12;

    sub foo { }

    package Case13;

    sub bar { }
}

{
    my $pocket = Test::Pockito->new("Tmnt");
    my $mock = $pocket->mock( "Case14", "b" );

    my $buffer2       = "";
    my $buffer_handle = IO::String->new($buffer2);

    $pocket->when( $mock->a )->then(1);

    ok( $mock->a == 1, "mock call on partial mock ok" );
    ok( $mock->b == 3, "real call to original method ok" );

    $pocket->report_expected_calls($buffer_handle);

    ok( $buffer2 eq "",
        "Partial mock left behind no expectations as expectred." );

    package Case14;
    use Test::More;

    sub a { not_ok("Mocked out method should not have been called."); }
    sub b { ok( 1, "Mocked out method call, called as expected" ); 3 }
}

{
    my $pocket = Test::Pockito->new("Mock");
    my $mock   = $pocket->mock("Edge1");

    $pocket->when( $mock->a() )->default(1);
    $pocket->when( $mock->a(2) )->default(2);

    ok( $mock->a == 1,    "Initial default works." );
    ok( $mock->a(2) == 2, "Initial default with a param works." );

    $pocket->when( $mock->a() )->default(2.1);

    ok( $mock->a(2) == 2, "Default with param continues to work" );
    ok( $mock->a == 2.1,  "new default works." );
    ok( $mock->a == 2.1,  "new default really works" );

    package Edge1;

    sub a { }
}

{
    my $pocket = Test::Pockito->new("Mock");
    my $mock   = $pocket->mock("CarpCall");

    $pocket->{'warn'} = 1;

    local $SIG{__WARN__} = sub {
        ok(
            $_[0] =~
/^Mock call not found to CarpCall->a at t\/002_basic_mock.t line \d+$/,
            "Warning properly issued."
        );
    };

    $mock->a;

    package CarpCall;
    use Test::More;

    sub a { }
}

{
    my $pocket = Test::Pockito->new("Mock");
    my $mock   = $pocket->mock("DestroyCall");

    $pocket->{'warn'} = 1;

    local $SIG{__WARN__} = sub {
        not_ok( "Destroy should never be considered." );
    };

    $mock->DESTROY;

    package DestroyCall;

    sub DESTROY { }
}

{
   my $pocket = Test::Pockito->new("Mock");
   my $mock = $pocket->mock("Execute");


   # one mock, two calls, won't result in $mock->execute being run twice
   # so no warning should ever occur. proof that 'go' doesn't affect things

   $pocket->{'go'} = 1;
   local $SIG{__WARN__} = sub { not_ok(1, "no warning from different params") };

   $pocket->when( $mock->execute(1) )->execute( sub { 2 } );
   $pocket->when( $mock->execute(2) )->execute( sub { 3 } );


   ok( $mock->execute(1) == 2, "First result from execute succeeded" );
   ok( $mock->execute(2) == 3, "Second result from execute succeeded" );

   package Execute;
   use Test::More;

   sub execute { }
}


{
   my $pocket = Test::Pockito->new("Mock");
   my $mock = $pocket->mock("ExecuteWarning");

   $SIG{__WARN__} = sub { ok( $_[0]=~/when called after an executable mock result occured. set ->{'go'} = 1 after all mocks are setup.*/, "error message on when after execute set reported"); };

   $pocket->{'go'} = 0;
   $pocket->when( $mock->execute(1) )->execute( sub { ok(1, "execute called properly"); 2 } );
   $pocket->{'go'} = 1;
   $pocket->when( $mock->execute(1) )->execute( sub { not_ok("shouldn't have gotten here"); } );


   package ExecuteWarning;
   use Test::More;

   sub execute { }
}

{
   my $pocket = Test::Pockito->new("Mock");
   my $mock = $pocket->mock("ExecuteOk");

   $pocket->{'go'} = 0;

   $pocket->when( $mock->execute(1) )->execute( sub { ok(1, "execute called properly"); 2 } );
   $pocket->when( $mock->execute(1) )->execute( sub { ok(1, "second execute called properly"); 3 } );

   $pocket->{'go'} = 1;

   package ExecuteOk;
   use Test::More;

   sub execute { }
}
