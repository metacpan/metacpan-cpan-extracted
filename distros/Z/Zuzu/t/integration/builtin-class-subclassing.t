use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'builtin-class-subclassing.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 3, 'builtin smoke: core constructors remain available';
let a := new Array( 1, 2, 3 );
a.length();
SRC

is eval_src(<<'SRC'), 'boom', 'builtin smoke: Exception subclass stays catch-compatible';
class BailOutException extends Exception;
try {
	throw new BailOutException( message: "boom" );
}
catch ( Exception e ) {
	e{message};
}
SRC

is eval_src(<<'SRC'), 'boom|Exception: boom|yes', 'Exception exposes raw message method';
try {
	throw new Exception( message: "boom" );
}
catch ( Exception e ) {
	let can_message := "no";
	if ( e can message ) {
		can_message := "yes";
	}
	e.message() _ "|" _ e.to_String() _ "|" _ can_message;
}
SRC

like dies {
	eval_src(<<'SRC');
let e := new Exception( message: "boom" );
e.file();
SRC
}, qr/Unknown method 'file'/, 'Exception data slots are not zero-arg member-call fallbacks';

is eval_src(<<'SRC'), 1, 'builtin smoke: collection subclasses preserve custom methods';
class SpecialBag extends Bag {
	method is_special () {
		return true;
	}
}
let sb := new SpecialBag( 1, 2, 3 );
if ( sb.is_special() ) {
	1;
}
else {
	0;
}
SRC

done_testing;
