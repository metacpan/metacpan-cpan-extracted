use Test2::V0;
use Test2::Require::AuthorTesting;

use utf8;
use File::Spec;
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $highlighter = File::Spec->catfile(
	$repo_root, 'bin', 'zuzu-highlight.pl'
);

ok -f $highlighter, 'highlighter script exists';

my $source = <<'ZZS';
let x := 10 / 2;
let rx := /ab+c/i;
let slash_class := /[/]/g;
let bytes := 'abc';
let bytes2 := '''ab
cd''';
let template := ```Hello {x}```;
let yes := ⊤;
let no := ⊥;
let none := ∅;
let data := { meta: { title: "T" } };
let exists := data @? "/meta/title";
let merged := data default { host: "localhost" };
let items := [];
function collect () {
	return items;
}
collect(...items);
let floored := ⌊1.8⌋;
let ceiled := ⌈1.2⌉;
let chained := 4 ▷ ^^ + 1;
let numeric := [ 0x1F, 0b1111, 0o100, 1E3, 2.5E-7 ];
let divided := 2 divides 6 and 2 ∣ 6 and 4 ∤ 6;
let logical := true nor? false xnor true onlyif? true butnot false;
let symbolic := true ⊽? false ↔ true ⊨? true ⊭ false;
let named := collect( length: 42, method: "GET", class: "Widget" );
let { host, "for": for_id, Number port := 1234, (`x`): x_key but weak } :=
	{ host: "localhost", "for": 1, port: 8080, x: null };
async function demo (value) {
	let task := spawn {
		return value;
	};
	return await {
		task;
	}
}
ZZS

my $stderr = gensym;
my $pid = open3( my $stdin, my $stdout, $stderr, $^X, $highlighter );
binmode $stdin, ':encoding(UTF-8)';
binmode $stdout, ':encoding(UTF-8)';
binmode $stderr, ':encoding(UTF-8)';
print {$stdin} $source;
close $stdin;

my $html = do { local $/ = undef; <$stdout> // '' };
my $err = do { local $/ = undef; <$stderr> // '' };
close $stdout;
close $stderr;
waitpid $pid, 0;
my $exit = $? >> 8;
is $exit, 0, 'highlighter exits successfully';
is $err, '', 'highlighter does not write to stderr';
like $html, qr{<span class="operator">/</span>\s*<span class="number">2</span>},
	'division slash is classified as operator';
like $html, qr{<span class="regexp">/ab\+c/i</span>},
	'regexp literal is classified as regexp';
like $html, qr{<span class="regexp">/\[/\]/g</span>},
	'regexp literal with slash character class is classified as regexp';
like $html, qr{<span class="string">'abc'</span>},
	'binary string literal is classified as string';
like $html, qr{(?s)<span class="string">'''ab\ncd'''</span>},
	'triple binary string literal is classified as string';
like $html, qr{<span class="string">```Hello \{x\}```</span>},
	'triple template literal is classified as string';
like $html, qr{<span class="boolean">⊤</span>},
	'Unicode true literal is classified as boolean';
like $html, qr{<span class="boolean">⊥</span>},
	'Unicode false literal is classified as boolean';
like $html, qr{<span class="operator">∅</span>},
	'empty set literal is classified as operator';
like $html, qr{<span class="operator">@\?</span>},
	'path-exists operator is classified as operator';
like $html, qr{<span class="operator">default</span>},
	'default word operator is classified as operator';
like $html, qr{<span class="operator">\.\.\.</span><span class="ident">items</span>},
	'spread operator is classified as operator in call arguments';
like $html, qr{<span class="operator">⌊</span><span class="number">1\.8</span><span class="operator">⌋</span>},
	'floor brackets are classified as operators around their expression';
like $html, qr{<span class="operator">▷</span>},
	'chain operator is classified as operator';
like $html, qr{<span class="ident">\^\^</span>},
	'chain placeholder is classified as identifier';
like $html, qr{<span class="number">0o100</span>},
	'octal source literal is classified as number';
like $html, qr{<span class="number">1E3</span>},
	'uppercase exponent source literal is classified as number';
like $html, qr{<span class="operator">divides</span>},
	'divides word operator is classified as operator';
like $html, qr{<span class="operator">∣</span>},
	'divides symbol operator is classified as operator';
like $html, qr{<span class="operator">∤</span>},
	'not-divides symbol operator is classified as operator';
like $html, qr{<span class="operator">nor\?</span>},
	'value-preserving nor word operator is classified as operator';
like $html, qr{<span class="operator">xnor</span>},
	'xnor word operator is classified as operator';
like $html, qr{<span class="operator">onlyif\?</span>},
	'value-preserving onlyif word operator is classified as operator';
like $html, qr{<span class="operator">butnot</span>},
	'butnot word operator is classified as operator';
like $html, qr{<span class="operator">⊽\?</span>},
	'value-preserving nor symbol operator is classified as operator';
like $html, qr{<span class="operator">↔</span>},
	'xnor symbol operator is classified as operator';
like $html, qr{<span class="operator">⊨\?</span>},
	'value-preserving onlyif symbol operator is classified as operator';
like $html, qr{<span class="operator">⊭</span>},
	'butnot symbol operator is classified as operator';
like $html, qr{<span class="operator">length</span><span class="operator">:</span>},
	'wordlike named argument key remains parseable';
like $html, qr{<span class="keyword">let</span>\s*<span class="operator">\{</span>},
	'declaration unpacking starts with highlighted let and brace tokens';
like $html, qr{<span class="string">"for"</span><span class="operator">:</span>},
	'string keys in declaration unpacking are highlighted';
like $html, qr{<span class="keyword">async</span>\s*<span class="keyword">function</span>},
	'async function keywords are highlighted';
like $html, qr{<span class="keyword">spawn</span>},
	'spawn keyword is highlighted';
like $html, qr{<span class="keyword">await</span>},
	'await keyword is highlighted';
like $html, qr{<span class="ident-decl">demo</span>},
	'function name identifier is highlighted as declaration';
like $html, qr{Parse check: ok},
	'parser validation succeeds for valid source';

done_testing;
