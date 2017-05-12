use 5.008;
use strict;
use warnings;
use Test::More tests => 10;
use utf8;
use Encode;

require_ok( 'TurboXSLT' );

my $engine = new TurboXSLT;
isa_ok($engine, 'TurboXSLT', "XSLT init");

my %Rights = (
	Korriban => {
		Sith => ['lightning', 'dreem_GOD_power', 'use_force','r44', 'r100500'],
		DarthVader => ['red_lightsaber', 'DeathStar', 'sopelka']
	},
	Tatooine => {
		Elvis => ['music', 'songs', 'datastorage','microphone','soundcard'],
		o_O  => ['gDGdshbcJJ&348JD'],
		Jedi => ['use_force','lightsaber','pathos', 'beard'],
    Luke => ['r2d2', 'c3po', 'sister'],
    Leia => ['karalka_na_golove', 'cap.Solo', 'blaster']
	}
);


my $Ok = 0;
eval{
	for my $prefix (keys %Rights){
		for my $group (keys %{ $Rights{$prefix} }){
			$engine->DefineGroupRights($prefix, $group, $Rights{$prefix}->{$group});
		}
	}
	$Ok = 1;
};
ok($Ok,'DefineGroupRights call works');

my $source =<<_XML
<foo>
  <bar>

  </bar>
</foo>
_XML
;

my $ctx = $engine->LoadStylesheet("t/check_rights.xsl");
isa_ok($ctx, 'TurboXSLT::Stylesheet', "Stylesheet load");

my $doc = $engine->Parse($source);
isa_ok($doc, 'TurboXSLT::Node', "Parsed document");

my $res = $ctx->Transform($doc);
my $text = $ctx->Output($res);
cmp_ok(Cleanup($text), 'eq', "<?xml version=\"1.0\"?>", "no rights specified");


my @groups_1 = ("DarthVader",'Elvis');
$Ok=0;
eval{
  $ctx->SetUserContext("Korriban", \@groups_1);
  $Ok=1;
};
ok($Ok,'SetUserContext call works');

$res = $ctx->Transform($doc);
$text = $ctx->Output($res);
cmp_ok(Cleanup($text), 'eq', "<?xml version=\"1.0\"?> Kh-h-h-h<br/>Pf-f-f-f", "has sopelka");

my @groups_2 = ("Luke", 'Jedi', 'Sith');
eval{
  $ctx->SetUserContext("Tatooine", \@groups_2);
};

$res = $ctx->Transform($doc);
$text = $ctx->Output($res);
cmp_ok(Cleanup($text), 'eq', "<?xml version=\"1.0\"?> bip-bip-bip<br/>cool", "has robot");

eval{
  $ctx->SetUserContext("Coruscant", \@groups_2);
};

$res = $ctx->Transform($doc);
$text = $ctx->Output($res);
cmp_ok(Cleanup($text), 'eq', "<?xml version=\"1.0\"?>", "has no rights");

sub Cleanup {
	$_ = shift;
	s/^\s+|\s+$//g;
	s/\s+/ /g;
	return $_;
}
