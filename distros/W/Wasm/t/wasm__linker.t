use 5.008004;
use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use Capture::Tiny qw( capture );
use lib 'corpus/wasm__linker/lib';
use YAML qw( Dump );

is( dies { require Module2 }, U(), 'require Module2');
is( dies { require Module3 }, match qr/module required by WebAssembly at.*Module3\.wat/, 'require Module3');

is
  [ capture { Module2::run() } ],
  ["Hello, world!\n", ''],
  'run it!',
;

is( dies { require Foo::Bar::X2 }, U(), 'require Foo::Bar::X2');
is( $Foo::Bar::X1::x1, 42, "global x1 is set to 42");
is( Foo::Bar::X2::get_x1(), 42, "get_x1() = 42");
Foo::Bar::X2::inc_x1();
is( Foo::Bar::X2::get_x1(), 43, "get_x1() = 43");
is( $Foo::Bar::X1::x1, 43, "global x1 is set to 43");

is( dies { require Foo::Bar::X4 }, U(), 'require Foo::Bar::X4');
is( $Foo::Bar::X3::x3, 42, "global x3 is set to 42");
is( Foo::Bar::X4::get_x3(), 42, "get_x3() = 42");
Foo::Bar::X4::inc_x3();
is( $Foo::Bar::X3::x3, 43, "global x3 is set to 43");
is( Foo::Bar::X4::get_x3(), 43, "get_x3() = 43");

is
  [ capture { Foo::Bar::X4::run() } ],
  ["hello, world!\n", ''],
  'run it to Perl!',
;

is( dies { require Foo::Bar::X5 }, U(), 'require Foo::Bar::X5');
Foo::Bar::X5::inc_x3();
is( $Foo::Bar::X3::x3, 44, "global x3 is set to 44");
is( Foo::Bar::X4::get_x3(), 44, "get_x3() = 44");
is( Foo::Bar::X5::get_x3(), 44, "get_x3() = 44");

note Dump(do { no warnings 'once'; \%Wasm::WASM });

done_testing;
