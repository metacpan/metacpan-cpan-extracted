use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-999999999999999999'});
	should_pass("-999999999999999998", $type, 0);
	should_pass("-818329512491933862", $type, 0);
	should_pass("-664485275263920426", $type, 0);
	should_pass("-740995979813640402", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -435976618086570511." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-435976618086570511'});
	should_pass("-435976618086570510", $type, 0);
	should_pass("-53919386640509476", $type, 0);
	should_pass("-225930627153700998", $type, 0);
	should_pass("-410736536149267286", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -900435039333670416." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-900435039333670416'});
	should_pass("-900435039333670415", $type, 0);
	should_pass("-211525512703915963", $type, 0);
	should_pass("-460069685368384428", $type, 0);
	should_pass("-339377387206743076", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -495295756372066909." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-495295756372066909'});
	should_pass("-495295756372066908", $type, 0);
	should_pass("-295243202700852519", $type, 0);
	should_pass("-325162158016492101", $type, 0);
	should_pass("-211876872550324198", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -2." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-2'});
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -999999999999999999." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-485746829700231197", $type, 0);
	should_pass("-805738000490561322", $type, 0);
	should_pass("-649849799367292035", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -440277848538184635." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-440277848538184635'});
	should_pass("-440277848538184635", $type, 0);
	should_pass("-9697736005135568", $type, 0);
	should_pass("-7632350895753607", $type, 0);
	should_pass("-7379248125433725", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -539945622984702833." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-539945622984702833'});
	should_pass("-539945622984702833", $type, 0);
	should_pass("-459526312298212931", $type, 0);
	should_pass("-218061040862121", $type, 0);
	should_pass("-259667994395542348", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -947674826094804355." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-947674826094804355'});
	should_pass("-947674826094804355", $type, 0);
	should_pass("-312579074702648793", $type, 0);
	should_pass("-68451092930283082", $type, 0);
	should_pass("-552221550562783780", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -1." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-1'});
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-999999999999999998'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -866521354558973720." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-866521354558973720'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-954880220749267418", $type, 0);
	should_pass("-962884675120571730", $type, 0);
	should_pass("-971148733548590286", $type, 0);
	should_pass("-866521354558973721", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -184935339155753553." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-184935339155753553'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-866443582381708492", $type, 0);
	should_pass("-414615380928389037", $type, 0);
	should_pass("-515743231902319800", $type, 0);
	should_pass("-184935339155753554", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -572450131914860271." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-572450131914860271'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-934954204455349911", $type, 0);
	should_pass("-685813274737660968", $type, 0);
	should_pass("-626892420609938489", $type, 0);
	should_pass("-572450131914860272", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -1." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-1'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-6016271999369606", $type, 0);
	should_pass("-386788852511558923", $type, 0);
	should_pass("-275298847842965989", $type, 0);
	should_pass("-2", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -922333322214573646." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-922333322214573646'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-932149789525735583", $type, 0);
	should_pass("-951946305725515999", $type, 0);
	should_pass("-963767697290822707", $type, 0);
	should_pass("-922333322214573646", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -34749374507754505." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-34749374507754505'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-523820368232342381", $type, 0);
	should_pass("-884126792645226095", $type, 0);
	should_pass("-745050149979268620", $type, 0);
	should_pass("-34749374507754505", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -666057423564200834." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-666057423564200834'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-859536992360054974", $type, 0);
	should_pass("-864728476120857385", $type, 0);
	should_pass("-762359260826851497", $type, 0);
	should_pass("-666057423564200834", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -1." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-1'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-318673160689050494", $type, 0);
	should_pass("-393749913908599924", $type, 0);
	should_pass("-614358525691746648", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('NegativeInteger', {'fractionDigits' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-171881324764382448", $type, 0);
	should_pass("-244720973181966839", $type, 0);
	should_pass("-301756094648375273", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '1'});
	should_pass("-2", $type, 0);
	should_pass("-3", $type, 0);
	should_pass("-6", $type, 0);
	should_pass("-6", $type, 0);
	should_pass("-4", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '5'});
	should_pass("-2", $type, 0);
	should_pass("-16", $type, 0);
	should_pass("-294", $type, 0);
	should_pass("-1193", $type, 0);
	should_pass("-73267", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '9'});
	should_pass("-4", $type, 0);
	should_pass("-177", $type, 0);
	should_pass("-83160", $type, 0);
	should_pass("-3465945", $type, 0);
	should_pass("-987457807", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '13'});
	should_pass("-4", $type, 0);
	should_pass("-5271", $type, 0);
	should_pass("-3126639", $type, 0);
	should_pass("-4597578363", $type, 0);
	should_pass("-7247487111835", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '18'});
	should_pass("-5", $type, 0);
	should_pass("-75742", $type, 0);
	should_pass("-455976320", $type, 0);
	should_pass("-4445354332577", $type, 0);
	should_pass("-912762633976188962", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-7", $type, 0);
	should_pass("-8", $type, 0);
	should_pass("-8", $type, 0);
	should_pass("-3", $type, 0);
	should_pass("-2", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_pass("-76576", $type, 0);
	should_pass("-92592", $type, 0);
	should_pass("-28664", $type, 0);
	should_pass("-73317", $type, 0);
	should_pass("-47257", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_pass("-165429727", $type, 0);
	should_pass("-583133911", $type, 0);
	should_pass("-887829423", $type, 0);
	should_pass("-774282848", $type, 0);
	should_pass("-718524348", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{13}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{13}$)/});
	should_pass("-6652874376778", $type, 0);
	should_pass("-5362777997727", $type, 0);
	should_pass("-2844768288884", $type, 0);
	should_pass("-5742996298233", $type, 0);
	should_pass("-5897261686643", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_pass("-914387262474557335", $type, 0);
	should_pass("-923276382451256268", $type, 0);
	should_pass("-917314136385244564", $type, 0);
	should_pass("-931566117363638157", $type, 0);
	should_pass("-964253325762237153", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-799584049274','-43086541125','-437','-141901608775','-4108769','-965719538530','-9896','-12671901386817929']});
	should_pass("-9896", $type, 0);
	should_pass("-141901608775", $type, 0);
	should_pass("-437", $type, 0);
	should_pass("-141901608775", $type, 0);
	should_pass("-437", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-51678619095983','-2567','-58812994566','-7328890','-759','-567986','-462214','-997161630']});
	should_pass("-759", $type, 0);
	should_pass("-51678619095983", $type, 0);
	should_pass("-462214", $type, 0);
	should_pass("-567986", $type, 0);
	should_pass("-58812994566", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-29566','-51381660407640261','-6839697930198','-627946996321885664','-78815123','-923074469','-74','-13149','-99']});
	should_pass("-923074469", $type, 0);
	should_pass("-51381660407640261", $type, 0);
	should_pass("-99", $type, 0);
	should_pass("-13149", $type, 0);
	should_pass("-74", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-87037330956252501','-36619944811','-57023','-918536646','-399072682','-39747055905837447','-941633341616753']});
	should_pass("-36619944811", $type, 0);
	should_pass("-918536646", $type, 0);
	should_pass("-57023", $type, 0);
	should_pass("-87037330956252501", $type, 0);
	should_pass("-918536646", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-4336721877308','-852169232158110','-6208','-972552137318','-632','-8638729626','-1243882220834','-312437399392143']});
	should_pass("-632", $type, 0);
	should_pass("-6208", $type, 0);
	should_pass("-972552137318", $type, 0);
	should_pass("-6208", $type, 0);
	should_pass("-632", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('NegativeInteger', {'whiteSpace' => 'collapse'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-165356406576173898", $type, 0);
	should_pass("-547179558838093771", $type, 0);
	should_pass("-758569088580481442", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -383278836725871707." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-383278836725871707'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-702169798022027542", $type, 0);
	should_fail("-666529727638624998", $type, 0);
	should_fail("-985972121431104560", $type, 0);
	should_fail("-383278836725871708", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -349070581849158068." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-349070581849158068'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-865540392815267322", $type, 0);
	should_fail("-409845412626426777", $type, 0);
	should_fail("-402775332169313208", $type, 0);
	should_fail("-349070581849158069", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -13084299575343628." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-13084299575343628'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-462923617980921371", $type, 0);
	should_fail("-318397992456832307", $type, 0);
	should_fail("-137137183091879389", $type, 0);
	should_fail("-13084299575343629", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -176155984517072817." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-176155984517072817'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-987458292566733449", $type, 0);
	should_fail("-811020132063424031", $type, 0);
	should_fail("-829439578944992037", $type, 0);
	should_fail("-176155984517072818", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minInclusive with value -1." => sub {
	my $type = mk_type('NegativeInteger', {'minInclusive' => '-1'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-518586297113227457", $type, 0);
	should_fail("-690472356337122672", $type, 0);
	should_fail("-195234996010505647", $type, 0);
	should_fail("-2", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-999999999999999999'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-283623569470353054", $type, 0);
	should_fail("-513743212038921703", $type, 0);
	should_fail("-738432751342086522", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -369278887790841392." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-369278887790841392'});
	should_fail("-369278887790841391", $type, 0);
	should_fail("-78342130091136135", $type, 0);
	should_fail("-254223661061725469", $type, 0);
	should_fail("-97858745140121915", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -177604717942529411." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-177604717942529411'});
	should_fail("-177604717942529410", $type, 0);
	should_fail("-131211550622692333", $type, 0);
	should_fail("-160312980577746200", $type, 0);
	should_fail("-111775195041801727", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -411412970005971434." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-411412970005971434'});
	should_fail("-411412970005971433", $type, 0);
	should_fail("-234044042183509633", $type, 0);
	should_fail("-300625725959076879", $type, 0);
	should_fail("-352625591500965827", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxInclusive with value -135951110411760890." => sub {
	my $type = mk_type('NegativeInteger', {'maxInclusive' => '-135951110411760890'});
	should_fail("-135951110411760889", $type, 0);
	should_fail("-85974327696241055", $type, 0);
	should_fail("-112021063643733463", $type, 0);
	should_fail("-132991626123000178", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '1'});
	should_fail("-58", $type, 0);
	should_fail("-818952", $type, 0);
	should_fail("-2832450785", $type, 0);
	should_fail("-77188754766704", $type, 0);
	should_fail("-355233502652433737", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '4'});
	should_fail("-18086", $type, 0);
	should_fail("-30236688", $type, 0);
	should_fail("-81144291194", $type, 0);
	should_fail("-56839769692583", $type, 0);
	should_fail("-478688135624794333", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '7'});
	should_fail("-27860248", $type, 0);
	should_fail("-6605411553", $type, 0);
	should_fail("-573349747565", $type, 0);
	should_fail("-55823956446873", $type, 0);
	should_fail("-395582881715216836", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '10'});
	should_fail("-80764013622", $type, 0);
	should_fail("-244686357565", $type, 0);
	should_fail("-6867961201779", $type, 0);
	should_fail("-76114111985696", $type, 0);
	should_fail("-408181343177446654", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('NegativeInteger', {'totalDigits' => '13'});
	should_fail("-91158467351677", $type, 0);
	should_fail("-122763668788141", $type, 0);
	should_fail("-1320423848331330", $type, 0);
	should_fail("-48844377017825023", $type, 0);
	should_fail("-788271878309517085", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -921633907817531072." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-921633907817531072'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-951595666509219807", $type, 0);
	should_fail("-949054733442859939", $type, 0);
	should_fail("-985381760840341098", $type, 0);
	should_fail("-921633907817531072", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -976782140546110121." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-976782140546110121'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-988149319138515245", $type, 0);
	should_fail("-983263510399785395", $type, 0);
	should_fail("-995748341020440494", $type, 0);
	should_fail("-976782140546110121", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -788555704125782685." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-788555704125782685'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-854450049048861665", $type, 0);
	should_fail("-901885140223494858", $type, 0);
	should_fail("-816608602126030677", $type, 0);
	should_fail("-788555704125782685", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet minExclusive with value -2." => sub {
	my $type = mk_type('NegativeInteger', {'minExclusive' => '-2'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-996734916696543681", $type, 0);
	should_fail("-532288887764013729", $type, 0);
	should_fail("-542195774224826232", $type, 0);
	should_fail("-2", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-999999999999999998'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-145345601162744975", $type, 0);
	should_fail("-359114579536026434", $type, 0);
	should_fail("-997175199307837376", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -466339041882621318." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-466339041882621318'});
	should_fail("-466339041882621318", $type, 0);
	should_fail("-465181401943681643", $type, 0);
	should_fail("-455208473908838232", $type, 0);
	should_fail("-63145281984264547", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -954414372192710523." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-954414372192710523'});
	should_fail("-954414372192710523", $type, 0);
	should_fail("-880236823638807375", $type, 0);
	should_fail("-41556158763589335", $type, 0);
	should_fail("-619003189153397151", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -367996043905826186." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-367996043905826186'});
	should_fail("-367996043905826186", $type, 0);
	should_fail("-367572248213243802", $type, 0);
	should_fail("-222998764331746192", $type, 0);
	should_fail("-104807281411357482", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet maxExclusive with value -1." => sub {
	my $type = mk_type('NegativeInteger', {'maxExclusive' => '-1'});
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("-6224178888684242", $type, 0);
	should_fail("-27738747", $type, 0);
	should_fail("-917486331664737187", $type, 0);
	should_fail("-862629", $type, 0);
	should_fail("-335183", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_fail("-3232", $type, 0);
	should_fail("-17351737336733", $type, 0);
	should_fail("-7417355772454323", $type, 0);
	should_fail("-7918676", $type, 0);
	should_fail("-893465834", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_fail("-765838262428", $type, 0);
	should_fail("-58", $type, 0);
	should_fail("-524428766258666", $type, 0);
	should_fail("-6843577645466", $type, 0);
	should_fail("-27787", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{13}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{13}$)/});
	should_fail("-64876363769717", $type, 0);
	should_fail("-8", $type, 0);
	should_fail("-948175624636772733", $type, 0);
	should_fail("-35573145", $type, 0);
	should_fail("-8986529274638524", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('NegativeInteger', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_fail("-282", $type, 0);
	should_fail("-678426537437946", $type, 0);
	should_fail("-25276325622825", $type, 0);
	should_fail("-3197335867", $type, 0);
	should_fail("-7695854688243555", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-56','-78162','-66','-64290','-53033235677117','-850050','-21344','-1941630','-6523','-650383']});
	should_fail("-405001977958150183", $type, 0);
	should_fail("-926265724849529958", $type, 0);
	should_fail("-947215466890104384", $type, 0);
	should_fail("-926265724849529958", $type, 0);
	should_fail("-320673971316476791", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-607079475462230','-59','-45532879838235473','-75385789227','-1834362131','-85662787813','-10964645614']});
	should_fail("-301611282400402802", $type, 0);
	should_fail("-320264127677682420", $type, 0);
	should_fail("-909215274749755496", $type, 0);
	should_fail("-32439581066225576", $type, 0);
	should_fail("-820566993291908852", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-94847585603997','-20278','-37','-9500135912','-8765337594408015','-52188','-38']});
	should_fail("-596049869114037344", $type, 0);
	should_fail("-681650746687945341", $type, 0);
	should_fail("-363186156759663370", $type, 0);
	should_fail("-667584630727504734", $type, 0);
	should_fail("-414737603349142558", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-7891','-210468','-954966599','-88','-81722239388','-1369568','-203452','-945450049185','-469413']});
	should_fail("-870664238957266189", $type, 0);
	should_fail("-719813955911788760", $type, 0);
	should_fail("-924064477915192638", $type, 0);
	should_fail("-870664238957266189", $type, 0);
	should_fail("-924064477915192638", $type, 0);
	done_testing;
};

subtest "Type atomic/negativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NegativeInteger', {'enumeration' => ['-38626','-758','-14631310','-6832806488697145','-28493065','-913277']});
	should_fail("-528129194915475608", $type, 0);
	should_fail("-986692020455715134", $type, 0);
	should_fail("-452559197884029096", $type, 0);
	should_fail("-514570933867417701", $type, 0);
	should_fail("-479202583663554504", $type, 0);
	done_testing;
};

done_testing;

