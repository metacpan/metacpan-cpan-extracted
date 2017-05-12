use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/long is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('Long', {'minExclusive' => '-999999999999999999'});
	should_pass("-999999999999999998", $type, 0);
	should_pass("-438183056062100283", $type, 0);
	should_pass("-730415030775278138", $type, 0);
	should_pass("-75024681958743010", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value 968402995542501752." => sub {
	my $type = mk_type('Long', {'minExclusive' => '968402995542501752'});
	should_pass("968402995542501753", $type, 0);
	should_pass("992032847900994818", $type, 0);
	should_pass("974537720720994502", $type, 0);
	should_pass("986012772750288166", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value 420715981815711347." => sub {
	my $type = mk_type('Long', {'minExclusive' => '420715981815711347'});
	should_pass("420715981815711348", $type, 0);
	should_pass("917335403421977926", $type, 0);
	should_pass("950507687486504889", $type, 0);
	should_pass("782630077344273642", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value -244808889653066019." => sub {
	my $type = mk_type('Long', {'minExclusive' => '-244808889653066019'});
	should_pass("-244808889653066018", $type, 0);
	should_pass("646654461216909232", $type, 0);
	should_pass("992170879059480184", $type, 0);
	should_pass("783790005141873453", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('Long', {'minExclusive' => '999999999999999998'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Long', {'minInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-397938882569509377", $type, 0);
	should_pass("-344267677883061784", $type, 0);
	should_pass("415083628365485290", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value 654371390798063278." => sub {
	my $type = mk_type('Long', {'minInclusive' => '654371390798063278'});
	should_pass("654371390798063278", $type, 0);
	should_pass("876174309598772003", $type, 0);
	should_pass("661591040355611765", $type, 0);
	should_pass("895577718881608925", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value 679423031619886596." => sub {
	my $type = mk_type('Long', {'minInclusive' => '679423031619886596'});
	should_pass("679423031619886596", $type, 0);
	should_pass("913111223216426828", $type, 0);
	should_pass("912510378381782725", $type, 0);
	should_pass("929305182239794686", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value 579451386929251021." => sub {
	my $type = mk_type('Long', {'minInclusive' => '579451386929251021'});
	should_pass("579451386929251021", $type, 0);
	should_pass("902992188127024208", $type, 0);
	should_pass("824874704639240016", $type, 0);
	should_pass("708948875639938824", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Long', {'minInclusive' => '999999999999999999'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '-999999999999999998'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value -562908107193849537." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '-562908107193849537'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-808380194595141275", $type, 0);
	should_pass("-822649479248610771", $type, 0);
	should_pass("-590945378547525183", $type, 0);
	should_pass("-562908107193849538", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value -62970516107334394." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '-62970516107334394'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-270926369799275666", $type, 0);
	should_pass("-365308762022580493", $type, 0);
	should_pass("-882518584237943728", $type, 0);
	should_pass("-62970516107334395", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value -40900034799576711." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '-40900034799576711'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-274843839731028429", $type, 0);
	should_pass("-682373695437848980", $type, 0);
	should_pass("-266120163505469408", $type, 0);
	should_pass("-40900034799576712", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("361579683220858870", $type, 0);
	should_pass("863135773750244748", $type, 0);
	should_pass("-230400793531868153", $type, 0);
	should_pass("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value 472512421492236489." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '472512421492236489'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-543180519732171516", $type, 0);
	should_pass("-106047285186662175", $type, 0);
	should_pass("-561394859984429942", $type, 0);
	should_pass("472512421492236489", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value -319274017545440269." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '-319274017545440269'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-727194004132777993", $type, 0);
	should_pass("-493310300001086924", $type, 0);
	should_pass("-587606438485648919", $type, 0);
	should_pass("-319274017545440269", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value 395309234845914847." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '395309234845914847'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-771424898560677999", $type, 0);
	should_pass("-388165179280097323", $type, 0);
	should_pass("315473587110365078", $type, 0);
	should_pass("395309234845914847", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("779716996244725456", $type, 0);
	should_pass("112284133831870302", $type, 0);
	should_pass("391081913308217287", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Long', {'fractionDigits' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-439678890605573080", $type, 0);
	should_pass("673029236492377779", $type, 0);
	should_pass("-367446140835359757", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Long', {'totalDigits' => '1'});
	should_pass("9", $type, 0);
	should_pass("8", $type, 0);
	should_pass("3", $type, 0);
	should_pass("2", $type, 0);
	should_pass("8", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('Long', {'totalDigits' => '5'});
	should_pass("2", $type, 0);
	should_pass("59", $type, 0);
	should_pass("256", $type, 0);
	should_pass("1881", $type, 0);
	should_pass("87876", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('Long', {'totalDigits' => '9'});
	should_pass("2", $type, 0);
	should_pass("324", $type, 0);
	should_pass("53160", $type, 0);
	should_pass("2241858", $type, 0);
	should_pass("350271868", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('Long', {'totalDigits' => '13'});
	should_pass("7", $type, 0);
	should_pass("1299", $type, 0);
	should_pass("4347514", $type, 0);
	should_pass("7559612718", $type, 0);
	should_pass("1416366976154", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('Long', {'totalDigits' => '18'});
	should_pass("3", $type, 0);
	should_pass("95740", $type, 0);
	should_pass("735611727", $type, 0);
	should_pass("3784148207702", $type, 0);
	should_pass("157826879511434666", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_pass("-986558763664653645", $type, 0);
	should_pass("-913428556433725453", $type, 0);
	should_pass("-973221252533651368", $type, 0);
	should_pass("-943246656652245344", $type, 0);
	should_pass("-956548175456225582", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_pass("-787574922", $type, 0);
	should_pass("-726788351", $type, 0);
	should_pass("-256584684", $type, 0);
	should_pass("-289122472", $type, 0);
	should_pass("-386638897", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-8", $type, 0);
	should_pass("-8", $type, 0);
	should_pass("-7", $type, 0);
	should_pass("-4", $type, 0);
	should_pass("-8", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("43733", $type, 0);
	should_pass("29358", $type, 0);
	should_pass("75414", $type, 0);
	should_pass("66282", $type, 0);
	should_pass("88634", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_pass("934646773752244366", $type, 0);
	should_pass("946663632864638888", $type, 0);
	should_pass("953654543736653615", $type, 0);
	should_pass("946365341267825427", $type, 0);
	should_pass("955717642814452228", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['67417897408','445463702','11686316','-223498733','-5496081750511','-4233583602889']});
	should_pass("11686316", $type, 0);
	should_pass("-5496081750511", $type, 0);
	should_pass("-5496081750511", $type, 0);
	should_pass("445463702", $type, 0);
	should_pass("-5496081750511", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['-60196439767','29044724','528615','-36983185','649699813723','-53330603926218023','-4958442914','-530271545']});
	should_pass("29044724", $type, 0);
	should_pass("-530271545", $type, 0);
	should_pass("-53330603926218023", $type, 0);
	should_pass("-530271545", $type, 0);
	should_pass("-36983185", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['43','-2032980968765','34853718286','-368','80579055795489529','282076','-4722','-12200','4812']});
	should_pass("4812", $type, 0);
	should_pass("-4722", $type, 0);
	should_pass("-2032980968765", $type, 0);
	should_pass("34853718286", $type, 0);
	should_pass("-4722", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['-19024765988335756','-902030968896','698832321694','-245446','62317068276','-52501609699','947653025590775','9289163707500556','-2295090265679','-97146741275']});
	should_pass("-52501609699", $type, 0);
	should_pass("62317068276", $type, 0);
	should_pass("-2295090265679", $type, 0);
	should_pass("947653025590775", $type, 0);
	should_pass("-902030968896", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['-998','1827924515','88745595866','-14260976357358','59419563214914','4468','4631900674078']});
	should_pass("59419563214914", $type, 0);
	should_pass("88745595866", $type, 0);
	should_pass("59419563214914", $type, 0);
	should_pass("88745595866", $type, 0);
	should_pass("-14260976357358", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Long', {'whiteSpace' => 'collapse'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-141811240377451630", $type, 0);
	should_pass("107634268556318302", $type, 0);
	should_pass("-741262037408872975", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value 583792148562175316." => sub {
	my $type = mk_type('Long', {'minInclusive' => '583792148562175316'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("406638238320622626", $type, 0);
	should_fail("-638693120471822479", $type, 0);
	should_fail("-323016043871903592", $type, 0);
	should_fail("583792148562175315", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value -689877964040234158." => sub {
	my $type = mk_type('Long', {'minInclusive' => '-689877964040234158'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-820792054363353774", $type, 0);
	should_fail("-725379333585144926", $type, 0);
	should_fail("-928387095497131129", $type, 0);
	should_fail("-689877964040234159", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value -635039562549570168." => sub {
	my $type = mk_type('Long', {'minInclusive' => '-635039562549570168'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-844669926868859999", $type, 0);
	should_fail("-651482607533091162", $type, 0);
	should_fail("-950390854239020283", $type, 0);
	should_fail("-635039562549570169", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value -217274055791231379." => sub {
	my $type = mk_type('Long', {'minInclusive' => '-217274055791231379'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-967264967922566177", $type, 0);
	should_fail("-527241730293832538", $type, 0);
	should_fail("-902272444411393578", $type, 0);
	should_fail("-217274055791231380", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Long', {'minInclusive' => '999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-4604910092599779", $type, 0);
	should_fail("695824151654512500", $type, 0);
	should_fail("476038958967349045", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '-999999999999999999'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-136550217446477439", $type, 0);
	should_fail("301508639387523258", $type, 0);
	should_fail("165029836242362782", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value 648840685860569087." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '648840685860569087'});
	should_fail("648840685860569088", $type, 0);
	should_fail("870346801180572437", $type, 0);
	should_fail("947290282026430821", $type, 0);
	should_fail("819053053548357647", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value 837276573179478677." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '837276573179478677'});
	should_fail("837276573179478678", $type, 0);
	should_fail("982131744201154708", $type, 0);
	should_fail("878401732190292315", $type, 0);
	should_fail("855806805973112446", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value -231112914202378227." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '-231112914202378227'});
	should_fail("-231112914202378226", $type, 0);
	should_fail("642456873159420352", $type, 0);
	should_fail("209104855015940588", $type, 0);
	should_fail("912184317590979202", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxInclusive with value -716385737637535546." => sub {
	my $type = mk_type('Long', {'maxInclusive' => '-716385737637535546'});
	should_fail("-716385737637535545", $type, 0);
	should_fail("732781777769492545", $type, 0);
	should_fail("531162283326065394", $type, 0);
	should_fail("240919302458363108", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Long', {'totalDigits' => '1'});
	should_fail("61", $type, 0);
	should_fail("352314", $type, 0);
	should_fail("5672867257", $type, 0);
	should_fail("61221375404615", $type, 0);
	should_fail("146672972327691410", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('Long', {'totalDigits' => '4'});
	should_fail("59600", $type, 0);
	should_fail("68323727", $type, 0);
	should_fail("37839894647", $type, 0);
	should_fail("58464689733810", $type, 0);
	should_fail("514834822567682304", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('Long', {'totalDigits' => '7'});
	should_fail("41891153", $type, 0);
	should_fail("3180876051", $type, 0);
	should_fail("356217484246", $type, 0);
	should_fail("15184683016354", $type, 0);
	should_fail("568323046628399965", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('Long', {'totalDigits' => '10'});
	should_fail("62183883927", $type, 0);
	should_fail("454688281764", $type, 0);
	should_fail("4250944564358", $type, 0);
	should_fail("60434747874517", $type, 0);
	should_fail("882271787829559286", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('Long', {'totalDigits' => '13'});
	should_fail("73160554226563", $type, 0);
	should_fail("152523424361917", $type, 0);
	should_fail("7816567088582023", $type, 0);
	should_fail("65585590862232778", $type, 0);
	should_fail("175655245093397441", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('Long', {'minExclusive' => '-999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value 797627372074136696." => sub {
	my $type = mk_type('Long', {'minExclusive' => '797627372074136696'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("571517462213777986", $type, 0);
	should_fail("-828347264457694281", $type, 0);
	should_fail("-932731884480699309", $type, 0);
	should_fail("797627372074136696", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value -425021319963341470." => sub {
	my $type = mk_type('Long', {'minExclusive' => '-425021319963341470'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-821040419442518247", $type, 0);
	should_fail("-693233371923550840", $type, 0);
	should_fail("-460176317465711225", $type, 0);
	should_fail("-425021319963341470", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value -371832791753599733." => sub {
	my $type = mk_type('Long', {'minExclusive' => '-371832791753599733'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-781426192888480178", $type, 0);
	should_fail("-475269055523014805", $type, 0);
	should_fail("-972055299241825914", $type, 0);
	should_fail("-371832791753599733", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('Long', {'minExclusive' => '999999999999999998'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-828451730987506351", $type, 0);
	should_fail("-161134781826219875", $type, 0);
	should_fail("-325521743394460605", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '-999999999999999998'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("422087990407563173", $type, 0);
	should_fail("-339322319330811249", $type, 0);
	should_fail("342669886312905402", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value -75742468208222612." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '-75742468208222612'});
	should_fail("-75742468208222612", $type, 0);
	should_fail("-31400323710645496", $type, 0);
	should_fail("11220641590985134", $type, 0);
	should_fail("913147533063598804", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value 426043137105943214." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '426043137105943214'});
	should_fail("426043137105943214", $type, 0);
	should_fail("499210806298271291", $type, 0);
	should_fail("845897864523529612", $type, 0);
	should_fail("744814266325269324", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value 911347761427307999." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '911347761427307999'});
	should_fail("911347761427307999", $type, 0);
	should_fail("989033144562084456", $type, 0);
	should_fail("944503962585307676", $type, 0);
	should_fail("953828544159003174", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('Long', {'maxExclusive' => '999999999999999999'});
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_fail("523528", $type, 0);
	should_fail("-83453757559438134", $type, 0);
	should_fail("-82864921", $type, 0);
	should_fail("24834653926555265", $type, 0);
	should_fail("5368", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_fail("6643732616", $type, 0);
	should_fail("-872475", $type, 0);
	should_fail("6622853", $type, 0);
	should_fail("-428237977745", $type, 0);
	should_fail("88546941", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("7481741375817", $type, 0);
	should_fail("-24856383", $type, 0);
	should_fail("72534", $type, 0);
	should_fail("-112193385578992", $type, 0);
	should_fail("69519774439863", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("-28847764362258", $type, 0);
	should_fail("-7848246815716", $type, 0);
	should_fail("66448574776", $type, 0);
	should_fail("586544", $type, 0);
	should_fail("-8", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('Long', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_fail("-1448838426", $type, 0);
	should_fail("-13887678695934982", $type, 0);
	should_fail("-4461457", $type, 0);
	should_fail("-61", $type, 0);
	should_fail("2492224547", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['435335836639','-73160366235125895','-1302746405841812','-54864','-32751','81382','650333774190190','34326204']});
	should_fail("-345398431745117306", $type, 0);
	should_fail("127657392041073069", $type, 0);
	should_fail("732130377772227224", $type, 0);
	should_fail("123031806783405084", $type, 0);
	should_fail("-630366862888847245", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['15262','-608069987034146','-4254','460983752307','-47']});
	should_fail("305873581919190229", $type, 0);
	should_fail("201555919457502952", $type, 0);
	should_fail("-777124409677342197", $type, 0);
	should_fail("976496010192487994", $type, 0);
	should_fail("486599881741643702", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['-134062998509662','-18422694','-8','-802079','-3835']});
	should_fail("-279754425781666426", $type, 0);
	should_fail("786134019132565419", $type, 0);
	should_fail("-944473943643886481", $type, 0);
	should_fail("937655730037457501", $type, 0);
	should_fail("-727874622972624506", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['-40336143872','425850','21','-481972798730214','-690116','-217564772649','-15971601822133','-87317753710']});
	should_fail("590935681411644430", $type, 0);
	should_fail("-239453803593872249", $type, 0);
	should_fail("-592225327498727915", $type, 0);
	should_fail("217482413221273817", $type, 0);
	should_fail("443393241210575883", $type, 0);
	done_testing;
};

subtest "Type atomic/long is restricted by facet enumeration." => sub {
	my $type = mk_type('Long', {'enumeration' => ['-8966243961509180','-4333144975','-73798832875597','390','875777023288750','-71']});
	should_fail("229811982042096740", $type, 0);
	should_fail("-814928962517383447", $type, 0);
	should_fail("-822190539041481426", $type, 0);
	should_fail("602607134494231199", $type, 0);
	should_fail("229811982042096740", $type, 0);
	done_testing;
};

done_testing;

