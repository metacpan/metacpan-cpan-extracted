use Test2::V0;

use Encode qw( decode );
use File::Basename qw( dirname );
use File::Spec;
use File::Temp qw( tempdir tempfile );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use Zuzu::Parser;
use Zuzu::Tidy;

my $messy = <<'SRC';
function foo(a,b){if(a){say "x"}else{say "y"}}
let arr:=[1, n+1]
while(let line:=file.get_line){say line}
=pod
This pod should stay untouched.
=cut
foo.mymethod("foo")
foo.mymethod("abcdefghijklmnopqrstuvwxyz")
foo.mymethod(some_long_function_name)
foo.mymethod(some_long_function_name())
SRC

my $tidied = Zuzu::Tidy->tidy( $messy, filename => 'sample.zzs' );

my $expected = <<'OUT';
function foo ( a, b ) {
	if (a) {
		say "x";
	}
	else {
		say "y";
	}
}

let arr := [ 1, n + 1 ];
while ( let line := file.get_line ) {
	say line;
}

=pod
This pod should stay untouched.
=cut

foo.mymethod("foo");
foo.mymethod( "abcdefghijklmnopqrstuvwxyz" );
foo.mymethod(some_long_function_name);
foo.mymethod( some_long_function_name() );
OUT

is $tidied, $expected, 'tidy applies spacing, braces, and semicolon rules';

my $vertical_src = <<'SRC';
function alpha(){say "one"}
function beta(){
let x:=1
let y:=2
return x+y
}
class Demo{
method tiny(){say "tiny"}
method big(){
let a:=1
let b:=2
let c:=3
let d:=4
return a+b+c+d
}
}
while(flag){
step1()
step2()
step3()
step4()
step5()
}
function with_comment(){
let n:=1
/*line one
line two*/
return n
}
SRC

my $vertical_tidy = Zuzu::Tidy->tidy( $vertical_src, filename => 'vertical.zzs' );

like(
	$vertical_tidy,
	qr/\}\n\nfunction beta \(\) \{/,
	'adds blank line before a function statement',
);
like(
	$vertical_tidy,
	qr/\n\}\n\nclass Demo \{/,
	'adds blank line after a function when not at block end',
);
like(
	$vertical_tidy,
	qr/class Demo \{\n\n\tmethod tiny \(\) \{/,
	'adds blank line before a method statement',
);
like(
	$vertical_tidy,
	qr/\t\}\n\n\tmethod big \(\) \{/,
	'adds blank line after a method when not at block end',
);
like(
	$vertical_tidy,
	qr/\n\}\n\nwhile \(flag\) \{/,
	'adds blank line before a 5+ line statement block',
);
like(
	$vertical_tidy,
	qr/\treturn x \+ y;\n\}\n\nclass Demo \{/,
	'adds blank line after a 5+ line block',
);
like(
	$vertical_tidy,
	qr/\tlet y := 2;\n\n\treturn x \+ y;/,
	'adds blank line before a final return in function',
);
like(
	$vertical_tidy,
	qr/\tlet n := 1;\n\n\t\/\*line one\n\tline two\*\/\n\n\treturn n;/,
	'adds blank line before multiline comments and preserves comment block',
);
my $short_return = Zuzu::Tidy->tidy(
	"function shorty(){return 1}\n",
	filename => 'short.zzs'
);
like(
	$short_return,
	qr/function shorty \(\) \{\n\treturn 1;\n\}\n/,
	'does not force a blank line before final return in very short functions',
);

my $chain_tidy = Zuzu::Tidy->tidy(
	"4▷1+(2*^^)▷say(^^+^^)\n",
	filename => 'chain.zzs',
);
is(
	$chain_tidy,
	"4\n\t▷ 1 + ( 2 * ^^ )\n\t▷ say( ^^ + ^^ );\n",
	'formats Unicode chain operators vertically',
);

my $chain_alias_tidy = Zuzu::Tidy->tidy(
	"4|>1+(2*^^)|>say(^^+^^)\n",
	filename => 'chain-alias.zzs',
);
is(
	$chain_alias_tidy,
	"4\n\t|> 1 + ( 2 * ^^ )\n\t|> say( ^^ + ^^ );\n",
	'formats ASCII chain operator aliases vertically without rewriting them',
);

my $canonical_operator_src = <<'SRC';
from foo/bar import *;
let a:=2*3/4
a*=5
a/=2
let cmp:=a<=10 and a>=1 or a<=>3 == 0 != false
let sets:=<<1>> union <<2>> intersection <<2>>
let diff:=<<1,2>> \ <<2>>
let member:=1 in <<1>>
let divisibility:=2 divides 6 and 4 ∤ 6
let expanded_logic:=a nand? b nor? c xnor? d onlyif? e butnot? f
for (let item in [1,2]){say item}
4|>1+(2*^^)|>say(^^+^^)
SRC

my $canonical_default_tidy = Zuzu::Tidy->tidy(
	$canonical_operator_src,
	filename => 'canonical-default.zzs',
);
like $canonical_default_tidy, qr/\nlet a := 2 \* 3 \/ 4;\n/,
	'preserves non-canonical operator spellings by default';
like $canonical_default_tidy, qr/\n\t\|> 1 \+ \( 2 \* \^\^ \)/,
	'preserves ASCII chain aliases by default';

my $canonical_operator_tidy = Zuzu::Tidy->tidy(
	$canonical_operator_src,
	filename => 'canonical-operators.zzs',
	canonical_operators => 1,
);
like $canonical_operator_tidy, qr/\Afrom foo\/bar import \*;\n/,
	'canonical operator mode preserves import paths and wildcards';
like $canonical_operator_tidy, qr/\nlet a := 2 × 3 ÷ 4;\n/,
	'canonical operator mode rewrites arithmetic operator aliases';
like $canonical_operator_tidy, qr/\na ×= 5;\na ÷= 2;\n/,
	'canonical operator mode rewrites assignment operator aliases';
like $canonical_operator_tidy,
	qr/\nlet cmp := a ≤ 10 ⋀ a ≥ 1 ⋁ a ≶ 3 ≡ 0 ≢ false;\n/,
	'canonical operator mode rewrites comparison and logical aliases';
like $canonical_operator_tidy, qr/\nlet sets := << 1 >> ⋃ << 2 >> ⋂ << 2 >>;\n/,
	'canonical operator mode rewrites named set operators';
like $canonical_operator_tidy, qr/\nlet diff := << 1, 2 >> ∖ << 2 >>;\n/,
	'canonical operator mode rewrites set difference alias';
like $canonical_operator_tidy, qr/\nlet member := 1 ∈ << 1 >>;\n/,
	'canonical operator mode rewrites binary in operator';
like $canonical_operator_tidy, qr/\nlet divisibility := 2 ∣ 6 ⋀ 4 ∤ 6;\n/,
	'canonical operator mode rewrites divisibility aliases';
like $canonical_operator_tidy,
	qr/\nlet expanded_logic := a ⊼\? b ⊽\? c ↔\? d ⊨\? e ⊭\? f;\n/,
	'canonical operator mode rewrites expanded value-preserving logical aliases';
like $canonical_operator_tidy, qr/\nfor \( let item in \[ 1, 2 \] \) \{\n/,
	'canonical operator mode preserves for-loop in syntax';
like $canonical_operator_tidy, qr/\n\t▷ 1 \+ \( 2 × \^\^ \)\n\t▷ say/,
	'canonical operator mode rewrites chain aliases';

my $spacing_src = <<'SRC';
let i:=1
i++
let j:=~i
function takes_optional(options?){return options}
let args:=[]
let spread_call:=takes_optional(... args)
let defaults:={a:1}default{b:2}
let x:=foo{bar}
let y:={{foo:1,bar:2}}
let cfg:={pretty:false,sort_keys:false,color:false,quiet:false,}
let range_arr:=[1...3]
let range_set:=<<1...3>>
let range_bag:=<<<1...3>>>
let arr:=[1,2,3,]
let set_single:=<<1,2,3,>>
let bag_single:=<<<1,2,3,>>>
let arr_force:=[aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,cccccccccccccccccccccccccccccccccccccccc,dddddddddddddddddddddddddddddddddddddddd]
let set_force:=<<aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,cccccccccccccccccccccccccccccccccccccccc,dddddddddddddddddddddddddddddddddddddddd>>
let bag_force:=<<<aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,cccccccccccccccccccccccccccccccccccccccc,dddddddddddddddddddddddddddddddddddddddd>>>
SRC

my $spacing_tidy = Zuzu::Tidy->tidy( $spacing_src, filename => 'spacing.zzs' );
like $spacing_tidy, qr/\ni\+\+;\n/, 'keeps postfix unary punctuation tight';
like $spacing_tidy, qr/\nlet j := ~i;\n/, 'keeps prefix unary punctuation tight';
like $spacing_tidy, qr/function takes_optional \( options\? \) \{/, 'keeps optional marker tight to parameter name';
like $spacing_tidy, qr/\nlet args := \[\];\n/, 'keeps space after := for array initialization';
like $spacing_tidy, qr/\nlet spread_call := takes_optional\(\.\.\.args\);\n/,
	'keeps call spread operator tight to its expression';
like $spacing_tidy, qr/\nlet defaults := \{ a: 1 \} default \{ b: 2 \};\n/,
	'formats default operator spacing';
like $spacing_tidy, qr/\nlet x := foo\{bar\};\n/, 'keeps dict element access tight before {';
like(
	$spacing_tidy,
	qr/\nlet y := \{\{\n\tfoo: 1,\n\tbar: 2,\n\}\};\n/,
	'formats multiline dict literals one item per line with trailing comma',
);
like(
	$spacing_tidy,
	qr/\nlet cfg := \{\n\tpretty: false,\n\tsort_keys: false,\n\tcolor: false,\n\tquiet: false,\n\};\n/,
	'forces multi-line dict literal when source has a trailing comma',
);
like $spacing_tidy, qr/\nlet range_arr := \[ 1 \.\.\. 3 \];\n/,
	'keeps array ranges formatted as ranges';
like $spacing_tidy, qr/\nlet range_set := << 1 \.\.\. 3 >>;\n/,
	'keeps set ranges formatted as ranges';
like $spacing_tidy, qr/\nlet range_bag := <<< 1 \.\.\. 3 >>>;\n/,
	'keeps bag ranges formatted as ranges';
like $spacing_tidy, qr/\nlet arr := \[\n\t1,\n\t2,\n\t3,\n\];\n/,
	'forces multi-line array when source has a trailing comma';
like(
	$spacing_tidy,
	qr/\nlet arr_force := \[\n\ta{40},\n\tb{40},\n\tc{40},\n\td{40},\n\];\n/,
	'formats split arrays one item per line with trailing comma',
);
like $spacing_tidy, qr/\nlet set_single := <<\n\t1,\n\t2,\n\t3,\n>>;\n/,
	'forces multi-line set when source has a trailing comma';
like(
	$spacing_tidy,
	qr/\nlet set_force := <<\n\ta{40},\n\tb{40},\n\tc{40},\n\td{40},\n>>;\n/,
	'formats split sets one item per line with trailing comma',
);
like $spacing_tidy, qr/\nlet bag_single := <<<\n\t1,\n\t2,\n\t3,\n>>>;\n/,
	'forces multi-line bag when source has a trailing comma';
like(
	$spacing_tidy,
	qr/\nlet bag_force := <<<\n\ta{40},\n\tb{40},\n\tc{40},\n\td{40},\n>>>;?\n/,
	'formats split bags one item per line with trailing comma',
);

my $trailing_comma_src = <<'SRC';
function declares(a,b,){return a}
let single_arg:=foo(1,)
let single_arr:=[1,]
let no_trailing:=foo(1,2,3)
let nested_force:=[[1,2,],[3,4,],]
let call_args:=foo(1,2,3,)
let shifted:=a<<b
let mixed:=[a<<b,c]
SRC
my $trailing_comma_tidy = Zuzu::Tidy->tidy( $trailing_comma_src, filename => 'trailing-comma.zzs' );

like $trailing_comma_tidy,
	qr/\Afunction declares \(\n\ta,\n\tb,\n\) \{/,
	'forces multi-line declaration parameter list when source has a trailing comma';
like $trailing_comma_tidy,
	qr/\nlet single_arg := foo\(\n\t1,\n\);\n/,
	'forces multi-line call args for a single-item trailing-comma argument list';
like $trailing_comma_tidy,
	qr/\nlet single_arr := \[\n\t1,\n\];\n/,
	'forces multi-line array for a single-item trailing-comma array literal';
like $trailing_comma_tidy,
	qr/\nlet no_trailing := foo\( 1, 2, 3 \);\n/,
	'a sequence without a trailing comma is unaffected and stays single-line';
like $trailing_comma_tidy,
	qr/\nlet nested_force := \[\n\t\[\n\t\t1,\n\t\t2,\n\t\],\n\t\[\n\t\t3,\n\t\t4,\n\t\],\n\];\n/,
	'nested forced sequences each split and indent independently';
like $trailing_comma_tidy,
	qr/\nlet call_args := foo\(\n\t1,\n\t2,\n\t3,\n\);\n/,
	'forces multi-line call argument list when source has a trailing comma';
like $trailing_comma_tidy,
	qr/\nlet shifted := a << b;\n/,
	'<< used as a genuine binary shift operator is spaced normally and not split';
like $trailing_comma_tidy,
	qr/\nlet mixed := \[ a << b, c \];\n/,
	'a binary shift expression as a non-trailing-comma array item does not confuse bracket matching';

my $unpack_tidy = Zuzu::Tidy->tidy(
	q{let {host,"for":for_id,Number port:=1234,`user-${suffix}`:String user_id,(key): value but weak}:=opts},
	filename => 'unpack-tidy.zzs',
);
like $unpack_tidy,
	qr/\Alet \{ host, "for": for_id, Number port := 1234, `user-\$\{suffix\}`: String user_id, \(key\): value but weak \} :=\n    opts;\n\z/,
	'formats declaration unpacking patterns and validates the result';

my $current_syntax_src = <<'SRC';
let bytes:='abc'
let bytes2:='a\n'
let template:=```Hello {name}```
let yes:=⊤
let no:=⊥
let none:=∅
let data:={meta:{title:"T"}}
let exists:=data@?"/meta/title"
let first:=data@"/meta/title"
let all:=data@@"/meta/*"
let floored:=⌊1.8⌋
let ceiled:=⌈value+0.2⌉
let bits:=a&b|c^d
let set_single:=«1,2,3,»
let diff:=left\right
async function worker(value){let task:=spawn{return value} return await{task}}
SRC

my $current_syntax_tidy = Zuzu::Tidy->tidy(
	$current_syntax_src,
	filename => 'current-syntax.zzs'
);
like $current_syntax_tidy, qr/\Alet bytes := 'abc';\n/,
	'keeps binary string delimiters';
like $current_syntax_tidy, qr/\nlet bytes2 := 'a\\n';\n/,
	'keeps escaped binary string content valid';
like $current_syntax_tidy, qr/\nlet template := `Hello \{name\}`;\n/,
	'keeps template delimiters valid';
like $current_syntax_tidy, qr/\nlet yes := true;\n/,
	'normalizes Unicode true literal to canonical boolean';
like $current_syntax_tidy, qr/\nlet no := false;\n/,
	'normalizes Unicode false literal to canonical boolean';
like $current_syntax_tidy, qr/\nlet none := ∅;\n/,
	'keeps empty set literal valid';
like $current_syntax_tidy, qr/\nlet exists := data @\? "\/meta\/title";\n/,
	'formats @? path operator spacing';
like $current_syntax_tidy, qr/\nlet first := data @ "\/meta\/title";\n/,
	'formats @ path operator spacing';
like $current_syntax_tidy, qr/\nlet all := data @@ "\/meta\/\*";\n/,
	'formats @@ path operator spacing';
like $current_syntax_tidy, qr/\nlet floored := ⌊1\.8⌋;\n/,
	'keeps simple floor bracket expression tight';
like $current_syntax_tidy, qr/\nlet ceiled := ⌈value \+ 0\.2⌉;\n/,
	'formats ceil bracket inner expression';
like $current_syntax_tidy, qr/\nlet bits := a & b \| c \^ d;\n/,
	'formats bitwise operator spacing';
like $current_syntax_tidy, qr/\nlet set_single := «\n\t1,\n\t2,\n\t3,\n»;\n/,
	'forces multi-line guillemet set when source has a trailing comma';
like $current_syntax_tidy, qr/\nlet diff := left \\ right;\n/,
	'formats set-difference operator spacing';
like $current_syntax_tidy, qr/\nasync function worker \(value\) \{/,
	'keeps async function syntax valid';
like $current_syntax_tidy, qr/\n\tlet task := spawn \{/,
	'formats spawn block keyword syntax';
like $current_syntax_tidy, qr/\n\treturn await \{\n\t\ttask;\n\t\}/,
	'formats await block keyword syntax';

my $import_src = <<'SRC';
from foo/bar import *;
from extras/math try import thing;
let ratio := foo / bar;
SRC
my $import_tidy = Zuzu::Tidy->tidy( $import_src, filename => 'import.zzs' );
like $import_tidy, qr/\Afrom foo\/bar import \*;/m,
	'keeps module path slash tight in from/import statements';
like $import_tidy, qr/\nfrom extras\/math try import thing;/,
	'keeps module path slash tight with try import';
like $import_tidy, qr/\nlet ratio := foo \/ bar;/,
	'keeps arithmetic division spacing unchanged';

my $wrap_src = 'let long := a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p + q + r + s + t';
my $wrap_tidy = Zuzu::Tidy->tidy( $wrap_src, filename => 'wrap.zzs' );
my @wrap_lines = split /\n/, $wrap_tidy;
my $max_width = 0;
for my $line ( @wrap_lines ) {
	next if $line eq '';
	my $len = length $line;
	$max_width = $len if $len > $max_width;
}
ok $max_width <= 100, 'keeps output lines at or below 100 columns';

is(
	Zuzu::Tidy->tidy("say 1\n=pod\nHello\n=cut\nsay 2\n"),
	"say 1;\n\n=pod\nHello\n=cut\n\nsay 2;\n",
	'ensures exactly one blank line around pod boundaries',
);

is(
	Zuzu::Tidy->tidy("=pod\nOnly pod\n=cut\n"),
	"=pod\nOnly pod\n=cut\n",
	'does not add blank lines at file boundaries for pod-only files',
);

like $tidied, qr/\n\tif \(a\) \{\n/s,
	'uses tab indentation';
like $tidied, qr/\n\t\}\n\telse \{\n/s,
	'does not cuddle else';

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu-tidy.pl' );
ok -x $bin, 'bin/zuzu-tidy.pl exists and is executable';

my $tmpdir = tempdir( CLEANUP => 1 );
my $script = File::Spec->catfile( $tmpdir, 'cli.zzs' );
open my $fh, '>:encoding(UTF-8)', $script
	or die "Could not create $script: $!";
print {$fh} "let n:=1\n";
close $fh;

my $cmd = "$^X $bin $script";
my $output = qx{$cmd};
my $exit = $? >> 8;
is $exit, 0, 'zuzu-tidy.pl CLI exits successfully';
is $output, "let n := 1;\n", 'zuzu-tidy.pl CLI prints tidied output';

my $canonical_script = File::Spec->catfile( $tmpdir, 'cli-canonical.zzs' );
open my $cfh, '>:encoding(UTF-8)', $canonical_script
	or die "Could not create $canonical_script: $!";
print {$cfh} "let n:=2*3\n";
close $cfh;

my $canonical_cmd = "$^X $bin --canonical-operators $canonical_script";
my $canonical_output = decode( 'UTF-8', qx{$canonical_cmd} );
my $canonical_exit = $? >> 8;
is $canonical_exit, 0, 'zuzu-tidy.pl --canonical-operators exits successfully';
is $canonical_output, "let n := 2 × 3;\n",
	'zuzu-tidy.pl --canonical-operators prints canonical operators';

my $stdin_err = gensym;
my $stdin_pid = open3(
	my $stdin_in,
	my $stdin_out,
	$stdin_err,
	$^X,
	$bin,
	'--stdin',
);
binmode $stdin_in, ':encoding(UTF-8)';
binmode $stdin_out, ':encoding(UTF-8)';
print {$stdin_in} "let stdin_value:=4\n";
close $stdin_in;
my $stdin_output = do { local $/; <$stdin_out> };
my $stdin_error = do { local $/; <$stdin_err> };
waitpid $stdin_pid, 0;
my $stdin_exit = $? >> 8;
is $stdin_exit, 0, 'zuzu-tidy.pl --stdin exits successfully';
is $stdin_error, '', 'zuzu-tidy.pl --stdin does not print errors';
is $stdin_output, "let stdin_value := 4;\n",
	'zuzu-tidy.pl --stdin prints tidied output';

my $in_place_cmd = "$^X $bin --in-place $script";
my $in_place_output = qx{$in_place_cmd};
my $in_place_exit = $? >> 8;
is $in_place_exit, 0, 'zuzu-tidy.pl --in-place exits successfully';
is $in_place_output, '', '--in-place does not print output';

open my $rfh, '<:encoding(UTF-8)', $script
	or die "Could not read $script: $!";
my $rewritten = do { local $/; <$rfh> };
close $rfh;
is $rewritten, "let n := 1;\n", '--in-place writes tidied content';

## ------------------------------------------------------------------
## Syntax-stress regression harness (examples/syntax-stress-test).
##
## Fixtures under t/fixtures/ugly/ are verbatim copies of
## examples/syntax-stress-test/uglified/*.zzs. They are intentionally
## ugly and must not be cleaned up: they exist to exercise Zuzu::Tidy
## against real-world messy input.
## ------------------------------------------------------------------

my $zuzu_bin  = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );
my @stdlib_includes = (
	'-I', File::Spec->catdir( $repo_root, 'stdlib', 'modules' ),
	'-I', File::Spec->catdir( $repo_root, 'stdlib', 'test-modules' ),
);

sub _slurp {
	my ( $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path or die "Could not read $path: $!";
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub _run_under_zuzu_perl {
	my ( $script_path ) = @_;
	my @cmd = ( $^X, $zuzu_bin, @stdlib_includes, $script_path );
	my ( $stdout, $stderr ) = ( '', '' );
	my $err = gensym;
	my $pid = open3( my $in, my $out, $err, @cmd );
	close $in;
	$stdout = do { local $/; <$out> };
	$stderr = do { local $/; <$err> };
	waitpid $pid, 0;
	my $exit = $? >> 8;
	return { exit => $exit, stdout => $stdout, stderr => $stderr, cmd => join( ' ', @cmd ) };
}

sub _tap_passed {
	my ( $result ) = @_;
	return 0 if $result->{exit} != 0;
	return 0 if $result->{stdout} =~ /^\s*not ok\b/m;
	return 1;
}

my @stress_fixtures = qw(
	01-control-and-literals.zzs
	02-objects-traits-and-accessors.zzs
	03-collections-paths-and-slices.zzs
	04-functions-lambdas-and-spread.zzs
	05-async-spawn-and-exceptions.zzs
);

my $fixtures_dir = File::Spec->catdir( $repo_root, 't', 'fixtures', 'ugly' );
my $manually_tidied_dir = File::Spec->catdir(
	$repo_root, '..', 'examples', 'syntax-stress-test', 'manually-tidied'
);

for my $name ( @stress_fixtures ) {
	my $ugly_path = File::Spec->catfile( $fixtures_dir, $name );
	my $ugly_src = _slurp($ugly_path);
	my $tidied = Zuzu::Tidy->tidy( $ugly_src, filename => $name );

	my $parser = Zuzu::Parser->new;
	my $parse_ok = eval {
		$parser->parse( $tidied, $name );
		1;
	};
	my $parse_error = $@;
	ok $parse_ok, "$name: auto-tidied ugly fixture parses with Zuzu::Parser"
		or diag "Parse error for $name:\n$parse_error\n---- tidied output ----\n$tidied";

	my $tmpdir = tempdir( CLEANUP => 1 );
	my $tidied_path = File::Spec->catfile( $tmpdir, $name );
	open my $fh, '>:encoding(UTF-8)', $tidied_path
		or die "Could not write $tidied_path: $!";
	print {$fh} $tidied;
	close $fh;

	my $result = _run_under_zuzu_perl($tidied_path);

	# Same pre-existing, unrelated std/path/z/node.zzm runtime bug noted
	# below for the manually-tidied fixture: it also reproduces on the
	# never-tidied original source, so it isn't something Zuzu::Tidy
	# introduced or can fix.
	if ( $name eq '03-collections-paths-and-slices.zzs' ) {
		todo 'pre-existing std/path/z/node.zzm runtime bug, unrelated to Zuzu::Tidy' => sub {
			ok _tap_passed($result), "$name: auto-tidied ugly fixture runs under zuzu-perl";
		};
		next;
	}

	ok _tap_passed($result), "$name: auto-tidied ugly fixture runs under zuzu-perl"
		or diag "Command: $result->{cmd}\nExit: $result->{exit}\nSTDOUT:\n$result->{stdout}\nSTDERR:\n$result->{stderr}";
}

for my $name ( @stress_fixtures ) {
	my $manual_path = File::Spec->catfile( $manually_tidied_dir, $name );
	next if ! -f $manual_path;
	my $manual_src = _slurp($manual_path);

	my $parser = Zuzu::Parser->new;
	my $parse_ok = eval {
		$parser->parse( $manual_src, $name );
		1;
	};
	ok $parse_ok, "$name: manually-tidied fixture parses with Zuzu::Parser"
		or diag "Parse error for $name:\n$@";

	my $result = _run_under_zuzu_perl($manual_path);

	# Known pre-existing bug in std/path/z/node.zzm's Node.children(),
	# unrelated to Zuzu::Tidy: indexing failure under zuzu-perl even for
	# the original, never-tidied source. Out of scope for this plan
	# (Assumptions: changes are scoped to Zuzu::Tidy unless lexer/parser
	# defects are found). Tracked here so a real fix shows up as a new
	# failure instead of silently staying broken.
	if ( $name eq '03-collections-paths-and-slices.zzs' ) {
		todo 'pre-existing std/path/z/node.zzm runtime bug, unrelated to Zuzu::Tidy' => sub {
			ok _tap_passed($result), "$name: manually-tidied fixture runs under zuzu-perl";
		};
		next;
	}

	ok _tap_passed($result), "$name: manually-tidied fixture runs under zuzu-perl"
		or diag "Command: $result->{cmd}\nExit: $result->{exit}\nSTDOUT:\n$result->{stdout}\nSTDERR:\n$result->{stderr}";
}

## ------------------------------------------------------------------
## Focused assertions for the known bad shapes from
## examples/syntax-stress-test/tidy-improvements.md. These currently
## fail (Phase 1 of that plan) and should turn green as the formatter
## is fixed in subsequent phases.
## ------------------------------------------------------------------

my $pairlist_spread_src = <<'SRC';
let merged := combine(...{{ left: "(", left: "{" }});
SRC
my $pairlist_spread_tidy = Zuzu::Tidy->tidy(
	$pairlist_spread_src,
	filename => 'pairlist-spread.zzs',
);
like $pairlist_spread_tidy, qr/\.\.\.\{\{.*?\}\}/s,
	'pairlist spread keeps doubled {{ ... }} delimiters intact';
unlike $pairlist_spread_tidy, qr/\.\.\.\{\n/,
	'pairlist spread is not split into a nested { { ... } } block';

my $class_brace_tidy = Zuzu::Tidy->tidy(
	"class Record with Labelled{let String name:=\"x\"}\n",
	filename => 'class-brace.zzs',
);
unlike $class_brace_tidy, qr/\{[ \t]*let\b/,
	'class opening brace is followed by a newline, not an inline field declaration';

my $function_brace_tidy = Zuzu::Tidy->tidy(
	"function classify(Number n)->String{if(n>0){return \"pos\"}return \"non-pos\"}\n",
	filename => 'function-brace.zzs',
);
unlike $function_brace_tidy, qr/\{[ \t]*if[ \t]*\(/,
	'function opening brace is followed by a newline, not an inline if statement';

my $method_brace_tidy = Zuzu::Tidy->tidy(
	"class Demo{method summary()->String{return \"ok\"}}\n",
	filename => 'method-brace.zzs',
);
unlike $method_brace_tidy, qr/\{[ \t]*return\b/,
	'method opening brace is followed by a newline, not an inline return';

my $async_brace_tidy = Zuzu::Tidy->tidy(
	"async function delayed_double(Number n)->Number{await{sleep(0.01)}return n*2}\n",
	filename => 'async-brace.zzs',
);
unlike $async_brace_tidy, qr/\{[ \t]*await[ \t]*\{/,
	'async function opening brace is followed by a newline, not an inline await block';

my $static_method_tidy = Zuzu::Tidy->tidy(
	"class Builder{method summary()->String{return \"a\"}static method make()->Builder{return new Builder()}}\n",
	filename => 'static-method.zzs',
);
unlike $static_method_tidy, qr/\}[ \t]*static[ \t]+method\b/,
	'closing a method body does not collapse onto the same line as the next static method declaration';

my $try_catch_src = <<'SRC';
try{
step1()
step2()
step3()
step4()
step5()
}catch(Exception e){handle(e)}
SRC
my $try_catch_tidy = Zuzu::Tidy->tidy( $try_catch_src, filename => 'try-catch.zzs' );
unlike $try_catch_tidy, qr/\}\n\n\s*catch\b/,
	'try/catch stay adjacent with no blank line between the closing } and catch';

my $for_else_src = <<'SRC';
for(let item in items){
step1(item)
step2(item)
step3(item)
step4(item)
step5(item)
}else{say "nothing"}
SRC
my $for_else_tidy = Zuzu::Tidy->tidy( $for_else_src, filename => 'for-else.zzs' );
unlike $for_else_tidy, qr/\}\n\n\s*else\b/,
	'for/else stay adjacent with no blank line between the closing } and else';

my $multiline_call_tidy = Zuzu::Tidy->tidy(
	"call_twice(function(value){step_one(value)step_two(value)}, 4);\n",
	filename => 'multiline-call.zzs',
);
unlike $multiline_call_tidy, qr/^\s*,\s*\d/m,
	'a trailing call argument after a callback is not stranded alone on its own line';

my $index_call_tidy = Zuzu::Tidy->tidy(
	"let lambda_values:=[await{async_lambdas[0](10);},await{async_lambdas[1](10);},];\n",
	filename => 'index-call.zzs',
);
unlike $index_call_tidy, qr/\[\s*0\s*,?\s*\n/,
	'a simple index expression is never split across a line break';

## ------------------------------------------------------------------
## Phase 5 whitespace rules: switch comparator spacing, access chains,
## slices, and concatenation around punctuation literals.
## ------------------------------------------------------------------

my $switch_comparator_tidy = Zuzu::Tidy->tidy(
	"switch(n mod 4: =){case 0:say \"a\" default:say \"b\"}\n",
	filename => 'switch-comparator.zzs',
);
like $switch_comparator_tidy, qr/switch \( n mod 4 : = \) \{/,
	'switch comparator marker keeps readable spacing around :';

my $access_chain_tidy = Zuzu::Tidy->tidy(
	"let x:=data{users}[0]{roles};\n",
	filename => 'access-chain.zzs',
);
like $access_chain_tidy, qr/\Alet x := data\{users\}\[0\]\{roles\};\n/,
	'chained dict/index access stays tight with no inserted spaces';

my $slice_tidy = Zuzu::Tidy->tidy(
	"let m:=text[1:2];\nlet n:=bytes[2:2];\nlet p:=arr[:2];\nlet q:=arr[1:];\n",
	filename => 'slice.zzs',
);
like $slice_tidy, qr/\Alet m := text\[1:2\];\n/, 'keeps a simple slice compact';
like $slice_tidy, qr/\nlet n := bytes\[2:2\];\n/, 'keeps a binary-string slice compact';
like $slice_tidy, qr/\nlet p := arr\[:2\];\n/, 'keeps a slice with an omitted start compact';
like $slice_tidy, qr/\nlet q := arr\[1:\];\n/, 'keeps a slice with an omitted end compact';

my $concat_punct_tidy = Zuzu::Tidy->tidy(
	qq{let r := text _":" _ item;\n},
	filename => 'concat-punct.zzs',
);
like $concat_punct_tidy, qr/\Alet r := text _ ":" _ item;\n/,
	'spaces the concatenation operator consistently around a punctuation string literal';

done_testing;
