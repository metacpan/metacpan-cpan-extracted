use Test::More ;
use IO::String;

use Test::Pockito::Exported;

use warnings;
use strict;


{
    setup("Foo");
    my $expected_pre_call_output = qq!Foo::Case12::
\tfoo(hello,bonjour);
\tfoo(go away,beat it);
Foo::Case13::
\tbar(warble);
\tbar();
!;
    my $buffer1       = "";
    my $buffer_handle = IO::String->new($buffer1);

    my $mock_foo = mock("Case12");
    my $mock_bar = mock("Case13");

    when( $mock_foo->foo( 'hello',   'bonjour' ) )->then(3);
    when( $mock_foo->foo( 'go away', 'beat it' ) )->then(2);
    when( $mock_bar->bar('warble') )->then(3);
    when( $mock_bar->bar() )->then();

    report_expected_calls($buffer_handle);

    ok( $buffer1 eq $expected_pre_call_output, "Expected calls reported." );

    my $buffer2 = "";
    $buffer_handle = IO::String->new($buffer2);

    $mock_foo->foo( 'hello',   'bonjour' );
    $mock_foo->foo( 'go away', 'beat it' );
    $mock_bar->bar('warble');
    $mock_bar->bar();

    report_expected_calls($buffer_handle);

    ok( $buffer2 eq "", "No expected calls, no output." );

    package Case12;

    sub foo { }

    package Case13;

    sub bar { }
}
done_testing()
