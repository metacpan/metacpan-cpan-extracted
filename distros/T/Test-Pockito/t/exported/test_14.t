use Test::More tests => 2;
use Test::Pockito::Exported;

use warnings;
use strict;

setup("Mock");
my $mock = mock("ExecuteWarning");

$SIG{__WARN__} = sub { ok( $_[0]=~/when called after an executable mock result occured. set ->{'go'} = 1 after all mocks are setup.*/, "error message on when after go set reported"); };

when( $mock->execute(1) )->execute( sub { ok(1, "execute called properly"); 2 } );
go();
when( $mock->execute(1) )->execute( sub { not_ok("shouldn't have gotten here"); } );


package ExecuteWarning;
use Test::More;

sub execute { }
