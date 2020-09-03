use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	use namespace::autoclean;
	
	abstract class Foo;
	class Bar {
		extends Foo;
	}
}

ok( !MyApp->can('new_foo') );
ok(  MyApp->can('new_bar') );
ok( !MyApp::Foo->can('new') );
ok(  MyApp::Bar->can('new') );

my $obj = MyApp->new_bar;

isa_ok($obj, 'MyApp::Bar');
isa_ok($obj, 'MyApp::Foo');

done_testing;

