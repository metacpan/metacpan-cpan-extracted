use strict;
use warnings;
use Test::More tests => 36;
use utf8;
use Encode;

require_ok( 'TurboXSLT' );

my $engine = new TurboXSLT;
isa_ok($engine, 'TurboXSLT', "XSLT init");
my $RegOk=0;
eval {
	$engine->RegisterCallback('ltr:my_callback', sub {join '/',@_});
	$RegOk = 1;
};
ok($RegOk,'RegisterCallback call works');

for my $Threads (0,4) {

	my $ctx = $engine->LoadStylesheet("t/test.xsl");
	isa_ok($ctx, 'TurboXSLT::Stylesheet', "Stylesheet load");

	if ($Threads > 1){
		$ctx->CreateThreadPool($Threads);
		pass("CreateThreadPool($Threads) - no die");
	}

	my $source =<<_XML
<foo>
  <bar developer1="жует печеньку" deve-Loper2="тоже хочет печенье" To_Pol="26755344">
    <xxx t="zzz"/>
  </bar>
</foo>
_XML
;
	my $expected=<<_XML
<?xml version="1.0"?>
<FOO>фуу

  <BAR>
    <XXX>my/path/zzz</XXX>
  </BAR>
</FOO>
_XML
;


	my $doc = $engine->Parse($source);
	isa_ok($doc, 'TurboXSLT::Node', "Parsed document ($Threads threads)");

	my $text = $ctx->Output($doc);
	like($text,qr/<bar/,"Document from TurboXSLT::Node ($Threads threads)");

	my $res = $ctx->Transform($doc);
	isa_ok($res, 'TurboXSLT::Node', "DOM after Transform ($Threads threads)");

	$text = $ctx->Output($res);
	ok(Encode::is_utf8($text), "Correct UTF-bit on Output ($Threads threads)");

	unless (Encode::is_utf8($text)) {
		$text = Encode::decode_utf8($text);
	}

	like($text,qr|<XXX>my/path/zzz</XXX>|,"Callback receives parameters as an array ($Threads threads)");

	for ($expected,$text){
		s/\s+/ /g;
	}

	cmp_ok($text, 'eq', $expected, "Transformation 100% correct ($Threads threads)");

	my $node = $ctx->FindNodes($doc,'/foo/bar/@developer1');
	isa_ok($doc, 'TurboXSLT::Node', "FindNodes()");

	my $StringVal = $node->StringValue();
	ok($StringVal, 'StringValue() returns something');
	ok(Encode::is_utf8($StringVal),"Correct UTF-bit on StringValue ($Threads threads)");

	my $StringVal1 = $node->StringValue();
	cmp_ok($StringVal, 'eq', $StringVal1,"StringValue returns the same data next time");

	unless (Encode::is_utf8($StringVal)) {
		$StringVal = Encode::decode_utf8($StringVal,0);
	}
	cmp_ok($StringVal, 'eq', qq{жует печеньку},"StringValue() evaluated correctly  ($Threads threads)");

	my $Attr = $ctx->FindNodes($doc,'/foo/bar')->Attributes();
	is (ref($Attr),ref({}),'->Attributes() is HASH');
	cmp_ok($Attr->{To_Pol}, '==', 26755344,"->Attributes() digit value ($Threads threads)");

	ok(Encode::is_utf8($Attr->{'deve-Loper2'}),"Attributes hashe values have UTF bit on  ($Threads threads)");

	unless (Encode::is_utf8($Attr->{'deve-Loper2'})) {
		$Attr->{'deve-Loper2'} = Encode::decode_utf8($Attr->{'deve-Loper2'},0);
	}
	cmp_ok($Attr->{'deve-Loper2'}, 'eq', 'тоже хочет печенье',"->Attributes() string value  ($Threads threads)");
}
