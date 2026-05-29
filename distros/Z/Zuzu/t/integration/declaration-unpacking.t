use utf8;
use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'declaration-unpacking.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'let unpacking supports shorthand keys';
let { host, port } := { host: "127.0.0.1", port: 1234 };
host eq "127.0.0.1" and port = 1234;
SRC

is eval_src(<<'SRC'), 1, 'aliases, typed aliases, strings, templates, and computed keys work';
let suffix := "id";
let {
	"for": for_id,
	`user-${suffix}`: String user_id,
	("content-type"): content_type,
} := { "for": 7, "user-id": "ada", "content-type": "text/plain" };
for_id = 7 and user_id eq "ada" and content_type eq "text/plain";
SRC

is eval_src(<<'SRC'), 1, 'typed shorthand and defaults work';
let { String host := "localhost", Number port := 8080 } := { port: 9000 };
host eq "localhost" and port = 9000;
SRC

is eval_src(<<'SRC'), 1, 'defaults are lazy and used only when the key is absent';
let calls := 0;
function fallback () {
	calls := calls + 1;
	return "fallback";
}
function explode () {
	die "default should not run";
}
let { present := explode(), missing := fallback() } := { present: null };
present ≡ null and missing eq "fallback" and calls = 1;
SRC

is eval_src(<<'SRC'), 1, 'source expression is evaluated once';
let calls := 0;
function source () {
	calls := calls + 1;
	return { a: 1, b: 2 };
}
let { a, b } := source();
a = 1 and b = 2 and calls = 1;
SRC

is eval_src(<<'SRC'), 1, 'key expressions resolve before unpacked locals are declared';
let key := "chosen";
{
	let { (key): key } := { chosen: 5 };
	key = 5;
}
SRC

is eval_src(<<'SRC'), 1, 'missing keys bind null without defaults';
let { missing } := {};
missing ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'PairList unpacking uses first-match get semantics';
let { a } := {{ a: 1, a: 2 }};
a = 1;
SRC

is eval_src(<<'SRC'), 1, 'per-binding weak storage is honoured';
class Box {}
let owner := new Box();
let { owner: parent but weak } := { owner: owner };
let alive := parent ≢ null;
owner := null;
alive and parent ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'const unpacking preserves const mutability';
const { a } := { a: 1 };
a;
SRC

like dies {
	$parser->parse(<<'SRC', 'const-unpack-reassign.zzs');
const { a } := { a: 1 };
a := 2;
SRC
}, qr/Cannot assign to const 'a' \(compile-time\)/,
	'const unpacked bindings reject reassignment at compile time';

like dies {
	$parser->parse(<<'SRC', 'duplicate-unpack.zzs');
let { a, b: a } := { a: 1, b: 2 };
SRC
}, qr/Duplicate unpacked binding 'a'/,
	'duplicate local names are compile-time errors';

like dies {
	$parser->parse(<<'SRC', 'unpack-default-new-name.zzs');
let { a := 1, b := a } := {};
SRC
}, qr/Use of undeclared identifier 'a' \(compile-time\)/,
	'unpack defaults do not resolve newly declared names';

like dies {
	eval_src('let { a } := 42;');
}, qr/Declaration unpacking expects Dict or PairList, got Number/,
	'non-Dict and non-PairList sources fail clearly';

like dies {
	eval_src('let { Number n } := { n: "nope" };');
}, qr/TypeException: 'n' must be Number, got String/,
	'unpacked typed bindings keep normal type checks';

like dies {
	eval_src(<<'SRC');
let source := { a: 1 };
let x;
({ a: x }) := source;
SRC
}, qr/Invalid assignment target/,
	'assignment destructuring outside declarations remains invalid';

done_testing;
