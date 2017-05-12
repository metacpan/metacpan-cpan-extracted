use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/integer is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '-999999999999999999'});
	should_pass("-999999999999999998", $type, 0);
	should_pass("443137129197984424", $type, 0);
	should_pass("974548584383189585", $type, 0);
	should_pass("-933323119839668311", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value 511594901568435787." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '511594901568435787'});
	should_pass("511594901568435788", $type, 0);
	should_pass("610220741092562958", $type, 0);
	should_pass("836708064607050875", $type, 0);
	should_pass("658348392840525865", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value 389578809107570477." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '389578809107570477'});
	should_pass("389578809107570478", $type, 0);
	should_pass("682131065909218436", $type, 0);
	should_pass("482804737273022810", $type, 0);
	should_pass("914441667137662715", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value 470740450062970382." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '470740450062970382'});
	should_pass("470740450062970383", $type, 0);
	should_pass("662902075507417933", $type, 0);
	should_pass("590924368168927172", $type, 0);
	should_pass("620830740395671088", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '999999999999999998'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-531635689142616829", $type, 0);
	should_pass("-585408758799392136", $type, 0);
	should_pass("745573427013310751", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 156487900906511434." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '156487900906511434'});
	should_pass("156487900906511434", $type, 0);
	should_pass("600191706710963948", $type, 0);
	should_pass("408597210565453406", $type, 0);
	should_pass("322374839388900638", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value -362471093580558400." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '-362471093580558400'});
	should_pass("-362471093580558400", $type, 0);
	should_pass("506504656626137485", $type, 0);
	should_pass("403237895164793885", $type, 0);
	should_pass("381039479548217691", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value -183640263935870295." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '-183640263935870295'});
	should_pass("-183640263935870295", $type, 0);
	should_pass("429867068360666903", $type, 0);
	should_pass("340717798352538690", $type, 0);
	should_pass("214286893239231791", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '999999999999999999'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-999999999999999998'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -863230876206589446." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-863230876206589446'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-984910341015155393", $type, 0);
	should_pass("-870742508782352781", $type, 0);
	should_pass("-903545016129904603", $type, 0);
	should_pass("-863230876206589447", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value 549869808681548999." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '549869808681548999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-787539741001840193", $type, 0);
	should_pass("-255803148941878739", $type, 0);
	should_pass("-639833227964826918", $type, 0);
	should_pass("549869808681548998", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -839533034801862807." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-839533034801862807'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-904217810162270606", $type, 0);
	should_pass("-975833234751130778", $type, 0);
	should_pass("-948658638815220892", $type, 0);
	should_pass("-839533034801862808", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("968427442786447432", $type, 0);
	should_pass("-927768633139940622", $type, 0);
	should_pass("-392022443438005962", $type, 0);
	should_pass("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 828008406281169228." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '828008406281169228'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-480145976733018877", $type, 0);
	should_pass("-198155044675043050", $type, 0);
	should_pass("-449651710856988442", $type, 0);
	should_pass("828008406281169228", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 705179181121327491." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '705179181121327491'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-116826494207499098", $type, 0);
	should_pass("230481006202911111", $type, 0);
	should_pass("95074826745361540", $type, 0);
	should_pass("705179181121327491", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value -2761698266856349." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '-2761698266856349'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-161047999884288548", $type, 0);
	should_pass("-446821181429400256", $type, 0);
	should_pass("-166593548519859024", $type, 0);
	should_pass("-2761698266856349", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("823690339516311319", $type, 0);
	should_pass("978685767674965178", $type, 0);
	should_pass("-530672654045668989", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Integer', {'fractionDigits' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("70613191813607922", $type, 0);
	should_pass("825606520242485152", $type, 0);
	should_pass("662351389368224684", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '1'});
	should_pass("3", $type, 0);
	should_pass("2", $type, 0);
	should_pass("6", $type, 0);
	should_pass("2", $type, 0);
	should_pass("6", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '5'});
	should_pass("1", $type, 0);
	should_pass("13", $type, 0);
	should_pass("392", $type, 0);
	should_pass("3263", $type, 0);
	should_pass("44340", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '9'});
	should_pass("5", $type, 0);
	should_pass("328", $type, 0);
	should_pass("91395", $type, 0);
	should_pass("2427870", $type, 0);
	should_pass("463625194", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '13'});
	should_pass("1", $type, 0);
	should_pass("7382", $type, 0);
	should_pass("6779457", $type, 0);
	should_pass("6180912352", $type, 0);
	should_pass("3307865857649", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '18'});
	should_pass("1", $type, 0);
	should_pass("14506", $type, 0);
	should_pass("121457346", $type, 0);
	should_pass("3683445412166", $type, 0);
	should_pass("495140751164400574", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_pass("-916336264155436366", $type, 0);
	should_pass("-952682614477467412", $type, 0);
	should_pass("-947637432751355373", $type, 0);
	should_pass("-961133431445663578", $type, 0);
	should_pass("-924254345137746455", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_pass("-823666421", $type, 0);
	should_pass("-442642367", $type, 0);
	should_pass("-321934657", $type, 0);
	should_pass("-924385566", $type, 0);
	should_pass("-618594232", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-2", $type, 0);
	should_pass("-7", $type, 0);
	should_pass("-9", $type, 0);
	should_pass("-5", $type, 0);
	should_pass("-8", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("82365", $type, 0);
	should_pass("79898", $type, 0);
	should_pass("33364", $type, 0);
	should_pass("76112", $type, 0);
	should_pass("26887", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_pass("953387635577466672", $type, 0);
	should_pass("956462344852823454", $type, 0);
	should_pass("947511736164636562", $type, 0);
	should_pass("955527688752774616", $type, 0);
	should_pass("925612635728263464", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['-79656589620485973','61','5609571936','-4739709191124','629890508912219','-820','-635117251034','371694697980']});
	should_pass("5609571936", $type, 0);
	should_pass("-4739709191124", $type, 0);
	should_pass("371694697980", $type, 0);
	should_pass("61", $type, 0);
	should_pass("61", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['-648311529','45817917','-54','94122922748785','-246897894064838530','-7816621','-76931211351','1654495802745']});
	should_pass("94122922748785", $type, 0);
	should_pass("-54", $type, 0);
	should_pass("-54", $type, 0);
	should_pass("45817917", $type, 0);
	should_pass("45817917", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['3','522','-34','-685416','-567825257','-451904674315973253']});
	should_pass("522", $type, 0);
	should_pass("-34", $type, 0);
	should_pass("-34", $type, 0);
	should_pass("522", $type, 0);
	should_pass("-567825257", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['-1480745378756','-479','9967661580861324','-21','44','35682594228541431','759297981117']});
	should_pass("-21", $type, 0);
	should_pass("759297981117", $type, 0);
	should_pass("-479", $type, 0);
	should_pass("44", $type, 0);
	should_pass("9967661580861324", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['-165130515156176','-4149','848','86','3411676615506539','42603','499220832']});
	should_pass("-4149", $type, 0);
	should_pass("848", $type, 0);
	should_pass("86", $type, 0);
	should_pass("3411676615506539", $type, 0);
	should_pass("499220832", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Integer', {'whiteSpace' => 'collapse'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("765487259224892246", $type, 0);
	should_pass("784529489867233475", $type, 0);
	should_pass("67939852834455693", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 555633833307218160." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '555633833307218160'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-715375137462915939", $type, 0);
	should_fail("-330293086481657660", $type, 0);
	should_fail("-20439147890683564", $type, 0);
	should_fail("555633833307218159", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 885701465961149291." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '885701465961149291'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-733333145792854732", $type, 0);
	should_fail("503646561312402961", $type, 0);
	should_fail("37750437322319377", $type, 0);
	should_fail("885701465961149290", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 903027701396896364." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '903027701396896364'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("803542756340227002", $type, 0);
	should_fail("-884575287008817597", $type, 0);
	should_fail("-968554962892916587", $type, 0);
	should_fail("903027701396896363", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 283850128955389857." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '283850128955389857'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-981348040158314034", $type, 0);
	should_fail("-108551497634576688", $type, 0);
	should_fail("-52284006405687333", $type, 0);
	should_fail("283850128955389856", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Integer', {'minInclusive' => '999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("915231012652328866", $type, 0);
	should_fail("-1842156205751122", $type, 0);
	should_fail("-774880558353902237", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '-999999999999999999'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("732627831192335320", $type, 0);
	should_fail("102989881653762438", $type, 0);
	should_fail("343045546112201282", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 579644983036442961." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '579644983036442961'});
	should_fail("579644983036442962", $type, 0);
	should_fail("657783372604533621", $type, 0);
	should_fail("892814218656800078", $type, 0);
	should_fail("976683336572491260", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 879158057178991646." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '879158057178991646'});
	should_fail("879158057178991647", $type, 0);
	should_fail("957210626799168633", $type, 0);
	should_fail("948775841289909504", $type, 0);
	should_fail("924521657636632656", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 514914181641328960." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '514914181641328960'});
	should_fail("514914181641328961", $type, 0);
	should_fail("546412662884414317", $type, 0);
	should_fail("984544185618551293", $type, 0);
	should_fail("891200472113873434", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxInclusive with value 987717400733315819." => sub {
	my $type = mk_type('Integer', {'maxInclusive' => '987717400733315819'});
	should_fail("987717400733315820", $type, 0);
	should_fail("998982291238848384", $type, 0);
	should_fail("988147725447667619", $type, 0);
	should_fail("995440855248586341", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '1'});
	should_fail("73", $type, 0);
	should_fail("769239", $type, 0);
	should_fail("3283247286", $type, 0);
	should_fail("28350621311206", $type, 0);
	should_fail("235172957253454087", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '4'});
	should_fail("62917", $type, 0);
	should_fail("37332132", $type, 0);
	should_fail("33541623096", $type, 0);
	should_fail("26653195820701", $type, 0);
	should_fail("436943262590675951", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '7'});
	should_fail("83731185", $type, 0);
	should_fail("7824493436", $type, 0);
	should_fail("423631318782", $type, 0);
	should_fail("37155925877143", $type, 0);
	should_fail("622613398826468318", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '10'});
	should_fail("73816310381", $type, 0);
	should_fail("872704113788", $type, 0);
	should_fail("6843138681342", $type, 0);
	should_fail("87437784153102", $type, 0);
	should_fail("111482155734837965", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('Integer', {'totalDigits' => '13'});
	should_fail("76486620136657", $type, 0);
	should_fail("881113724560259", $type, 0);
	should_fail("7847781334630603", $type, 0);
	should_fail("79384111427118245", $type, 0);
	should_fail("235339218946921455", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '-999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value -438857029232744943." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '-438857029232744943'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-706516304210049812", $type, 0);
	should_fail("-587275362264587543", $type, 0);
	should_fail("-811308817075634922", $type, 0);
	should_fail("-438857029232744943", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value 520623083761981407." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '520623083761981407'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-369704743268721243", $type, 0);
	should_fail("431295840769552640", $type, 0);
	should_fail("-899920080041305242", $type, 0);
	should_fail("520623083761981407", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value -803324837597181761." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '-803324837597181761'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-979574777898465747", $type, 0);
	should_fail("-847977457228131287", $type, 0);
	should_fail("-869245724557926333", $type, 0);
	should_fail("-803324837597181761", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('Integer', {'minExclusive' => '999999999999999998'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-609931933249433066", $type, 0);
	should_fail("-366111682540258165", $type, 0);
	should_fail("-974096115222225610", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-999999999999999998'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-457591284603875657", $type, 0);
	should_fail("277743723766642247", $type, 0);
	should_fail("-945199490913345428", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -740625800233241758." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-740625800233241758'});
	should_fail("-740625800233241758", $type, 0);
	should_fail("398541088728751173", $type, 0);
	should_fail("-547997326204181850", $type, 0);
	should_fail("-288328762100017528", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -587018553452636869." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-587018553452636869'});
	should_fail("-587018553452636869", $type, 0);
	should_fail("82097550327076279", $type, 0);
	should_fail("361640725837125523", $type, 0);
	should_fail("-490115177088915028", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value -343370478631694008." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '-343370478631694008'});
	should_fail("-343370478631694008", $type, 0);
	should_fail("161483662816734775", $type, 0);
	should_fail("460404257832331682", $type, 0);
	should_fail("101612848955484236", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('Integer', {'maxExclusive' => '999999999999999999'});
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_fail("-2875718525374455", $type, 0);
	should_fail("4428734471785813", $type, 0);
	should_fail("55632973", $type, 0);
	should_fail("-4", $type, 0);
	should_fail("-3452617252542", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_fail("-39682798272352427", $type, 0);
	should_fail("522688578965", $type, 0);
	should_fail("278352863422374", $type, 0);
	should_fail("-922973", $type, 0);
	should_fail("-5523297772154555", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("-615", $type, 0);
	should_fail("252", $type, 0);
	should_fail("-845526", $type, 0);
	should_fail("52887", $type, 0);
	should_fail("54515685354", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("3", $type, 0);
	should_fail("4", $type, 0);
	should_fail("-564172", $type, 0);
	should_fail("6468988464", $type, 0);
	should_fail("19938571382266", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('Integer', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_fail("3765", $type, 0);
	should_fail("-3163464278", $type, 0);
	should_fail("-36284471451", $type, 0);
	should_fail("146557", $type, 0);
	should_fail("-41468", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['-152','95','25385971775262072','-2413740','-7','440146783175242806','-90869253371','2457839','-12','-866988040697697415']});
	should_fail("429432980408758879", $type, 0);
	should_fail("625583585677498054", $type, 0);
	should_fail("429432980408758879", $type, 0);
	should_fail("419065458728186345", $type, 0);
	should_fail("-820591559414092452", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['8785763494850','950846866884093','-32589','-5354358','-374','2032211972695']});
	should_fail("182392902047340266", $type, 0);
	should_fail("350482891421959097", $type, 0);
	should_fail("-819606813622294482", $type, 0);
	should_fail("77593997135002590", $type, 0);
	should_fail("-988246105259493966", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['5031495120521736','646034','351003417603263','-9184826400789700','-781553476','836','38315088843','-873']});
	should_fail("-450845844618843249", $type, 0);
	should_fail("645472034881447109", $type, 0);
	should_fail("210135983395829173", $type, 0);
	should_fail("-553527799610078252", $type, 0);
	should_fail("-762857802722344046", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['7280808904855','90383064','-88','13185418','97487211','-8801','67176183','-70586615385']});
	should_fail("74575575756274270", $type, 0);
	should_fail("366787906513476480", $type, 0);
	should_fail("490640727365811545", $type, 0);
	should_fail("402439179028029947", $type, 0);
	should_fail("490640727365811545", $type, 0);
	done_testing;
};

subtest "Type atomic/integer is restricted by facet enumeration." => sub {
	my $type = mk_type('Integer', {'enumeration' => ['7980740138073','426','-189337021','-33','504','-417572823','-19146712219589']});
	should_fail("187412487362427881", $type, 0);
	should_fail("515203305113594911", $type, 0);
	should_fail("433049324809725133", $type, 0);
	should_fail("546973724262155513", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

done_testing;

