use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/int is restricted by facet minExclusive with value -2147483648." => sub {
	my $type = mk_type('Int', {'minExclusive' => '-2147483648'});
	should_pass("-2147483647", $type, 0);
	should_pass("-1529308213", $type, 0);
	should_pass("736511976", $type, 0);
	should_pass("2100599421", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value -1627498592." => sub {
	my $type = mk_type('Int', {'minExclusive' => '-1627498592'});
	should_pass("-1627498591", $type, 0);
	should_pass("2027187427", $type, 0);
	should_pass("-1502841975", $type, 0);
	should_pass("-1133731086", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value 410341384." => sub {
	my $type = mk_type('Int', {'minExclusive' => '410341384'});
	should_pass("410341385", $type, 0);
	should_pass("893609864", $type, 0);
	should_pass("499930050", $type, 0);
	should_pass("874321586", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value 272279129." => sub {
	my $type = mk_type('Int', {'minExclusive' => '272279129'});
	should_pass("272279130", $type, 0);
	should_pass("1884283998", $type, 0);
	should_pass("731235525", $type, 0);
	should_pass("309357714", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value 2147483646." => sub {
	my $type = mk_type('Int', {'minExclusive' => '2147483646'});
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value -2147483648." => sub {
	my $type = mk_type('Int', {'minInclusive' => '-2147483648'});
	should_pass("-2147483648", $type, 0);
	should_pass("190151643", $type, 0);
	should_pass("-112621736", $type, 0);
	should_pass("98792388", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value -1728117668." => sub {
	my $type = mk_type('Int', {'minInclusive' => '-1728117668'});
	should_pass("-1728117668", $type, 0);
	should_pass("-814587757", $type, 0);
	should_pass("2069610640", $type, 0);
	should_pass("86987481", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value -484721378." => sub {
	my $type = mk_type('Int', {'minInclusive' => '-484721378'});
	should_pass("-484721378", $type, 0);
	should_pass("455017347", $type, 0);
	should_pass("913084689", $type, 0);
	should_pass("919609429", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value 1012081748." => sub {
	my $type = mk_type('Int', {'minInclusive' => '1012081748'});
	should_pass("1012081748", $type, 0);
	should_pass("1962924477", $type, 0);
	should_pass("2061791888", $type, 0);
	should_pass("1117627776", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value 2147483647." => sub {
	my $type = mk_type('Int', {'minInclusive' => '2147483647'});
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value -2147483647." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '-2147483647'});
	should_pass("-2147483648", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value -1810120723." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '-1810120723'});
	should_pass("-2147483648", $type, 0);
	should_pass("-1850462532", $type, 0);
	should_pass("-1848695294", $type, 0);
	should_pass("-2068950192", $type, 0);
	should_pass("-1810120724", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value 1403226675." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '1403226675'});
	should_pass("-2147483648", $type, 0);
	should_pass("-314821885", $type, 0);
	should_pass("-1323723968", $type, 0);
	should_pass("-1185155929", $type, 0);
	should_pass("1403226674", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value -1338447688." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '-1338447688'});
	should_pass("-2147483648", $type, 0);
	should_pass("-2122631874", $type, 0);
	should_pass("-2134321545", $type, 0);
	should_pass("-1824892031", $type, 0);
	should_pass("-1338447689", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value 2147483647." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '2147483647'});
	should_pass("-2147483648", $type, 0);
	should_pass("-1925888897", $type, 0);
	should_pass("367544275", $type, 0);
	should_pass("1877337193", $type, 0);
	should_pass("2147483646", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value -2147483648." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '-2147483648'});
	should_pass("-2147483648", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value -1910754291." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '-1910754291'});
	should_pass("-2147483648", $type, 0);
	should_pass("-1950916646", $type, 0);
	should_pass("-1953865974", $type, 0);
	should_pass("-2001500912", $type, 0);
	should_pass("-1910754291", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value 1033309964." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '1033309964'});
	should_pass("-2147483648", $type, 0);
	should_pass("-1135211238", $type, 0);
	should_pass("-1086646887", $type, 0);
	should_pass("-871959884", $type, 0);
	should_pass("1033309964", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value 348085051." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '348085051'});
	should_pass("-2147483648", $type, 0);
	should_pass("-1756416665", $type, 0);
	should_pass("260108624", $type, 0);
	should_pass("-1559552005", $type, 0);
	should_pass("348085051", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value 2147483647." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '2147483647'});
	should_pass("-2147483648", $type, 0);
	should_pass("171860631", $type, 0);
	should_pass("1437643801", $type, 0);
	should_pass("716321140", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Int', {'fractionDigits' => '0'});
	should_pass("-2147483648", $type, 0);
	should_pass("1958247551", $type, 0);
	should_pass("-1159431106", $type, 0);
	should_pass("1969512786", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Int', {'totalDigits' => '1'});
	should_pass("2", $type, 0);
	should_pass("6", $type, 0);
	should_pass("1", $type, 0);
	should_pass("1", $type, 0);
	should_pass("7", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('Int', {'totalDigits' => '3'});
	should_pass("2", $type, 0);
	should_pass("32", $type, 0);
	should_pass("902", $type, 0);
	should_pass("1", $type, 0);
	should_pass("88", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('Int', {'totalDigits' => '5'});
	should_pass("6", $type, 0);
	should_pass("56", $type, 0);
	should_pass("482", $type, 0);
	should_pass("5382", $type, 0);
	should_pass("31986", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('Int', {'totalDigits' => '7'});
	should_pass("3", $type, 0);
	should_pass("83", $type, 0);
	should_pass("524", $type, 0);
	should_pass("7574", $type, 0);
	should_pass("6269784", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('Int', {'totalDigits' => '10'});
	should_pass("4", $type, 0);
	should_pass("721", $type, 0);
	should_pass("12077", $type, 0);
	should_pass("4536775", $type, 0);
	should_pass("1377882784", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\-\\d{10}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\-\d{10}$)/});
	should_pass("-2021151233", $type, 0);
	should_pass("-2123141222", $type, 0);
	should_pass("-2122362122", $type, 0);
	should_pass("-2126241225", $type, 0);
	should_pass("-2026142512", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_pass("-63629", $type, 0);
	should_pass("-25648", $type, 0);
	should_pass("-62278", $type, 0);
	should_pass("-86928", $type, 0);
	should_pass("-32647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-5", $type, 0);
	should_pass("-6", $type, 0);
	should_pass("-9", $type, 0);
	should_pass("-3", $type, 0);
	should_pass("-4", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_pass("526", $type, 0);
	should_pass("637", $type, 0);
	should_pass("864", $type, 0);
	should_pass("356", $type, 0);
	should_pass("146", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\d{10}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\d{10}$)/});
	should_pass("2124321125", $type, 0);
	should_pass("2011272332", $type, 0);
	should_pass("2026262112", $type, 0);
	should_pass("2124131112", $type, 0);
	should_pass("2023271111", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['-8','-48251','-726612373','7142','-2212763','-532985353']});
	should_pass("-48251", $type, 0);
	should_pass("-2212763", $type, 0);
	should_pass("-48251", $type, 0);
	should_pass("-48251", $type, 0);
	should_pass("-726612373", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['-2147483648','516405021','997702013','-4389','-279694555','2147483647','-8333939','68011','376934']});
	should_pass("997702013", $type, 0);
	should_pass("-8333939", $type, 0);
	should_pass("-2147483648", $type, 0);
	should_pass("2147483647", $type, 0);
	should_pass("997702013", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['2147483647','70977758','323669986','-314','-53685045','9391921','43292492','-2142090']});
	should_pass("9391921", $type, 0);
	should_pass("-314", $type, 0);
	should_pass("323669986", $type, 0);
	should_pass("43292492", $type, 0);
	should_pass("323669986", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['762','-7786609','13025','444723','628279555','-929293','2147483647','994943306']});
	should_pass("2147483647", $type, 0);
	should_pass("-7786609", $type, 0);
	should_pass("-7786609", $type, 0);
	should_pass("444723", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['-765383','-878521','-642','231','-2']});
	should_pass("-642", $type, 0);
	should_pass("-765383", $type, 0);
	should_pass("-642", $type, 0);
	should_pass("-2", $type, 0);
	should_pass("-878521", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Int', {'whiteSpace' => 'collapse'});
	should_pass("-2147483648", $type, 0);
	should_pass("-1857713729", $type, 0);
	should_pass("-1858797953", $type, 0);
	should_pass("1894997310", $type, 0);
	should_pass("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value -1105723757." => sub {
	my $type = mk_type('Int', {'minInclusive' => '-1105723757'});
	should_fail("-2147483648", $type, 0);
	should_fail("-1554203522", $type, 0);
	should_fail("-1867927754", $type, 0);
	should_fail("-1246783233", $type, 0);
	should_fail("-1105723758", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value 314385179." => sub {
	my $type = mk_type('Int', {'minInclusive' => '314385179'});
	should_fail("-2147483648", $type, 0);
	should_fail("-202084546", $type, 0);
	should_fail("-1030582070", $type, 0);
	should_fail("-558804931", $type, 0);
	should_fail("314385178", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value -978972026." => sub {
	my $type = mk_type('Int', {'minInclusive' => '-978972026'});
	should_fail("-2147483648", $type, 0);
	should_fail("-1886474009", $type, 0);
	should_fail("-2048558050", $type, 0);
	should_fail("-1270407674", $type, 0);
	should_fail("-978972027", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value 990570194." => sub {
	my $type = mk_type('Int', {'minInclusive' => '990570194'});
	should_fail("-2147483648", $type, 0);
	should_fail("238590822", $type, 0);
	should_fail("695318947", $type, 0);
	should_fail("895695993", $type, 0);
	should_fail("990570193", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minInclusive with value 2147483647." => sub {
	my $type = mk_type('Int', {'minInclusive' => '2147483647'});
	should_fail("-2147483648", $type, 0);
	should_fail("1357856806", $type, 0);
	should_fail("-319808428", $type, 0);
	should_fail("-121654525", $type, 0);
	should_fail("2147483646", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value -2147483648." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '-2147483648'});
	should_fail("-2147483647", $type, 0);
	should_fail("157650509", $type, 0);
	should_fail("145963417", $type, 0);
	should_fail("-1718129641", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value 107981828." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '107981828'});
	should_fail("107981829", $type, 0);
	should_fail("690669358", $type, 0);
	should_fail("797235603", $type, 0);
	should_fail("554730780", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value -1631590701." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '-1631590701'});
	should_fail("-1631590700", $type, 0);
	should_fail("746911236", $type, 0);
	should_fail("1443179759", $type, 0);
	should_fail("-1281519134", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value -396617149." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '-396617149'});
	should_fail("-396617148", $type, 0);
	should_fail("1984167525", $type, 0);
	should_fail("1869474272", $type, 0);
	should_fail("1326598106", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxInclusive with value 1617521685." => sub {
	my $type = mk_type('Int', {'maxInclusive' => '1617521685'});
	should_fail("1617521686", $type, 0);
	should_fail("2058985880", $type, 0);
	should_fail("2093269693", $type, 0);
	should_fail("1714939022", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Int', {'totalDigits' => '1'});
	should_fail("14", $type, 0);
	should_fail("1938", $type, 0);
	should_fail("377163", $type, 0);
	should_fail("61711285", $type, 0);
	should_fail("1516122451", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('Int', {'totalDigits' => '2'});
	should_fail("258", $type, 0);
	should_fail("2282", $type, 0);
	should_fail("72675", $type, 0);
	should_fail("418404", $type, 0);
	should_fail("1260205586", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('Int', {'totalDigits' => '3'});
	should_fail("2457", $type, 0);
	should_fail("51587", $type, 0);
	should_fail("750043", $type, 0);
	should_fail("4422785", $type, 0);
	should_fail("1653135776", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('Int', {'totalDigits' => '4'});
	should_fail("86408", $type, 0);
	should_fail("568165", $type, 0);
	should_fail("2113676", $type, 0);
	should_fail("65357261", $type, 0);
	should_fail("1623517461", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('Int', {'totalDigits' => '5'});
	should_fail("107802", $type, 0);
	should_fail("2591104", $type, 0);
	should_fail("21390625", $type, 0);
	should_fail("784566563", $type, 0);
	should_fail("1257555418", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value -2147483648." => sub {
	my $type = mk_type('Int', {'minExclusive' => '-2147483648'});
	should_fail("-2147483648", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value -1347613196." => sub {
	my $type = mk_type('Int', {'minExclusive' => '-1347613196'});
	should_fail("-2147483648", $type, 0);
	should_fail("-1941168364", $type, 0);
	should_fail("-1711127617", $type, 0);
	should_fail("-1368513905", $type, 0);
	should_fail("-1347613196", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value -52553616." => sub {
	my $type = mk_type('Int', {'minExclusive' => '-52553616'});
	should_fail("-2147483648", $type, 0);
	should_fail("-724022492", $type, 0);
	should_fail("-1508674745", $type, 0);
	should_fail("-52996607", $type, 0);
	should_fail("-52553616", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value 545642569." => sub {
	my $type = mk_type('Int', {'minExclusive' => '545642569'});
	should_fail("-2147483648", $type, 0);
	should_fail("-536743899", $type, 0);
	should_fail("363486011", $type, 0);
	should_fail("-1454064932", $type, 0);
	should_fail("545642569", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet minExclusive with value 2147483646." => sub {
	my $type = mk_type('Int', {'minExclusive' => '2147483646'});
	should_fail("-2147483648", $type, 0);
	should_fail("-481987679", $type, 0);
	should_fail("919865681", $type, 0);
	should_fail("-590002976", $type, 0);
	should_fail("2147483646", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value -2147483647." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '-2147483647'});
	should_fail("-2147483647", $type, 0);
	should_fail("1320063562", $type, 0);
	should_fail("883318207", $type, 0);
	should_fail("1579179461", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value -1862034354." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '-1862034354'});
	should_fail("-1862034354", $type, 0);
	should_fail("1603056474", $type, 0);
	should_fail("-1538388085", $type, 0);
	should_fail("1638251926", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value -1564577088." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '-1564577088'});
	should_fail("-1564577088", $type, 0);
	should_fail("801713771", $type, 0);
	should_fail("1786441673", $type, 0);
	should_fail("1669059396", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value 1028669252." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '1028669252'});
	should_fail("1028669252", $type, 0);
	should_fail("1727749747", $type, 0);
	should_fail("2034721430", $type, 0);
	should_fail("2146626319", $type, 0);
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet maxExclusive with value 2147483647." => sub {
	my $type = mk_type('Int', {'maxExclusive' => '2147483647'});
	should_fail("2147483647", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\-\\d{10}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\-\d{10}$)/});
	should_fail("37", $type, 0);
	should_fail("-96215428", $type, 0);
	should_fail("-252765767", $type, 0);
	should_fail("-6372239", $type, 0);
	should_fail("-4567324", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_fail("2928288", $type, 0);
	should_fail("-55", $type, 0);
	should_fail("-656423387", $type, 0);
	should_fail("-7863", $type, 0);
	should_fail("884355", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("4713", $type, 0);
	should_fail("-6741", $type, 0);
	should_fail("41", $type, 0);
	should_fail("6421527", $type, 0);
	should_fail("-645751222", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_fail("-38", $type, 0);
	should_fail("7543", $type, 0);
	should_fail("-2025222435", $type, 0);
	should_fail("2126271224", $type, 0);
	should_fail("-61", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet pattern with value \\d{10}." => sub {
	my $type = mk_type('Int', {'pattern' => qr/(?ms:^\d{10}$)/});
	should_fail("-5566282", $type, 0);
	should_fail("-158417927", $type, 0);
	should_fail("34672729", $type, 0);
	should_fail("4296", $type, 0);
	should_fail("662153738", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['759','-97403404','-29705135','-147897','353','-71','-52084']});
	should_fail("-1538024579", $type, 0);
	should_fail("5365287", $type, 0);
	should_fail("114571599", $type, 0);
	should_fail("5365287", $type, 0);
	should_fail("-1816238048", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['-46','818','588859393','53463862','2147483647','-132','584','-547137375','4973060']});
	should_fail("116970484", $type, 0);
	should_fail("1583653002", $type, 0);
	should_fail("989798885", $type, 0);
	should_fail("-476887895", $type, 0);
	should_fail("1837761890", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['-13330','86645069','67442821','1582227530','-47830239']});
	should_fail("-1338835307", $type, 0);
	should_fail("-695473537", $type, 0);
	should_fail("-386708731", $type, 0);
	should_fail("-386708731", $type, 0);
	should_fail("1837505618", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['6','3884586','36355213','-6796311','-34','-908904','880440401','-79776522']});
	should_fail("2147483647", $type, 0);
	should_fail("384508812", $type, 0);
	should_fail("-2068540027", $type, 0);
	should_fail("-1583879972", $type, 0);
	should_fail("729371608", $type, 0);
	done_testing;
};

subtest "Type atomic/int is restricted by facet enumeration." => sub {
	my $type = mk_type('Int', {'enumeration' => ['59132','-657815','-2147483648','3161','1331418175','-29278736']});
	should_fail("-219237349", $type, 0);
	should_fail("-899341555", $type, 0);
	should_fail("-219237349", $type, 0);
	should_fail("898550454", $type, 0);
	should_fail("1622854063", $type, 0);
	done_testing;
};

done_testing;

