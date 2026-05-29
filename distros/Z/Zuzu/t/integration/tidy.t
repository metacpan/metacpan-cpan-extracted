use Test2::V0;

use Encode qw( decode );
use File::Spec;
use File::Temp qw( tempdir );

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
	qr/\nlet cfg := \{ pretty: false, sort_keys: false, color: false, quiet: false \};\n/,
	'removes trailing comma for single-line dict or bag literals',
);
like $spacing_tidy, qr/\nlet range_arr := \[ 1 \.\.\. 3 \];\n/,
	'keeps array ranges formatted as ranges';
like $spacing_tidy, qr/\nlet range_set := << 1 \.\.\. 3 >>;\n/,
	'keeps set ranges formatted as ranges';
like $spacing_tidy, qr/\nlet range_bag := <<< 1 \.\.\. 3 >>>;\n/,
	'keeps bag ranges formatted as ranges';
like $spacing_tidy, qr/\nlet arr := \[ 1, 2, 3 \];\n/, 'removes trailing comma for single-line arrays';
like(
	$spacing_tidy,
	qr/\nlet arr_force := \[\n\ta{40},\n\tb{40},\n\tc{40},\n\td{40},\n\];\n/,
	'formats split arrays one item per line with trailing comma',
);
like $spacing_tidy, qr/\nlet set_single := << 1, 2, 3 >>;\n/, 'removes trailing comma for single-line sets';
like(
	$spacing_tidy,
	qr/\nlet set_force := <<\n\ta{40},\n\tb{40},\n\tc{40},\n\td{40},\n>>;\n/,
	'formats split sets one item per line with trailing comma',
);
like $spacing_tidy, qr/\nlet bag_single := <<< 1, 2, 3 >>>;\n/, 'removes trailing comma for single-line bags';
like(
	$spacing_tidy,
	qr/\nlet bag_force := <<<\n\ta{40},\n\tb{40},\n\tc{40},\n\td{40},\n>>>;?\n/,
	'formats split bags one item per line with trailing comma',
);

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
like $current_syntax_tidy, qr/\nlet set_single := « 1, 2, 3 »;\n/,
	'removes trailing comma for single-line guillemet sets';
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

done_testing;
