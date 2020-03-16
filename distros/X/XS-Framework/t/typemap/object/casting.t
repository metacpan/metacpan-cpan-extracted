use 5.012;
use warnings;
use lib 't';
use MyTest;

my $objA = MyTest::ObjectA->new;
my $objB = MyTest::ObjectB->new;

throws_ok( sub { MyTest::ObjectA::check($objB) }, qr|\QMyTest::ObjectB' to expected 'MyTest::ObjectA' (C++ type 'ObjectA*')\E| ) ;
throws_ok( sub { MyTest::ObjectB::check($objA) }, qr|\QMyTest::ObjectA' to expected 'MyTest::ObjectB' (C++ type 'ObjectB*')\E| ) ;

done_testing;
