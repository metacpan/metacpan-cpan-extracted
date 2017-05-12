use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-999999999999999999'});
	should_pass("-999999999999999998", $type, 0);
	should_pass("-905988655891905690", $type, 0);
	should_pass("-290106735591304731", $type, 0);
	should_pass("-810915085663024613", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -482054947069493477." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-482054947069493477'});
	should_pass("-482054947069493476", $type, 0);
	should_pass("-201826549746962768", $type, 0);
	should_pass("-112150045490162742", $type, 0);
	should_pass("-408029346335664256", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -406392790344449528." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-406392790344449528'});
	should_pass("-406392790344449527", $type, 0);
	should_pass("-281004217978489778", $type, 0);
	should_pass("-208581781143212700", $type, 0);
	should_pass("-33364160796484990", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -594976296252018754." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-594976296252018754'});
	should_pass("-594976296252018753", $type, 0);
	should_pass("-255265502493433159", $type, 0);
	should_pass("-381628976206782991", $type, 0);
	should_pass("-474274082065671734", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -1." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-1'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -999999999999999999." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-514604280507368505", $type, 0);
	should_pass("-83583574885654487", $type, 0);
	should_pass("-505473555297749954", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -927820889571802863." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-927820889571802863'});
	should_pass("-927820889571802863", $type, 0);
	should_pass("-156360166869488276", $type, 0);
	should_pass("-325086174575775878", $type, 0);
	should_pass("-88105372236679898", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -214379312213180406." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-214379312213180406'});
	should_pass("-214379312213180406", $type, 0);
	should_pass("-153719698257793504", $type, 0);
	should_pass("-27445027048368935", $type, 0);
	should_pass("-32102847658518338", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -911248228325171715." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-911248228325171715'});
	should_pass("-911248228325171715", $type, 0);
	should_pass("-71699205998103321", $type, 0);
	should_pass("-287523941873722043", $type, 0);
	should_pass("-600807522347121358", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '0'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-999999999999999998'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -267691436022826633." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-267691436022826633'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-741114493510696257", $type, 0);
	should_pass("-344055993533620673", $type, 0);
	should_pass("-985355471466500825", $type, 0);
	should_pass("-267691436022826634", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -64116953963150757." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-64116953963150757'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-935506704938491307", $type, 0);
	should_pass("-190406070523111214", $type, 0);
	should_pass("-309195465747117080", $type, 0);
	should_pass("-64116953963150758", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -398718969796236887." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-398718969796236887'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-766850543644733626", $type, 0);
	should_pass("-895067844361676168", $type, 0);
	should_pass("-492234184111664960", $type, 0);
	should_pass("-398718969796236888", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value 0." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-981113330609807431", $type, 0);
	should_pass("-634906667179249039", $type, 0);
	should_pass("-80582241587873749", $type, 0);
	should_pass("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -63404852978511949." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-63404852978511949'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-106172108207356609", $type, 0);
	should_pass("-318208363019321686", $type, 0);
	should_pass("-546425195624242438", $type, 0);
	should_pass("-63404852978511949", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -78303033269241706." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-78303033269241706'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-473418910026643198", $type, 0);
	should_pass("-622517735700789671", $type, 0);
	should_pass("-905913138266054961", $type, 0);
	should_pass("-78303033269241706", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -686635117591375964." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-686635117591375964'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-996746452401836103", $type, 0);
	should_pass("-867835744993880221", $type, 0);
	should_pass("-845649434684695218", $type, 0);
	should_pass("-686635117591375964", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-60998369586791056", $type, 0);
	should_pass("-517125678919806097", $type, 0);
	should_pass("-62209535110962277", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('NonPositiveInteger', {'fractionDigits' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-867815918966345355", $type, 0);
	should_pass("-409756946594936443", $type, 0);
	should_pass("-943790338064085076", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '1'});
	should_pass("-3", $type, 0);
	should_pass("-6", $type, 0);
	should_pass("-1", $type, 0);
	should_pass("-4", $type, 0);
	should_pass("-9", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '5'});
	should_pass("-8", $type, 0);
	should_pass("-42", $type, 0);
	should_pass("-225", $type, 0);
	should_pass("-6099", $type, 0);
	should_pass("-38541", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '9'});
	should_pass("-8", $type, 0);
	should_pass("-531", $type, 0);
	should_pass("-21345", $type, 0);
	should_pass("-9113291", $type, 0);
	should_pass("-313528833", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '13'});
	should_pass("-8", $type, 0);
	should_pass("-9602", $type, 0);
	should_pass("-1697397", $type, 0);
	should_pass("-7685547334", $type, 0);
	should_pass("-2574750577713", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '18'});
	should_pass("-7", $type, 0);
	should_pass("-33606", $type, 0);
	should_pass("-435467090", $type, 0);
	should_pass("-6788246588007", $type, 0);
	should_pass("-777517648312366647", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-8", $type, 0);
	should_pass("-8", $type, 0);
	should_pass("-5", $type, 0);
	should_pass("-2", $type, 0);
	should_pass("-8", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_pass("-78241", $type, 0);
	should_pass("-52356", $type, 0);
	should_pass("-36965", $type, 0);
	should_pass("-68554", $type, 0);
	should_pass("-63668", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_pass("-488322716", $type, 0);
	should_pass("-437225795", $type, 0);
	should_pass("-744662475", $type, 0);
	should_pass("-288473844", $type, 0);
	should_pass("-986452775", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{13}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{13}$)/});
	should_pass("-8275124922345", $type, 0);
	should_pass("-2469517378287", $type, 0);
	should_pass("-4715332476686", $type, 0);
	should_pass("-1895527583514", $type, 0);
	should_pass("-8372678763482", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_pass("-936563332352235635", $type, 0);
	should_pass("-942544636732766563", $type, 0);
	should_pass("-913235447674617174", $type, 0);
	should_pass("-914656717751452542", $type, 0);
	should_pass("-962563545524633342", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-2','-9433249751626','-490343697','-34057323631','-4061916853','-761218']});
	should_pass("-4061916853", $type, 0);
	should_pass("-761218", $type, 0);
	should_pass("-761218", $type, 0);
	should_pass("-490343697", $type, 0);
	should_pass("-490343697", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-559044','-69','-40316819','-351','-712506','-118','-748','-23407037','-19','-677813318583757']});
	should_pass("-748", $type, 0);
	should_pass("-40316819", $type, 0);
	should_pass("-748", $type, 0);
	should_pass("-69", $type, 0);
	should_pass("-712506", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-10458828265','-39825826839070','-8989002307','-50729019','-805328452431','-9862058680016422','-92','-29118543','-71959641']});
	should_pass("-8989002307", $type, 0);
	should_pass("-29118543", $type, 0);
	should_pass("-29118543", $type, 0);
	should_pass("-8989002307", $type, 0);
	should_pass("-9862058680016422", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-4710744954','-1090','-9949071662356567','-9764893','-774596823389670285','-216459046','-209931154']});
	should_pass("-1090", $type, 0);
	should_pass("-9764893", $type, 0);
	should_pass("-774596823389670285", $type, 0);
	should_pass("-216459046", $type, 0);
	should_pass("-774596823389670285", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-71','-611','-27','-241238476','-8591039','-934828787','-342967456457','-841018047002872','-8884375099']});
	should_pass("-611", $type, 0);
	should_pass("-241238476", $type, 0);
	should_pass("-841018047002872", $type, 0);
	should_pass("-342967456457", $type, 0);
	should_pass("-27", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('NonPositiveInteger', {'whiteSpace' => 'collapse'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-336938973883109115", $type, 0);
	should_pass("-164737809714792127", $type, 0);
	should_pass("-409009825015166805", $type, 0);
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -269608150885451202." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-269608150885451202'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-389294831499795693", $type, 0);
	should_fail("-293692742896350827", $type, 0);
	should_fail("-983208627966342561", $type, 0);
	should_fail("-269608150885451203", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -890254333493681659." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-890254333493681659'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-926580995300126740", $type, 0);
	should_fail("-946004331892225444", $type, 0);
	should_fail("-997058928016916483", $type, 0);
	should_fail("-890254333493681660", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -203590473966627882." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-203590473966627882'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-389158202230241307", $type, 0);
	should_fail("-725110076828486213", $type, 0);
	should_fail("-382574530274989215", $type, 0);
	should_fail("-203590473966627883", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value -228784597763440178." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '-228784597763440178'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-727240079311177310", $type, 0);
	should_fail("-953315392318688509", $type, 0);
	should_fail("-520389547660290105", $type, 0);
	should_fail("-228784597763440179", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('NonPositiveInteger', {'minInclusive' => '0'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-250580201345327214", $type, 0);
	should_fail("-345783375965520223", $type, 0);
	should_fail("-492839161375730694", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-999999999999999999'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-838154723768013252", $type, 0);
	should_fail("-354221138603540430", $type, 0);
	should_fail("-706632266417767772", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -593437050761786099." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-593437050761786099'});
	should_fail("-593437050761786098", $type, 0);
	should_fail("-138449568698411934", $type, 0);
	should_fail("-587493942186698299", $type, 0);
	should_fail("-249368885741101753", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -923171155172606060." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-923171155172606060'});
	should_fail("-923171155172606059", $type, 0);
	should_fail("-41939930644503284", $type, 0);
	should_fail("-208864230497451625", $type, 0);
	should_fail("-35995692169824455", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -850796917225226100." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-850796917225226100'});
	should_fail("-850796917225226099", $type, 0);
	should_fail("-78470538010152981", $type, 0);
	should_fail("-141809537111496421", $type, 0);
	should_fail("-225569617986930453", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxInclusive with value -196913225599862462." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxInclusive' => '-196913225599862462'});
	should_fail("-196913225599862461", $type, 0);
	should_fail("-122943505382308148", $type, 0);
	should_fail("-1741256791526694", $type, 0);
	should_fail("-151863541637642114", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '1'});
	should_fail("-40", $type, 0);
	should_fail("-577251", $type, 0);
	should_fail("-2663520623", $type, 0);
	should_fail("-73212184903048", $type, 0);
	should_fail("-349504324017759461", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '4'});
	should_fail("-27071", $type, 0);
	should_fail("-14583578", $type, 0);
	should_fail("-35952536628", $type, 0);
	should_fail("-40802634248261", $type, 0);
	should_fail("-449887659171104609", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '7'});
	should_fail("-69435458", $type, 0);
	should_fail("-8891934243", $type, 0);
	should_fail("-714271107488", $type, 0);
	should_fail("-43844327248488", $type, 0);
	should_fail("-302778408231437852", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '10'});
	should_fail("-57691455131", $type, 0);
	should_fail("-245941620212", $type, 0);
	should_fail("-1428731864416", $type, 0);
	should_fail("-33312167919807", $type, 0);
	should_fail("-248648124166262261", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('NonPositiveInteger', {'totalDigits' => '13'});
	should_fail("-53297507933173", $type, 0);
	should_fail("-174713368831614", $type, 0);
	should_fail("-2787813748806156", $type, 0);
	should_fail("-16182259713041554", $type, 0);
	should_fail("-524968710237166743", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -572157627064420859." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-572157627064420859'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-928148707875611681", $type, 0);
	should_fail("-886568633074002832", $type, 0);
	should_fail("-665290110456655127", $type, 0);
	should_fail("-572157627064420859", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -717484827624413345." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-717484827624413345'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-728016069820303410", $type, 0);
	should_fail("-866446949329529514", $type, 0);
	should_fail("-821705741031630961", $type, 0);
	should_fail("-717484827624413345", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -791138773234574931." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-791138773234574931'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-928318088638857581", $type, 0);
	should_fail("-926771981913107160", $type, 0);
	should_fail("-899773724187238059", $type, 0);
	should_fail("-791138773234574931", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet minExclusive with value -1." => sub {
	my $type = mk_type('NonPositiveInteger', {'minExclusive' => '-1'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-873838499504295817", $type, 0);
	should_fail("-305614124670335330", $type, 0);
	should_fail("-110339095313123026", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-999999999999999998'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-718138374788761189", $type, 0);
	should_fail("-446535343371481484", $type, 0);
	should_fail("-702833914246292378", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -698542836566919399." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-698542836566919399'});
	should_fail("-698542836566919399", $type, 0);
	should_fail("-57880152026340493", $type, 0);
	should_fail("-458861167247245026", $type, 0);
	should_fail("-436071170160881216", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -730118541643560268." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-730118541643560268'});
	should_fail("-730118541643560268", $type, 0);
	should_fail("-89298064474577713", $type, 0);
	should_fail("-555479316813332199", $type, 0);
	should_fail("-485487302763131155", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value -145124311590065779." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '-145124311590065779'});
	should_fail("-145124311590065779", $type, 0);
	should_fail("-60212599132106189", $type, 0);
	should_fail("-68888204860155179", $type, 0);
	should_fail("-80561746828064702", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet maxExclusive with value 0." => sub {
	my $type = mk_type('NonPositiveInteger', {'maxExclusive' => '0'});
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("-2944", $type, 0);
	should_fail("-84382889683379", $type, 0);
	should_fail("-72847445", $type, 0);
	should_fail("-316573813744", $type, 0);
	should_fail("-43534164", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_fail("-922653546988", $type, 0);
	should_fail("-7967", $type, 0);
	should_fail("-7547535873", $type, 0);
	should_fail("-62748861729234844", $type, 0);
	should_fail("-577473345", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{9}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{9}$)/});
	should_fail("-87135695", $type, 0);
	should_fail("-287435868776", $type, 0);
	should_fail("-1533523342", $type, 0);
	should_fail("-25959", $type, 0);
	should_fail("-298362", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{13}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{13}$)/});
	should_fail("-83736172817", $type, 0);
	should_fail("-686465751752", $type, 0);
	should_fail("-4", $type, 0);
	should_fail("-4", $type, 0);
	should_fail("-947565246385256254", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet pattern with value \\-\\d{18}." => sub {
	my $type = mk_type('NonPositiveInteger', {'pattern' => qr/(?ms:^\-\d{18}$)/});
	should_fail("-64954588", $type, 0);
	should_fail("-44652546", $type, 0);
	should_fail("-78771773424874684", $type, 0);
	should_fail("-961813642", $type, 0);
	should_fail("-6335537862842", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-29490','-303','-73972936855','-19635989421241','-16838537','-40673062','-85295918','-387069093','-1203933612287135']});
	should_fail("-555070367802298014", $type, 0);
	should_fail("-335893637421509793", $type, 0);
	should_fail("-369608200113519802", $type, 0);
	should_fail("-112026868098659248", $type, 0);
	should_fail("-360925289666946813", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-2755','-211641047466678','-8075493294856522','-678561','-175870582528','-715614697774']});
	should_fail("-876186417532006877", $type, 0);
	should_fail("-660065142213748567", $type, 0);
	should_fail("-656032272225989365", $type, 0);
	should_fail("-356592693188201081", $type, 0);
	should_fail("-795920270681258367", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-92771046753','-563135454','-918435967979','-1','-10650441353166639']});
	should_fail("-511157760572277796", $type, 0);
	should_fail("-693810004742233420", $type, 0);
	should_fail("-433490516337204700", $type, 0);
	should_fail("-136027461971012342", $type, 0);
	should_fail("-503867689398694195", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-467623039','-6728877914982','-331486169353','-16','-88530367946759','-68666','-37798693952976']});
	should_fail("-139412945140734878", $type, 0);
	should_fail("-703463435374974576", $type, 0);
	should_fail("-216525328808880312", $type, 0);
	should_fail("-917371313089531902", $type, 0);
	should_fail("-157030679799715633", $type, 0);
	done_testing;
};

subtest "Type atomic/nonPositiveInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonPositiveInteger', {'enumeration' => ['-5225075','-36843','-230','-20382978','-7843737','-8212','-1033086645']});
	should_fail("-304729948399550032", $type, 0);
	should_fail("-104695326054680681", $type, 0);
	should_fail("-661256908744913273", $type, 0);
	should_fail("-933227475071535027", $type, 0);
	should_fail("-803859958473912560", $type, 0);
	done_testing;
};

done_testing;

