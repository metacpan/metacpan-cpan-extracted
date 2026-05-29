use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ($src) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'identifier-underscore.zzs' );

	return $runtime->evaluate($ast);
}

my $src_underscore_var = <<'SRC';
let _thing := 42;
_thing;
SRC

is eval_src($src_underscore_var), 42,
	'leading underscore variable names are legal';

my $src_underscore_function = <<'SRC';
let _thing := 42;
function _blah () {
	return _thing;
}
_blah();
SRC

is eval_src($src_underscore_function), 42,
	'leading underscore function names and references are legal';

my $src_underscore_type_names = <<'SRC';
trait _Greeter {
	method hello () {
		return 8;
	}
}
class _Thing with _Greeter;
let _obj := new _Thing();
_obj.hello();
SRC

is eval_src($src_underscore_type_names), 8,
	'leading underscore class and trait names are legal';

my $src_underscore_digit = <<'SRC';
let _1 := 7;
_1;
SRC

is eval_src($src_underscore_digit), 7,
	'identifier _1 is legal';

like dies {
	$parser->parse(<<'SRC', 'underscore-alone.zzs');
let _ := 9;
SRC
}, qr/Expected IDENT/,
	'underscore alone is not a legal identifier name';

like dies {
	$parser->parse(<<'SRC', 'concat-followed-by-word-char.zzs');
let x := "a"_foo;
SRC
}, qr/Expected OP/,
	"'_' concat operator cannot be directly followed by word chars";

done_testing;
