use Test::More tests => 4;
use Test::Pockito::Exported;

use warnings;
use strict;


setup("Mock");
my $mock = mock("Execute");

stop();

when( $mock->execute(1) )->execute( sub { ok(1, "execute called properly"); 2 } );
when( $mock->execute(1) )->execute( sub { ok(1, "second execute called properly"); 3 } );

go();

ok( $mock->execute(1) == 2, "First result from execute succeeded" );
ok( $mock->execute(1) == 3, "Second result from execute succeeded" );

package Execute;
use Test::More;

sub execute { }
