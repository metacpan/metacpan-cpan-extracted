use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '1'});
	should_pass("2", $type, 0);
	should_pass("982349033495275913", $type, 0);
	should_pass("991909556031309923", $type, 0);
	should_pass("932234447917123620", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 262638891446532185." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '262638891446532185'});
	should_pass("262638891446532186", $type, 0);
	should_pass("876689699487020075", $type, 0);
	should_pass("305127189898932780", $type, 0);
	should_pass("546875430332327851", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 173303931811171541." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '173303931811171541'});
	should_pass("173303931811171542", $type, 0);
	should_pass("988296320075830472", $type, 0);
	should_pass("187207554565913903", $type, 0);
	should_pass("878376937391018269", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 506558727413711217." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '506558727413711217'});
	should_pass("506558727413711218", $type, 0);
	should_pass("875004857999238131", $type, 0);
	should_pass("641501311423161415", $type, 0);
	should_pass("668695977727626858", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '999999999999999998'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '1'});
	should_pass("1", $type, 0);
	should_pass("312555068067347119", $type, 0);
	should_pass("406416714419411406", $type, 0);
	should_pass("317956959553971186", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 15066261577183049." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '15066261577183049'});
	should_pass("15066261577183049", $type, 0);
	should_pass("58253528157596052", $type, 0);
	should_pass("205376965405062076", $type, 0);
	should_pass("913187852637643351", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 828758841369869991." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '828758841369869991'});
	should_pass("828758841369869991", $type, 0);
	should_pass("910584086949352167", $type, 0);
	should_pass("936085115171037335", $type, 0);
	should_pass("918098813427214593", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 69860014844260743." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '69860014844260743'});
	should_pass("69860014844260743", $type, 0);
	should_pass("225746133856350748", $type, 0);
	should_pass("770102717928348466", $type, 0);
	should_pass("90419069275015919", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '999999999999999999'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 2." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '2'});
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 32371283896903692." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '32371283896903692'});
	should_pass("1", $type, 0);
	should_pass("4486244211931743", $type, 0);
	should_pass("30697555039207401", $type, 0);
	should_pass("24352217317326215", $type, 0);
	should_pass("32371283896903691", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 685616415831176051." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '685616415831176051'});
	should_pass("1", $type, 0);
	should_pass("645153569833015152", $type, 0);
	should_pass("572235003435245836", $type, 0);
	should_pass("447037998416114053", $type, 0);
	should_pass("685616415831176050", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 571841216500225568." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '571841216500225568'});
	should_pass("1", $type, 0);
	should_pass("22031580018851121", $type, 0);
	should_pass("383029359970327560", $type, 0);
	should_pass("71789437680291185", $type, 0);
	should_pass("571841216500225567", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '999999999999999999'});
	should_pass("1", $type, 0);
	should_pass("720027946340477952", $type, 0);
	should_pass("75300685728174277", $type, 0);
	should_pass("236166620433764906", $type, 0);
	should_pass("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '1'});
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 423285904007674851." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '423285904007674851'});
	should_pass("1", $type, 0);
	should_pass("153349543491418210", $type, 0);
	should_pass("192168039749809891", $type, 0);
	should_pass("330253502610144334", $type, 0);
	should_pass("423285904007674851", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 809380027468239004." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '809380027468239004'});
	should_pass("1", $type, 0);
	should_pass("376556333955278357", $type, 0);
	should_pass("282180434046745516", $type, 0);
	should_pass("186033623824917075", $type, 0);
	should_pass("809380027468239004", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 619618676703699189." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '619618676703699189'});
	should_pass("1", $type, 0);
	should_pass("458184742283352808", $type, 0);
	should_pass("270348752837021310", $type, 0);
	should_pass("56691669269610340", $type, 0);
	should_pass("619618676703699189", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 999999999999999999." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '999999999999999999'});
	should_pass("1", $type, 0);
	should_pass("339696864049625069", $type, 0);
	should_pass("399326842300909867", $type, 0);
	should_pass("143280828597479371", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('PositiveInteger', {'fractionDigits' => '0'});
	should_pass("1", $type, 0);
	should_pass("496604127571227182", $type, 0);
	should_pass("866575962853341485", $type, 0);
	should_pass("258197386597402434", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '1'});
	should_pass("5", $type, 0);
	should_pass("6", $type, 0);
	should_pass("4", $type, 0);
	should_pass("6", $type, 0);
	should_pass("7", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '5'});
	should_pass("3", $type, 0);
	should_pass("45", $type, 0);
	should_pass("564", $type, 0);
	should_pass("1275", $type, 0);
	should_pass("13714", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '9'});
	should_pass("2", $type, 0);
	should_pass("151", $type, 0);
	should_pass("81986", $type, 0);
	should_pass("8472964", $type, 0);
	should_pass("319266366", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '13'});
	should_pass("6", $type, 0);
	should_pass("8272", $type, 0);
	should_pass("8651131", $type, 0);
	should_pass("7238618218", $type, 0);
	should_pass("6979035245178", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '18'});
	should_pass("9", $type, 0);
	should_pass("73765", $type, 0);
	should_pass("721731556", $type, 0);
	should_pass("6587555823776", $type, 0);
	should_pass("171462243233917146", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("2", $type, 0);
	should_pass("4", $type, 0);
	should_pass("3", $type, 0);
	should_pass("7", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("88253", $type, 0);
	should_pass("35956", $type, 0);
	should_pass("37377", $type, 0);
	should_pass("71439", $type, 0);
	should_pass("96766", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{9}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{9}$)/});
	should_pass("769719874", $type, 0);
	should_pass("328264516", $type, 0);
	should_pass("788695745", $type, 0);
	should_pass("466944674", $type, 0);
	should_pass("484763277", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{13}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{13}$)/});
	should_pass("2233735692359", $type, 0);
	should_pass("2466125676771", $type, 0);
	should_pass("5661425462852", $type, 0);
	should_pass("8245223398863", $type, 0);
	should_pass("3737767893432", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_pass("977784185831812352", $type, 0);
	should_pass("954768745235645523", $type, 0);
	should_pass("964636143567451713", $type, 0);
	should_pass("942757486532436464", $type, 0);
	should_pass("925841177113784843", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['29','3059918349066803','44881','557','39237065970202644','101001635697','7652','408576971836088']});
	should_pass("408576971836088", $type, 0);
	should_pass("3059918349066803", $type, 0);
	should_pass("101001635697", $type, 0);
	should_pass("44881", $type, 0);
	should_pass("3059918349066803", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['853441','5705619952894463','468315652460615','54802934845216066','10','801','8410074843393','87378193514885904','127831830298']});
	should_pass("468315652460615", $type, 0);
	should_pass("801", $type, 0);
	should_pass("468315652460615", $type, 0);
	should_pass("801", $type, 0);
	should_pass("801", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['12730','518340460','27263821738066862','63621988','7678','7942666042']});
	should_pass("12730", $type, 0);
	should_pass("7678", $type, 0);
	should_pass("63621988", $type, 0);
	should_pass("518340460", $type, 0);
	should_pass("63621988", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['66130353503','2337','27711148','849926','600957','822','7497','3167940084','435109']});
	should_pass("2337", $type, 0);
	should_pass("849926", $type, 0);
	should_pass("435109", $type, 0);
	should_pass("600957", $type, 0);
	should_pass("849926", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['85265','2633','20007586335496','24394','15836086414917927','84017762294','378362663062']});
	should_pass("15836086414917927", $type, 0);
	should_pass("15836086414917927", $type, 0);
	should_pass("24394", $type, 0);
	should_pass("378362663062", $type, 0);
	should_pass("85265", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('PositiveInteger', {'whiteSpace' => 'collapse'});
	should_pass("1", $type, 0);
	should_pass("840635356637731478", $type, 0);
	should_pass("857418719546887752", $type, 0);
	should_pass("324146775533287634", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 874370595268603056." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '874370595268603056'});
	should_fail("1", $type, 0);
	should_fail("463969428287285252", $type, 0);
	should_fail("571284772856430574", $type, 0);
	should_fail("751601505559521427", $type, 0);
	should_fail("874370595268603055", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 975077401610746407." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '975077401610746407'});
	should_fail("1", $type, 0);
	should_fail("340511711975447020", $type, 0);
	should_fail("222561909334976317", $type, 0);
	should_fail("703175082919244117", $type, 0);
	should_fail("975077401610746406", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 520520563111862677." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '520520563111862677'});
	should_fail("1", $type, 0);
	should_fail("242844343134479483", $type, 0);
	should_fail("199625598517031173", $type, 0);
	should_fail("194628006109212701", $type, 0);
	should_fail("520520563111862676", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 884867483068111581." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '884867483068111581'});
	should_fail("1", $type, 0);
	should_fail("789270698540434769", $type, 0);
	should_fail("800583676657285039", $type, 0);
	should_fail("574809300350579814", $type, 0);
	should_fail("884867483068111580", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('PositiveInteger', {'minInclusive' => '999999999999999999'});
	should_fail("1", $type, 0);
	should_fail("878144925461554313", $type, 0);
	should_fail("334020139353938039", $type, 0);
	should_fail("25382068101232114", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '1'});
	should_fail("2", $type, 0);
	should_fail("45468464539782817", $type, 0);
	should_fail("829562509786757495", $type, 0);
	should_fail("704807950524782400", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 177196767521656029." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '177196767521656029'});
	should_fail("177196767521656030", $type, 0);
	should_fail("887357412961596139", $type, 0);
	should_fail("183935176227759991", $type, 0);
	should_fail("564160953444496121", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 131706786963028178." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '131706786963028178'});
	should_fail("131706786963028179", $type, 0);
	should_fail("647787532796072695", $type, 0);
	should_fail("483853198284271574", $type, 0);
	should_fail("852804698047706080", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 638826049431571618." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '638826049431571618'});
	should_fail("638826049431571619", $type, 0);
	should_fail("705257234714437272", $type, 0);
	should_fail("844109764788363834", $type, 0);
	should_fail("717553871867105576", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxInclusive with value 860350668025949171." => sub {
	my $type = mk_type('PositiveInteger', {'maxInclusive' => '860350668025949171'});
	should_fail("860350668025949172", $type, 0);
	should_fail("906253266082163879", $type, 0);
	should_fail("933320924116726189", $type, 0);
	should_fail("867891249566093604", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '1'});
	should_fail("82", $type, 0);
	should_fail("926035", $type, 0);
	should_fail("4832375246", $type, 0);
	should_fail("16512552312512", $type, 0);
	should_fail("137684928197322329", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '4'});
	should_fail("34822", $type, 0);
	should_fail("70637742", $type, 0);
	should_fail("15793211212", $type, 0);
	should_fail("26618875674363", $type, 0);
	should_fail("163842311182224166", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '7'});
	should_fail("36643115", $type, 0);
	should_fail("6351625544", $type, 0);
	should_fail("815716190557", $type, 0);
	should_fail("48769445775724", $type, 0);
	should_fail("110346136636237565", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '10'});
	should_fail("74648782350", $type, 0);
	should_fail("166308411217", $type, 0);
	should_fail("2044173572041", $type, 0);
	should_fail("57779138821106", $type, 0);
	should_fail("398235385338349817", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('PositiveInteger', {'totalDigits' => '13'});
	should_fail("21187981634549", $type, 0);
	should_fail("755658594114345", $type, 0);
	should_fail("5908446520846672", $type, 0);
	should_fail("89050264731859148", $type, 0);
	should_fail("703714577082544222", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 1." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '1'});
	should_fail("1", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 159779689100354561." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '159779689100354561'});
	should_fail("1", $type, 0);
	should_fail("4703221073283038", $type, 0);
	should_fail("83826753273273379", $type, 0);
	should_fail("47847777004084757", $type, 0);
	should_fail("159779689100354561", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 196998635864784277." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '196998635864784277'});
	should_fail("1", $type, 0);
	should_fail("82328350442857316", $type, 0);
	should_fail("191511466403091336", $type, 0);
	should_fail("94354030643614512", $type, 0);
	should_fail("196998635864784277", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 975773071955124413." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '975773071955124413'});
	should_fail("1", $type, 0);
	should_fail("366331497857183911", $type, 0);
	should_fail("599355922918828286", $type, 0);
	should_fail("298741005666310057", $type, 0);
	should_fail("975773071955124413", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('PositiveInteger', {'minExclusive' => '999999999999999998'});
	should_fail("1", $type, 0);
	should_fail("292709229968370232", $type, 0);
	should_fail("4037170947835956", $type, 0);
	should_fail("860341361129465130", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 2." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '2'});
	should_fail("2", $type, 0);
	should_fail("580035881441445355", $type, 0);
	should_fail("260948973968477716", $type, 0);
	should_fail("563331464152950767", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 439492137310005915." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '439492137310005915'});
	should_fail("439492137310005915", $type, 0);
	should_fail("643558600794419319", $type, 0);
	should_fail("489995076791599946", $type, 0);
	should_fail("530397461306073535", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 44963355987554522." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '44963355987554522'});
	should_fail("44963355987554522", $type, 0);
	should_fail("699372905347424185", $type, 0);
	should_fail("702131530495087662", $type, 0);
	should_fail("888590873668325996", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 77051283049339393." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '77051283049339393'});
	should_fail("77051283049339393", $type, 0);
	should_fail("362331558821822932", $type, 0);
	should_fail("955585039591778988", $type, 0);
	should_fail("544302254470812148", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('PositiveInteger', {'maxExclusive' => '999999999999999999'});
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("938684679368", $type, 0);
	should_fail("161", $type, 0);
	should_fail("83791567323", $type, 0);
	should_fail("674", $type, 0);
	should_fail("8723668", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("26143554", $type, 0);
	should_fail("3253126293", $type, 0);
	should_fail("985654524774343281", $type, 0);
	should_fail("668", $type, 0);
	should_fail("1517477226927279", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{9}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{9}$)/});
	should_fail("8728865", $type, 0);
	should_fail("5267524", $type, 0);
	should_fail("924122425827362435", $type, 0);
	should_fail("52745613725", $type, 0);
	should_fail("2592", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{13}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{13}$)/});
	should_fail("18361538227259", $type, 0);
	should_fail("238", $type, 0);
	should_fail("865", $type, 0);
	should_fail("32458682", $type, 0);
	should_fail("88183", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('PositiveInteger', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_fail("67822567", $type, 0);
	should_fail("662", $type, 0);
	should_fail("4542", $type, 0);
	should_fail("5268746", $type, 0);
	should_fail("455576", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['89425355401952721','887680011527414','9640188','655587','66','63297','311','98622','355626345463206150']});
	should_fail("449018306605672990", $type, 0);
	should_fail("838199422666880299", $type, 0);
	should_fail("838199422666880299", $type, 0);
	should_fail("838199422666880299", $type, 0);
	should_fail("231700685040938770", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['25429839','8115610159877','483194965216','2979764','208947282923','2051075329','7825']});
	should_fail("30345251576797794", $type, 0);
	should_fail("835629896067205390", $type, 0);
	should_fail("933075754619171359", $type, 0);
	should_fail("371963561942588505", $type, 0);
	should_fail("933075754619171359", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['909089889806','4206487177','67271116222315','828','12484','2716638065015443']});
	should_fail("648184620210752848", $type, 0);
	should_fail("192172868942828590", $type, 0);
	should_fail("397325780006547835", $type, 0);
	should_fail("312762109656851694", $type, 0);
	should_fail("889380911552340446", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['529720439','131717044209','670','5803','792157356069878']});
	should_fail("50064529409591608", $type, 0);
	should_fail("528478019669675447", $type, 0);
	should_fail("407042767729179355", $type, 0);
	should_fail("600985861594698578", $type, 0);
	should_fail("929306415722023325", $type, 0);
	done_testing;
};

subtest "Type atomic/positiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('PositiveInteger', {'enumeration' => ['18','945','922540711065','466381','49453438244','55786266586','6535483','343049990794353','799695914569401']});
	should_fail("645640079662813559", $type, 0);
	should_fail("941561360696071657", $type, 0);
	should_fail("214611027314337455", $type, 0);
	should_fail("824272384129683954", $type, 0);
	should_fail("414831628296158383", $type, 0);
	done_testing;
};

done_testing;

