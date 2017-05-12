use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '0'});
	should_pass("1", $type, 0);
	should_pass("1832591814", $type, 0);
	should_pass("1159363342", $type, 0);
	should_pass("2761156808", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 72170852." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '72170852'});
	should_pass("72170853", $type, 0);
	should_pass("667832659", $type, 0);
	should_pass("2383344626", $type, 0);
	should_pass("3725868637", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 2085810236." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '2085810236'});
	should_pass("2085810237", $type, 0);
	should_pass("2739688204", $type, 0);
	should_pass("2494311306", $type, 0);
	should_pass("4000722380", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 4242349370." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '4242349370'});
	should_pass("4242349371", $type, 0);
	should_pass("4258076808", $type, 0);
	should_pass("4267468898", $type, 0);
	should_pass("4284182886", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 4294967294." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '4294967294'});
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '0'});
	should_pass("0", $type, 0);
	should_pass("2266183353", $type, 0);
	should_pass("3817833782", $type, 0);
	should_pass("1739697344", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 3433747195." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '3433747195'});
	should_pass("3433747195", $type, 0);
	should_pass("3749498688", $type, 0);
	should_pass("4141075250", $type, 0);
	should_pass("3867497808", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 2401546713." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '2401546713'});
	should_pass("2401546713", $type, 0);
	should_pass("3115589962", $type, 0);
	should_pass("3761415141", $type, 0);
	should_pass("2817083921", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 2912115668." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '2912115668'});
	should_pass("2912115668", $type, 0);
	should_pass("4109011338", $type, 0);
	should_pass("3088452651", $type, 0);
	should_pass("2961995942", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 4294967295." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '4294967295'});
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '1'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 339569650." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '339569650'});
	should_pass("0", $type, 0);
	should_pass("23046762", $type, 0);
	should_pass("235307581", $type, 0);
	should_pass("334268793", $type, 0);
	should_pass("339569649", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 1539442072." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '1539442072'});
	should_pass("0", $type, 0);
	should_pass("1084249757", $type, 0);
	should_pass("1213056054", $type, 0);
	should_pass("493131837", $type, 0);
	should_pass("1539442071", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 1033689612." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '1033689612'});
	should_pass("0", $type, 0);
	should_pass("939722023", $type, 0);
	should_pass("606292023", $type, 0);
	should_pass("255360374", $type, 0);
	should_pass("1033689611", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 4294967295." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '4294967295'});
	should_pass("0", $type, 0);
	should_pass("401123804", $type, 0);
	should_pass("1160725769", $type, 0);
	should_pass("1186451478", $type, 0);
	should_pass("4294967294", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '0'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 3323681229." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '3323681229'});
	should_pass("0", $type, 0);
	should_pass("2832786672", $type, 0);
	should_pass("518374699", $type, 0);
	should_pass("2045003521", $type, 0);
	should_pass("3323681229", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 637454996." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '637454996'});
	should_pass("0", $type, 0);
	should_pass("278337081", $type, 0);
	should_pass("485072777", $type, 0);
	should_pass("268919441", $type, 0);
	should_pass("637454996", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 3479012164." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '3479012164'});
	should_pass("0", $type, 0);
	should_pass("1016153814", $type, 0);
	should_pass("1811092620", $type, 0);
	should_pass("5643795", $type, 0);
	should_pass("3479012164", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 4294967295." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '4294967295'});
	should_pass("0", $type, 0);
	should_pass("2154216687", $type, 0);
	should_pass("3994448256", $type, 0);
	should_pass("2521119044", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('UnsignedInt', {'fractionDigits' => '0'});
	should_pass("0", $type, 0);
	should_pass("1924287060", $type, 0);
	should_pass("1509728369", $type, 0);
	should_pass("252230610", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '1'});
	should_pass("1", $type, 0);
	should_pass("7", $type, 0);
	should_pass("1", $type, 0);
	should_pass("2", $type, 0);
	should_pass("1", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '3'});
	should_pass("6", $type, 0);
	should_pass("31", $type, 0);
	should_pass("852", $type, 0);
	should_pass("3", $type, 0);
	should_pass("76", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '5'});
	should_pass("3", $type, 0);
	should_pass("63", $type, 0);
	should_pass("958", $type, 0);
	should_pass("3996", $type, 0);
	should_pass("72469", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '7'});
	should_pass("2", $type, 0);
	should_pass("20", $type, 0);
	should_pass("328", $type, 0);
	should_pass("6891", $type, 0);
	should_pass("7727448", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '10'});
	should_pass("8", $type, 0);
	should_pass("255", $type, 0);
	should_pass("33841", $type, 0);
	should_pass("1768503", $type, 0);
	should_pass("1871752173", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("4", $type, 0);
	should_pass("7", $type, 0);
	should_pass("3", $type, 0);
	should_pass("5", $type, 0);
	should_pass("2", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_pass("879", $type, 0);
	should_pass("233", $type, 0);
	should_pass("783", $type, 0);
	should_pass("621", $type, 0);
	should_pass("699", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("68779", $type, 0);
	should_pass("37876", $type, 0);
	should_pass("34638", $type, 0);
	should_pass("48493", $type, 0);
	should_pass("43284", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{7}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{7}$)/});
	should_pass("3384339", $type, 0);
	should_pass("2273743", $type, 0);
	should_pass("6664358", $type, 0);
	should_pass("5263655", $type, 0);
	should_pass("2323319", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{10}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{10}$)/});
	should_pass("4142734124", $type, 0);
	should_pass("4121131161", $type, 0);
	should_pass("4142731174", $type, 0);
	should_pass("4111322122", $type, 0);
	should_pass("4153734111", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['80391676','162','13943339','582','367952057','283609','844']});
	should_pass("582", $type, 0);
	should_pass("283609", $type, 0);
	should_pass("582", $type, 0);
	should_pass("162", $type, 0);
	should_pass("367952057", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['1331474827','25','576176','944130','62','46','5135198','2157977','311']});
	should_pass("2157977", $type, 0);
	should_pass("62", $type, 0);
	should_pass("5135198", $type, 0);
	should_pass("944130", $type, 0);
	should_pass("62", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['47','2421249','90949193','6248','70884037','959','8001','9175']});
	should_pass("2421249", $type, 0);
	should_pass("959", $type, 0);
	should_pass("47", $type, 0);
	should_pass("959", $type, 0);
	should_pass("2421249", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['47','9906','271268','18558','969778623','237992966']});
	should_pass("969778623", $type, 0);
	should_pass("9906", $type, 0);
	should_pass("47", $type, 0);
	should_pass("969778623", $type, 0);
	should_pass("18558", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['34216','276','99184083','7776','6662698','134172074','93114']});
	should_pass("6662698", $type, 0);
	should_pass("276", $type, 0);
	should_pass("7776", $type, 0);
	should_pass("6662698", $type, 0);
	should_pass("34216", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('UnsignedInt', {'whiteSpace' => 'collapse'});
	should_pass("0", $type, 0);
	should_pass("2626359436", $type, 0);
	should_pass("934961103", $type, 0);
	should_pass("1581635374", $type, 0);
	should_pass("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 2976894290." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '2976894290'});
	should_fail("0", $type, 0);
	should_fail("708347188", $type, 0);
	should_fail("1122195078", $type, 0);
	should_fail("174343210", $type, 0);
	should_fail("2976894289", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 1076892208." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '1076892208'});
	should_fail("0", $type, 0);
	should_fail("15441599", $type, 0);
	should_fail("316873262", $type, 0);
	should_fail("459570687", $type, 0);
	should_fail("1076892207", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 2815670596." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '2815670596'});
	should_fail("0", $type, 0);
	should_fail("863588906", $type, 0);
	should_fail("1185750112", $type, 0);
	should_fail("1707302678", $type, 0);
	should_fail("2815670595", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 795920399." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '795920399'});
	should_fail("0", $type, 0);
	should_fail("26358710", $type, 0);
	should_fail("718501086", $type, 0);
	should_fail("657587282", $type, 0);
	should_fail("795920398", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minInclusive with value 4294967295." => sub {
	my $type = mk_type('UnsignedInt', {'minInclusive' => '4294967295'});
	should_fail("0", $type, 0);
	should_fail("2582347832", $type, 0);
	should_fail("3935935285", $type, 0);
	should_fail("1759957870", $type, 0);
	should_fail("4294967294", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '0'});
	should_fail("1", $type, 0);
	should_fail("2539298279", $type, 0);
	should_fail("1594892403", $type, 0);
	should_fail("2572895521", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 1116575447." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '1116575447'});
	should_fail("1116575448", $type, 0);
	should_fail("3876884850", $type, 0);
	should_fail("1663494401", $type, 0);
	should_fail("4066312590", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 3663158687." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '3663158687'});
	should_fail("3663158688", $type, 0);
	should_fail("4112413925", $type, 0);
	should_fail("3777174703", $type, 0);
	should_fail("4282922536", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 1600916644." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '1600916644'});
	should_fail("1600916645", $type, 0);
	should_fail("2909227258", $type, 0);
	should_fail("3587562506", $type, 0);
	should_fail("2235705500", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxInclusive with value 2354971999." => sub {
	my $type = mk_type('UnsignedInt', {'maxInclusive' => '2354971999'});
	should_fail("2354972000", $type, 0);
	should_fail("3033595904", $type, 0);
	should_fail("3931046249", $type, 0);
	should_fail("3724502281", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '1'});
	should_fail("12", $type, 0);
	should_fail("5241", $type, 0);
	should_fail("225238", $type, 0);
	should_fail("57582229", $type, 0);
	should_fail("3694220168", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '2'});
	should_fail("744", $type, 0);
	should_fail("6087", $type, 0);
	should_fail("41606", $type, 0);
	should_fail("575323", $type, 0);
	should_fail("3207575552", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '3'});
	should_fail("8438", $type, 0);
	should_fail("17357", $type, 0);
	should_fail("587817", $type, 0);
	should_fail("4633572", $type, 0);
	should_fail("3521971725", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '4'});
	should_fail("47001", $type, 0);
	should_fail("823342", $type, 0);
	should_fail("7164125", $type, 0);
	should_fail("81398613", $type, 0);
	should_fail("1850477094", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('UnsignedInt', {'totalDigits' => '5'});
	should_fail("147284", $type, 0);
	should_fail("7452558", $type, 0);
	should_fail("64885333", $type, 0);
	should_fail("536553013", $type, 0);
	should_fail("3684558235", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '0'});
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 1657198128." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '1657198128'});
	should_fail("0", $type, 0);
	should_fail("1502453737", $type, 0);
	should_fail("308967366", $type, 0);
	should_fail("1308358655", $type, 0);
	should_fail("1657198128", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 38976714." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '38976714'});
	should_fail("0", $type, 0);
	should_fail("9799632", $type, 0);
	should_fail("17346221", $type, 0);
	should_fail("12100146", $type, 0);
	should_fail("38976714", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 1759037912." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '1759037912'});
	should_fail("0", $type, 0);
	should_fail("432160371", $type, 0);
	should_fail("807014465", $type, 0);
	should_fail("1141429462", $type, 0);
	should_fail("1759037912", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet minExclusive with value 4294967294." => sub {
	my $type = mk_type('UnsignedInt', {'minExclusive' => '4294967294'});
	should_fail("0", $type, 0);
	should_fail("908662424", $type, 0);
	should_fail("712642291", $type, 0);
	should_fail("2489818821", $type, 0);
	should_fail("4294967294", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '1'});
	should_fail("1", $type, 0);
	should_fail("1139629629", $type, 0);
	should_fail("315140948", $type, 0);
	should_fail("3228964435", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 3352947019." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '3352947019'});
	should_fail("3352947019", $type, 0);
	should_fail("3680518649", $type, 0);
	should_fail("3578123117", $type, 0);
	should_fail("4203755449", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 205769955." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '205769955'});
	should_fail("205769955", $type, 0);
	should_fail("297207523", $type, 0);
	should_fail("2475770327", $type, 0);
	should_fail("551666909", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 1758636711." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '1758636711'});
	should_fail("1758636711", $type, 0);
	should_fail("4028713122", $type, 0);
	should_fail("3768820111", $type, 0);
	should_fail("4142208651", $type, 0);
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet maxExclusive with value 4294967295." => sub {
	my $type = mk_type('UnsignedInt', {'maxExclusive' => '4294967295'});
	should_fail("4294967295", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("24292767", $type, 0);
	should_fail("486586812", $type, 0);
	should_fail("47856523", $type, 0);
	should_fail("4663127", $type, 0);
	should_fail("322455443", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_fail("4867", $type, 0);
	should_fail("4132656154", $type, 0);
	should_fail("25552718", $type, 0);
	should_fail("245348", $type, 0);
	should_fail("36", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("4133716174", $type, 0);
	should_fail("2571", $type, 0);
	should_fail("254428812", $type, 0);
	should_fail("959824", $type, 0);
	should_fail("2662511", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{7}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{7}$)/});
	should_fail("63283426", $type, 0);
	should_fail("61451847", $type, 0);
	should_fail("231944", $type, 0);
	should_fail("5882", $type, 0);
	should_fail("36937417", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet pattern with value \\d{10}." => sub {
	my $type = mk_type('UnsignedInt', {'pattern' => qr/(?ms:^\d{10}$)/});
	should_fail("4494", $type, 0);
	should_fail("3435967", $type, 0);
	should_fail("34252", $type, 0);
	should_fail("4365", $type, 0);
	should_fail("6395", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['383144','253360','99022','503178914','3044','65','577588']});
	should_fail("2360970273", $type, 0);
	should_fail("1229510359", $type, 0);
	should_fail("4027828735", $type, 0);
	should_fail("5131048", $type, 0);
	should_fail("2956850759", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['95667959','252634302','24272511','629494','2239','20054322','356367143','89','738818346','9915']});
	should_fail("627887621", $type, 0);
	should_fail("2473466232", $type, 0);
	should_fail("2473466232", $type, 0);
	should_fail("2473466232", $type, 0);
	should_fail("1911547289", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['1689','917','80','8523258','5050849','1808871','89649934','410760']});
	should_fail("4192360433", $type, 0);
	should_fail("119479023", $type, 0);
	should_fail("2645499376", $type, 0);
	should_fail("3252138589", $type, 0);
	should_fail("4163719111", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['888394','5','59489814','65655','85','4294967295','67788058','20588978','250961411']});
	should_fail("1746307776", $type, 0);
	should_fail("1228359153", $type, 0);
	should_fail("4225339663", $type, 0);
	should_fail("1558294678", $type, 0);
	should_fail("1558294678", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedInt is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedInt', {'enumeration' => ['649','78','161','3575','2800719','27954','4294967295']});
	should_fail("1385287528", $type, 0);
	should_fail("2035203914", $type, 0);
	should_fail("2566228164", $type, 0);
	should_fail("3746628266", $type, 0);
	should_fail("339657124", $type, 0);
	done_testing;
};

done_testing;

