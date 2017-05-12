use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '0'});
	should_pass("1", $type, 0);
	should_pass("579421924029281942", $type, 0);
	should_pass("219905673220316289", $type, 0);
	should_pass("825556724778076955", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 853655586043630230." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '853655586043630230'});
	should_pass("853655586043630231", $type, 0);
	should_pass("942139671139083756", $type, 0);
	should_pass("942175964599979620", $type, 0);
	should_pass("937601013341671843", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 278671410676320174." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '278671410676320174'});
	should_pass("278671410676320175", $type, 0);
	should_pass("702417656416904009", $type, 0);
	should_pass("320678524002397993", $type, 0);
	should_pass("975565089788066280", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 595843373185442780." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '595843373185442780'});
	should_pass("595843373185442781", $type, 0);
	should_pass("953273142321915308", $type, 0);
	should_pass("817253934811455311", $type, 0);
	should_pass("983718955254806591", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '999999999999999998'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '0'});
	should_pass("0", $type, 0);
	should_pass("41007894529837773", $type, 0);
	should_pass("702305597604277131", $type, 0);
	should_pass("95182362152875343", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 846028599370221122." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '846028599370221122'});
	should_pass("846028599370221122", $type, 0);
	should_pass("858920554078437206", $type, 0);
	should_pass("868333972315695196", $type, 0);
	should_pass("854285391376024437", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 842438235652469335." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '842438235652469335'});
	should_pass("842438235652469335", $type, 0);
	should_pass("941589841735488982", $type, 0);
	should_pass("937796290481633731", $type, 0);
	should_pass("882381498356502105", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 237916309768272493." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '237916309768272493'});
	should_pass("237916309768272493", $type, 0);
	should_pass("808647780058454955", $type, 0);
	should_pass("918974327612490334", $type, 0);
	should_pass("330533892042496564", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '999999999999999999'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '1'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 621144438259934594." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '621144438259934594'});
	should_pass("0", $type, 0);
	should_pass("201791954294354993", $type, 0);
	should_pass("191571782779087926", $type, 0);
	should_pass("100689026846308507", $type, 0);
	should_pass("621144438259934593", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 114762413382550444." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '114762413382550444'});
	should_pass("0", $type, 0);
	should_pass("63464628654103891", $type, 0);
	should_pass("22848637588725746", $type, 0);
	should_pass("104871003695373474", $type, 0);
	should_pass("114762413382550443", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 146493734340271798." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '146493734340271798'});
	should_pass("0", $type, 0);
	should_pass("106269794730729926", $type, 0);
	should_pass("111591154715930884", $type, 0);
	should_pass("41067703125806682", $type, 0);
	should_pass("146493734340271797", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '999999999999999999'});
	should_pass("0", $type, 0);
	should_pass("450417699601756592", $type, 0);
	should_pass("6767563515241548", $type, 0);
	should_pass("42409174718375575", $type, 0);
	should_pass("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '0'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 183206970010490244." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '183206970010490244'});
	should_pass("0", $type, 0);
	should_pass("106622141242831681", $type, 0);
	should_pass("118968621288518129", $type, 0);
	should_pass("45894558483907457", $type, 0);
	should_pass("183206970010490244", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 126060676543225391." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '126060676543225391'});
	should_pass("0", $type, 0);
	should_pass("87379499370975988", $type, 0);
	should_pass("25750459121279535", $type, 0);
	should_pass("14433512623924316", $type, 0);
	should_pass("126060676543225391", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 501388613203794019." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '501388613203794019'});
	should_pass("0", $type, 0);
	should_pass("308691166761711236", $type, 0);
	should_pass("112916681063706516", $type, 0);
	should_pass("302566782287082417", $type, 0);
	should_pass("501388613203794019", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 999999999999999999." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '999999999999999999'});
	should_pass("0", $type, 0);
	should_pass("935130467038026934", $type, 0);
	should_pass("472974001380600860", $type, 0);
	should_pass("474969679238704811", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('UnsignedLong', {'fractionDigits' => '0'});
	should_pass("0", $type, 0);
	should_pass("163428080161349797", $type, 0);
	should_pass("968661288039707745", $type, 0);
	should_pass("666571856464760025", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '1'});
	should_pass("5", $type, 0);
	should_pass("5", $type, 0);
	should_pass("1", $type, 0);
	should_pass("5", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '5'});
	should_pass("7", $type, 0);
	should_pass("12", $type, 0);
	should_pass("196", $type, 0);
	should_pass("5786", $type, 0);
	should_pass("17609", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '9'});
	should_pass("4", $type, 0);
	should_pass("351", $type, 0);
	should_pass("23474", $type, 0);
	should_pass("3788647", $type, 0);
	should_pass("755984772", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '13'});
	should_pass("8", $type, 0);
	should_pass("1951", $type, 0);
	should_pass("7799326", $type, 0);
	should_pass("3329204877", $type, 0);
	should_pass("3382473510617", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '18'});
	should_pass("1", $type, 0);
	should_pass("60939", $type, 0);
	should_pass("353491186", $type, 0);
	should_pass("4740096172026", $type, 0);
	should_pass("785697261776857178", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("8", $type, 0);
	should_pass("8", $type, 0);
	should_pass("5", $type, 0);
	should_pass("5", $type, 0);
	should_pass("5", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("44186", $type, 0);
	should_pass("48744", $type, 0);
	should_pass("32321", $type, 0);
	should_pass("35523", $type, 0);
	should_pass("85477", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{9}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{9}$)/});
	should_pass("357386454", $type, 0);
	should_pass("428648357", $type, 0);
	should_pass("644555788", $type, 0);
	should_pass("495528158", $type, 0);
	should_pass("699948339", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{13}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{13}$)/});
	should_pass("2373271823545", $type, 0);
	should_pass("2589651918243", $type, 0);
	should_pass("5147455727632", $type, 0);
	should_pass("4556844658222", $type, 0);
	should_pass("5445757533925", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_pass("916127516267662627", $type, 0);
	should_pass("964523682364156541", $type, 0);
	should_pass("966625142267332424", $type, 0);
	should_pass("913784361723264886", $type, 0);
	should_pass("917217432147464684", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['235157797394','2841737','6246890837920823','502437096339080','475868893660','69228431818957325','16']});
	should_pass("475868893660", $type, 0);
	should_pass("475868893660", $type, 0);
	should_pass("69228431818957325", $type, 0);
	should_pass("6246890837920823", $type, 0);
	should_pass("2841737", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['840115845','2874238170314','355386265673274248','37531498438491484','92597973','320','9340658324154','224645440232296156']});
	should_pass("355386265673274248", $type, 0);
	should_pass("840115845", $type, 0);
	should_pass("37531498438491484", $type, 0);
	should_pass("320", $type, 0);
	should_pass("320", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['760056434','33505897371058979','38','492728752144644066','7037409938820924','51135955','48185','5876730603']});
	should_pass("33505897371058979", $type, 0);
	should_pass("48185", $type, 0);
	should_pass("48185", $type, 0);
	should_pass("38", $type, 0);
	should_pass("51135955", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['10','1737393204819','8333904222','5093784','50511429','602699130']});
	should_pass("5093784", $type, 0);
	should_pass("10", $type, 0);
	should_pass("1737393204819", $type, 0);
	should_pass("50511429", $type, 0);
	should_pass("8333904222", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['47','62233091384207','9211859','81098772','2880505374436178','858510565604495']});
	should_pass("858510565604495", $type, 0);
	should_pass("62233091384207", $type, 0);
	should_pass("9211859", $type, 0);
	should_pass("47", $type, 0);
	should_pass("62233091384207", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('UnsignedLong', {'whiteSpace' => 'collapse'});
	should_pass("0", $type, 0);
	should_pass("515074060769636132", $type, 0);
	should_pass("636981916365820465", $type, 0);
	should_pass("671551779918335921", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 607303985250778221." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '607303985250778221'});
	should_fail("0", $type, 0);
	should_fail("78776965077975312", $type, 0);
	should_fail("333626116185448486", $type, 0);
	should_fail("176760580557294792", $type, 0);
	should_fail("607303985250778220", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 475565976977797121." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '475565976977797121'});
	should_fail("0", $type, 0);
	should_fail("243057859851789813", $type, 0);
	should_fail("350287480877992018", $type, 0);
	should_fail("228617340624930809", $type, 0);
	should_fail("475565976977797120", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 78231575228674965." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '78231575228674965'});
	should_fail("0", $type, 0);
	should_fail("64436704482788751", $type, 0);
	should_fail("70479407485482966", $type, 0);
	should_fail("36771734124550700", $type, 0);
	should_fail("78231575228674964", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 227623669414460438." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '227623669414460438'});
	should_fail("0", $type, 0);
	should_fail("212874377782275639", $type, 0);
	should_fail("195872563971949804", $type, 0);
	should_fail("219070887195480277", $type, 0);
	should_fail("227623669414460437", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('UnsignedLong', {'minInclusive' => '999999999999999999'});
	should_fail("0", $type, 0);
	should_fail("428678212178694172", $type, 0);
	should_fail("24363826435765512", $type, 0);
	should_fail("162032948824023303", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '0'});
	should_fail("1", $type, 0);
	should_fail("378536898276589872", $type, 0);
	should_fail("940884396243847", $type, 0);
	should_fail("631245973550001892", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 658823762719767058." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '658823762719767058'});
	should_fail("658823762719767059", $type, 0);
	should_fail("937697798837375450", $type, 0);
	should_fail("786346002052533289", $type, 0);
	should_fail("858194201256232558", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 716865919719541721." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '716865919719541721'});
	should_fail("716865919719541722", $type, 0);
	should_fail("957126819824961752", $type, 0);
	should_fail("881387289577164257", $type, 0);
	should_fail("939625894887129164", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 456868453150915620." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '456868453150915620'});
	should_fail("456868453150915621", $type, 0);
	should_fail("900842282656852195", $type, 0);
	should_fail("550194434556833235", $type, 0);
	should_fail("586332526617090104", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxInclusive with value 988150031519812287." => sub {
	my $type = mk_type('UnsignedLong', {'maxInclusive' => '988150031519812287'});
	should_fail("988150031519812288", $type, 0);
	should_fail("989538850324977517", $type, 0);
	should_fail("990718628014227246", $type, 0);
	should_fail("996605064728778116", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '1'});
	should_fail("71", $type, 0);
	should_fail("832264", $type, 0);
	should_fail("3620876346", $type, 0);
	should_fail("53421877661367", $type, 0);
	should_fail("771132081176184346", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '4'});
	should_fail("62708", $type, 0);
	should_fail("52091547", $type, 0);
	should_fail("21797978661", $type, 0);
	should_fail("61362145742181", $type, 0);
	should_fail("276751123244023818", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '7'});
	should_fail("17624365", $type, 0);
	should_fail("8895534872", $type, 0);
	should_fail("712385674179", $type, 0);
	should_fail("66157908224326", $type, 0);
	should_fail("216307197451817467", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '10'});
	should_fail("23693737755", $type, 0);
	should_fail("829142574498", $type, 0);
	should_fail("3984431563046", $type, 0);
	should_fail("37945665144127", $type, 0);
	should_fail("816782121715147780", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('UnsignedLong', {'totalDigits' => '13'});
	should_fail("41311256703476", $type, 0);
	should_fail("473130671135359", $type, 0);
	should_fail("7918868129853453", $type, 0);
	should_fail("17767433537356947", $type, 0);
	should_fail("284524557405854053", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '0'});
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 537563135329115037." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '537563135329115037'});
	should_fail("0", $type, 0);
	should_fail("149267670039196492", $type, 0);
	should_fail("272644907807817373", $type, 0);
	should_fail("318108153653346079", $type, 0);
	should_fail("537563135329115037", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 297022948594505064." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '297022948594505064'});
	should_fail("0", $type, 0);
	should_fail("78409358642214020", $type, 0);
	should_fail("72537417730959616", $type, 0);
	should_fail("175201384554719027", $type, 0);
	should_fail("297022948594505064", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 789396117357098912." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '789396117357098912'});
	should_fail("0", $type, 0);
	should_fail("35050767997415899", $type, 0);
	should_fail("139779438068786013", $type, 0);
	should_fail("541648064951068808", $type, 0);
	should_fail("789396117357098912", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('UnsignedLong', {'minExclusive' => '999999999999999998'});
	should_fail("0", $type, 0);
	should_fail("174557464349445967", $type, 0);
	should_fail("43446029967720511", $type, 0);
	should_fail("73036724432510968", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '1'});
	should_fail("1", $type, 0);
	should_fail("710666380484064718", $type, 0);
	should_fail("848584659967298925", $type, 0);
	should_fail("291397251626248854", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 237922228245894263." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '237922228245894263'});
	should_fail("237922228245894263", $type, 0);
	should_fail("895682688487357889", $type, 0);
	should_fail("776950032702901923", $type, 0);
	should_fail("547019997097664011", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 94265169216393830." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '94265169216393830'});
	should_fail("94265169216393830", $type, 0);
	should_fail("586099638443715153", $type, 0);
	should_fail("437110086258198767", $type, 0);
	should_fail("841558355233551889", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 438210007279301816." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '438210007279301816'});
	should_fail("438210007279301816", $type, 0);
	should_fail("616321475942507545", $type, 0);
	should_fail("747314011206960606", $type, 0);
	should_fail("733560886475558485", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('UnsignedLong', {'maxExclusive' => '999999999999999999'});
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("5735663989573639", $type, 0);
	should_fail("869", $type, 0);
	should_fail("45674", $type, 0);
	should_fail("6485", $type, 0);
	should_fail("98545644754", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("79299555848824331", $type, 0);
	should_fail("615", $type, 0);
	should_fail("87", $type, 0);
	should_fail("874877689621425", $type, 0);
	should_fail("324728684982", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{9}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{9}$)/});
	should_fail("47686618", $type, 0);
	should_fail("3532", $type, 0);
	should_fail("86488", $type, 0);
	should_fail("57677887556458587", $type, 0);
	should_fail("56625223858", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{13}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{13}$)/});
	should_fail("731645", $type, 0);
	should_fail("488", $type, 0);
	should_fail("78", $type, 0);
	should_fail("4545298", $type, 0);
	should_fail("8256685967", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('UnsignedLong', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_fail("482", $type, 0);
	should_fail("427746296", $type, 0);
	should_fail("56483629", $type, 0);
	should_fail("4617386", $type, 0);
	should_fail("15182589862779444", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['7308','4325153467105500','6268632802106','243912','451936956','58']});
	should_fail("847636461691905872", $type, 0);
	should_fail("255989132628767989", $type, 0);
	should_fail("112195906170641679", $type, 0);
	should_fail("258011567247514616", $type, 0);
	should_fail("317350495789223363", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['2164519010239559','872271','9238275371','6932','464535192527820','6820','8017891378905219']});
	should_fail("327277750272195299", $type, 0);
	should_fail("327277750272195299", $type, 0);
	should_fail("629528569691124139", $type, 0);
	should_fail("327277750272195299", $type, 0);
	should_fail("674079386681194602", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['942975980323','161867888670080','206707139691233','40464','41784358560019274','14986736','915079697482']});
	should_fail("493755646805543401", $type, 0);
	should_fail("703130363684031033", $type, 0);
	should_fail("419931190896128958", $type, 0);
	should_fail("497867106796829549", $type, 0);
	should_fail("497867106796829549", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['9181298332184532','84658754203403474','827','2601075','29658436616262884','2632093071072183']});
	should_fail("199959556769777946", $type, 0);
	should_fail("95516130866985959", $type, 0);
	should_fail("967601475826953437", $type, 0);
	should_fail("798217836924336453", $type, 0);
	should_fail("996517474663569878", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedLong is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedLong', {'enumeration' => ['34048514759406','545128199921885658','66','9323055976172072','5021048514849938','1790','57380694936332','3225725891','13336181','374']});
	should_fail("234388474600340401", $type, 0);
	should_fail("234388474600340401", $type, 0);
	should_fail("939161833933526034", $type, 0);
	should_fail("234388474600340401", $type, 0);
	should_fail("589967306110707245", $type, 0);
	done_testing;
};

done_testing;

