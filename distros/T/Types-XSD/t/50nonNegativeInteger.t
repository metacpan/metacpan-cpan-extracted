use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '0'});
	should_pass("1", $type, 0);
	should_pass("420622914392487334", $type, 0);
	should_pass("711166205738569922", $type, 0);
	should_pass("601854033523182785", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 279497457259986536." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '279497457259986536'});
	should_pass("279497457259986537", $type, 0);
	should_pass("565148117926952049", $type, 0);
	should_pass("849859674658384755", $type, 0);
	should_pass("512953235511037469", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 12032691129748584." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '12032691129748584'});
	should_pass("12032691129748585", $type, 0);
	should_pass("645354870800451493", $type, 0);
	should_pass("629087069541260967", $type, 0);
	should_pass("243398316233110706", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 656186311861347125." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '656186311861347125'});
	should_pass("656186311861347126", $type, 0);
	should_pass("660176223359068458", $type, 0);
	should_pass("992779479398573116", $type, 0);
	should_pass("956143781468634329", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '999999999999999998'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '0'});
	should_pass("0", $type, 0);
	should_pass("20650283505041944", $type, 0);
	should_pass("933739927874715712", $type, 0);
	should_pass("871902332295281689", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 414410475494371377." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '414410475494371377'});
	should_pass("414410475494371377", $type, 0);
	should_pass("619241322601469913", $type, 0);
	should_pass("527980315601927548", $type, 0);
	should_pass("910571910425706802", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 543609894158592842." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '543609894158592842'});
	should_pass("543609894158592842", $type, 0);
	should_pass("949012401326380590", $type, 0);
	should_pass("979129731672420390", $type, 0);
	should_pass("604337704629058328", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 430399820504899332." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '430399820504899332'});
	should_pass("430399820504899332", $type, 0);
	should_pass("727896179801196930", $type, 0);
	should_pass("801292633795849003", $type, 0);
	should_pass("627092159362274280", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '999999999999999999'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '1'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 671945496538646879." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '671945496538646879'});
	should_pass("0", $type, 0);
	should_pass("261183403354472441", $type, 0);
	should_pass("194959179560998769", $type, 0);
	should_pass("361886253563862450", $type, 0);
	should_pass("671945496538646878", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 278524439385076983." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '278524439385076983'});
	should_pass("0", $type, 0);
	should_pass("253165356347898417", $type, 0);
	should_pass("62948318663286785", $type, 0);
	should_pass("197034238665818822", $type, 0);
	should_pass("278524439385076982", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 486042717509224675." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '486042717509224675'});
	should_pass("0", $type, 0);
	should_pass("198433291959685677", $type, 0);
	should_pass("10407362817208197", $type, 0);
	should_pass("102821201977141980", $type, 0);
	should_pass("486042717509224674", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '999999999999999999'});
	should_pass("0", $type, 0);
	should_pass("140855137347027592", $type, 0);
	should_pass("706366201258347702", $type, 0);
	should_pass("882995200557444069", $type, 0);
	should_pass("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '0'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 495229311196364818." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '495229311196364818'});
	should_pass("0", $type, 0);
	should_pass("187865784376034884", $type, 0);
	should_pass("151083687173417018", $type, 0);
	should_pass("492801888814156427", $type, 0);
	should_pass("495229311196364818", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 154173639038036491." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '154173639038036491'});
	should_pass("0", $type, 0);
	should_pass("131171777416741679", $type, 0);
	should_pass("42088439900719018", $type, 0);
	should_pass("34265300879566862", $type, 0);
	should_pass("154173639038036491", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 467117575036009479." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '467117575036009479'});
	should_pass("0", $type, 0);
	should_pass("438321703526830219", $type, 0);
	should_pass("100248434061178699", $type, 0);
	should_pass("209819376569373583", $type, 0);
	should_pass("467117575036009479", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 999999999999999999." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '999999999999999999'});
	should_pass("0", $type, 0);
	should_pass("386929430516098515", $type, 0);
	should_pass("430423238640956439", $type, 0);
	should_pass("819734920144501665", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('NonNegativeInteger', {'fractionDigits' => '0'});
	should_pass("0", $type, 0);
	should_pass("850684867747796501", $type, 0);
	should_pass("625236343753581613", $type, 0);
	should_pass("766660829133858467", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '1'});
	should_pass("3", $type, 0);
	should_pass("2", $type, 0);
	should_pass("9", $type, 0);
	should_pass("6", $type, 0);
	should_pass("4", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '5'});
	should_pass("6", $type, 0);
	should_pass("60", $type, 0);
	should_pass("461", $type, 0);
	should_pass("1480", $type, 0);
	should_pass("18618", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '9'});
	should_pass("7", $type, 0);
	should_pass("488", $type, 0);
	should_pass("88235", $type, 0);
	should_pass("1425777", $type, 0);
	should_pass("814118403", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '13'});
	should_pass("1", $type, 0);
	should_pass("2734", $type, 0);
	should_pass("3973573", $type, 0);
	should_pass("7346856784", $type, 0);
	should_pass("8564591727456", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '18'});
	should_pass("6", $type, 0);
	should_pass("44930", $type, 0);
	should_pass("699879955", $type, 0);
	should_pass("8521474425424", $type, 0);
	should_pass("573041487868816274", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("5", $type, 0);
	should_pass("7", $type, 0);
	should_pass("8", $type, 0);
	should_pass("7", $type, 0);
	should_pass("8", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("61563", $type, 0);
	should_pass("71174", $type, 0);
	should_pass("88533", $type, 0);
	should_pass("84894", $type, 0);
	should_pass("33775", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{9}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{9}$)/});
	should_pass("744672379", $type, 0);
	should_pass("352843363", $type, 0);
	should_pass("546285228", $type, 0);
	should_pass("165766975", $type, 0);
	should_pass("492246237", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{13}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{13}$)/});
	should_pass("3515776629323", $type, 0);
	should_pass("7439739327795", $type, 0);
	should_pass("5383645611171", $type, 0);
	should_pass("7245857231884", $type, 0);
	should_pass("8362248584526", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_pass("915476347284546727", $type, 0);
	should_pass("981361845647637366", $type, 0);
	should_pass("921446647764661256", $type, 0);
	should_pass("946444323178626635", $type, 0);
	should_pass("936153437421347234", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['95273492','65117369587117','63','566057831','75769970879','61084065764','49778069509229']});
	should_pass("95273492", $type, 0);
	should_pass("95273492", $type, 0);
	should_pass("61084065764", $type, 0);
	should_pass("75769970879", $type, 0);
	should_pass("75769970879", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['58297003663756774','55','87918438408','92809813592','12914741768813','50094']});
	should_pass("87918438408", $type, 0);
	should_pass("87918438408", $type, 0);
	should_pass("92809813592", $type, 0);
	should_pass("87918438408", $type, 0);
	should_pass("50094", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['23892815','90576835920','424484','79896','9556157928','9176','802100066184431','668936','849475711356152407','71162303480519']});
	should_pass("849475711356152407", $type, 0);
	should_pass("9176", $type, 0);
	should_pass("802100066184431", $type, 0);
	should_pass("668936", $type, 0);
	should_pass("849475711356152407", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['165524680951923075','25316000768963','641253638624229571','90692','6809792634202668','5435077718428','75086583090071','17593746']});
	should_pass("641253638624229571", $type, 0);
	should_pass("75086583090071", $type, 0);
	should_pass("75086583090071", $type, 0);
	should_pass("6809792634202668", $type, 0);
	should_pass("25316000768963", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['153','30','1530','125','68919387654218','261','8001281','29523017399162965','873']});
	should_pass("30", $type, 0);
	should_pass("261", $type, 0);
	should_pass("30", $type, 0);
	should_pass("8001281", $type, 0);
	should_pass("1530", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('NonNegativeInteger', {'whiteSpace' => 'collapse'});
	should_pass("0", $type, 0);
	should_pass("663569508556448694", $type, 0);
	should_pass("749876594474212065", $type, 0);
	should_pass("163817072726506918", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 68621188090916995." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '68621188090916995'});
	should_fail("0", $type, 0);
	should_fail("49164518756074332", $type, 0);
	should_fail("47784213665996517", $type, 0);
	should_fail("46938487223960270", $type, 0);
	should_fail("68621188090916994", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 414683870939169918." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '414683870939169918'});
	should_fail("0", $type, 0);
	should_fail("299190482066150346", $type, 0);
	should_fail("7672435498459624", $type, 0);
	should_fail("40802468802545157", $type, 0);
	should_fail("414683870939169917", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 705386240938976837." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '705386240938976837'});
	should_fail("0", $type, 0);
	should_fail("511692812622593162", $type, 0);
	should_fail("229783343553290588", $type, 0);
	should_fail("508118155474036901", $type, 0);
	should_fail("705386240938976836", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 586989978554113389." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '586989978554113389'});
	should_fail("0", $type, 0);
	should_fail("434690454850062370", $type, 0);
	should_fail("208777471342449354", $type, 0);
	should_fail("72011835839441353", $type, 0);
	should_fail("586989978554113388", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('NonNegativeInteger', {'minInclusive' => '999999999999999999'});
	should_fail("0", $type, 0);
	should_fail("70983889130972976", $type, 0);
	should_fail("266303028029555188", $type, 0);
	should_fail("886245613321752110", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '0'});
	should_fail("1", $type, 0);
	should_fail("140801489300441785", $type, 0);
	should_fail("169221912742806402", $type, 0);
	should_fail("198618706990894567", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 297689380360350197." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '297689380360350197'});
	should_fail("297689380360350198", $type, 0);
	should_fail("896414932894558138", $type, 0);
	should_fail("965591322660256205", $type, 0);
	should_fail("682141799706741747", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 303742718992286664." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '303742718992286664'});
	should_fail("303742718992286665", $type, 0);
	should_fail("595140762320601980", $type, 0);
	should_fail("903052347790957108", $type, 0);
	should_fail("705072694493848030", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 378879032113847990." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '378879032113847990'});
	should_fail("378879032113847991", $type, 0);
	should_fail("606255497292639091", $type, 0);
	should_fail("847671278101021575", $type, 0);
	should_fail("895766837444982417", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxInclusive with value 5840324392176410." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxInclusive' => '5840324392176410'});
	should_fail("5840324392176411", $type, 0);
	should_fail("564773605595527686", $type, 0);
	should_fail("412546318997669526", $type, 0);
	should_fail("121085269362897124", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '1'});
	should_fail("43", $type, 0);
	should_fail("122613", $type, 0);
	should_fail("8413456671", $type, 0);
	should_fail("88317353381013", $type, 0);
	should_fail("115913271327648484", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '4'});
	should_fail("11545", $type, 0);
	should_fail("16373457", $type, 0);
	should_fail("16639132605", $type, 0);
	should_fail("56611153511628", $type, 0);
	should_fail("633268051751428648", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '7'});
	should_fail("60326505", $type, 0);
	should_fail("1984865648", $type, 0);
	should_fail("274752962975", $type, 0);
	should_fail("18663945150129", $type, 0);
	should_fail("289379373673313139", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '10'});
	should_fail("81692927074", $type, 0);
	should_fail("923207941036", $type, 0);
	should_fail("6377142241925", $type, 0);
	should_fail("36365253771732", $type, 0);
	should_fail("936784857313111338", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('NonNegativeInteger', {'totalDigits' => '13'});
	should_fail("10432728981242", $type, 0);
	should_fail("170800797529838", $type, 0);
	should_fail("4475447211351286", $type, 0);
	should_fail("73361303663331944", $type, 0);
	should_fail("954488713077402163", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '0'});
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 832032588787707803." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '832032588787707803'});
	should_fail("0", $type, 0);
	should_fail("488893885808247156", $type, 0);
	should_fail("463796524911268092", $type, 0);
	should_fail("726909715477858746", $type, 0);
	should_fail("832032588787707803", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 105669227618697569." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '105669227618697569'});
	should_fail("0", $type, 0);
	should_fail("13443293542706066", $type, 0);
	should_fail("4590498223110692", $type, 0);
	should_fail("86624382942676538", $type, 0);
	should_fail("105669227618697569", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 679939135819036087." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '679939135819036087'});
	should_fail("0", $type, 0);
	should_fail("646114791168737948", $type, 0);
	should_fail("416670691466157256", $type, 0);
	should_fail("619405580197060783", $type, 0);
	should_fail("679939135819036087", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('NonNegativeInteger', {'minExclusive' => '999999999999999998'});
	should_fail("0", $type, 0);
	should_fail("44510725441964549", $type, 0);
	should_fail("632224246631051588", $type, 0);
	should_fail("479572940356873255", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '1'});
	should_fail("1", $type, 0);
	should_fail("813414117892087839", $type, 0);
	should_fail("386816443373796947", $type, 0);
	should_fail("525521044684190807", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 342271279747271451." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '342271279747271451'});
	should_fail("342271279747271451", $type, 0);
	should_fail("362882772320813288", $type, 0);
	should_fail("723962147859572241", $type, 0);
	should_fail("505440518618352839", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 588497386592158222." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '588497386592158222'});
	should_fail("588497386592158222", $type, 0);
	should_fail("979539619900485450", $type, 0);
	should_fail("671301357771440926", $type, 0);
	should_fail("657245208214284995", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 939225066502577531." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '939225066502577531'});
	should_fail("939225066502577531", $type, 0);
	should_fail("951042209140048583", $type, 0);
	should_fail("999769866304810403", $type, 0);
	should_fail("960823280578121666", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('NonNegativeInteger', {'maxExclusive' => '999999999999999999'});
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("4335235", $type, 0);
	should_fail("77", $type, 0);
	should_fail("227847", $type, 0);
	should_fail("6685661154", $type, 0);
	should_fail("668578721731", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("39855645", $type, 0);
	should_fail("73", $type, 0);
	should_fail("34889484", $type, 0);
	should_fail("6617681", $type, 0);
	should_fail("8485562656353", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{9}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{9}$)/});
	should_fail("35184452224", $type, 0);
	should_fail("17", $type, 0);
	should_fail("85977", $type, 0);
	should_fail("74285", $type, 0);
	should_fail("923854877522245335", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{13}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{13}$)/});
	should_fail("3365452747", $type, 0);
	should_fail("7", $type, 0);
	should_fail("845326", $type, 0);
	should_fail("72383255", $type, 0);
	should_fail("625872", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet pattern with value \\d{18}." => sub {
	my $type = mk_type('NonNegativeInteger', {'pattern' => qr/(?ms:^\d{18}$)/});
	should_fail("6462125255", $type, 0);
	should_fail("364364648671", $type, 0);
	should_fail("5268764", $type, 0);
	should_fail("53", $type, 0);
	should_fail("8175", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['776323406067','206297852961434','95331661707','109','48643141634619724','18422725621481','624114','6673263269','45652654523739','96580177']});
	should_fail("415649926964222648", $type, 0);
	should_fail("363425438012047629", $type, 0);
	should_fail("662399176410003897", $type, 0);
	should_fail("569046552683175054", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['4666174071','39397','8953001','3442650103366697','9520089393']});
	should_fail("244875952415783193", $type, 0);
	should_fail("367027716907425860", $type, 0);
	should_fail("367027716907425860", $type, 0);
	should_fail("294856988641413297", $type, 0);
	should_fail("327115986022324056", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['8994372964782390','2809248792','522963765406','31','89802913','21477296244931554','79197097026683','484172467095720','35798849826','153430671']});
	should_fail("686625997375219120", $type, 0);
	should_fail("827409826444820971", $type, 0);
	should_fail("686625997375219120", $type, 0);
	should_fail("765625700375572869", $type, 0);
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['5098','8617','1695','858844803','85079597812283','653962539349469','11533256458']});
	should_fail("999707256508818308", $type, 0);
	should_fail("74639484924701293", $type, 0);
	should_fail("526433650826933718", $type, 0);
	should_fail("348804558062742797", $type, 0);
	should_fail("585614304285726471", $type, 0);
	done_testing;
};

subtest "Type atomic/nonNegativeInteger is restricted by facet enumeration." => sub {
	my $type = mk_type('NonNegativeInteger', {'enumeration' => ['792019','1391782096775','59258070060798884','128','90280268073','43172','41030']});
	should_fail("219550401864674893", $type, 0);
	should_fail("610262149218043114", $type, 0);
	should_fail("101141510136071199", $type, 0);
	should_fail("425078491289867077", $type, 0);
	should_fail("610262149218043114", $type, 0);
	done_testing;
};

done_testing;

