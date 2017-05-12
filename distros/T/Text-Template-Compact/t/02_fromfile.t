use utf8;
use strict;
use Test::More tests => 3;
use Text::Template::Compact;
use Encode;

my $infile = "t/test.html";

my $tmpl = new Text::Template::Compact();
my $r = $tmpl->loadFile($infile,'utf8');
ok($r);
if(not $r){
	die $tmpl->error;
}

my $param = {
	text=>"this is text.",
	index=>"0",
	hash=>{ a => "深い階層にあるパラメータです", },
	tlist =>[
		"これはutf8フラグのついたテキストです",
		Encode::encode('cp932',"これはutf8フラグのないテキストです"),
	],
	htmltest => "日本語ABC<>&\"';[\n]",
	
	varlist =>[
		undef
		,'',' ','0E0'
		,0,1,2,3
		,0.0001
		,[1,2,3]
		,{ a=>1,b=>2,c=>3}
		,$tmpl
	],

	true => 1,

	testif =>[ (0..5)],
};

$tmpl->param_encoding('cp932');
$tmpl->filter_default('html');

my $fh;
ok(open($fh,">","out1.html"));
$fh and $tmpl->print($param,$fh,'utf8');
ok(close($fh));

# print Encode::encode('utf8',$tmpl->toString($param));

