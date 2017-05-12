use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/decimal is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '-999999999999999999'});
	should_pass("-999999999999999998", $type, 0);
	should_pass("743242983065211192", $type, 0);
	should_pass("-298277777844702550", $type, 0);
	should_pass("-489622089249996726", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value 631308414640570968." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '631308414640570968'});
	should_pass("631308414640570969", $type, 0);
	should_pass("655270940327769770", $type, 0);
	should_pass("633688260227604501", $type, 0);
	should_pass("724204691061185475", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value -67428259604688900." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '-67428259604688900'});
	should_pass("-67428259604688899.9", $type, 0);
	should_pass("964512941415486691.7", $type, 0);
	should_pass("929574180872636469.1", $type, 0);
	should_pass("10009076448161849.4", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value -294253147230818967." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '-294253147230818967'});
	should_pass("-294253147230818966", $type, 0);
	should_pass("42621829743492400", $type, 0);
	should_pass("778328217399065823", $type, 0);
	should_pass("303014161192265037", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '999999999999999998'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-479965255856956706", $type, 0);
	should_pass("870254101268362444", $type, 0);
	should_pass("934935134052641058", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 229822855408968073." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '229822855408968073'});
	should_pass("229822855408968073", $type, 0);
	should_pass("583563079235933449", $type, 0);
	should_pass("693743199641761298", $type, 0);
	should_pass("877108449600715506", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value -785368448026986020." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '-785368448026986020'});
	should_pass("-785368448026986020", $type, 0);
	should_pass("-286947689254679556", $type, 0);
	should_pass("126998522279017820", $type, 0);
	should_pass("-119719541893928025", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 325207740352921658." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '325207740352921658'});
	should_pass("325207740352921658", $type, 0);
	should_pass("707562012596744786", $type, 0);
	should_pass("748498012179183663", $type, 0);
	should_pass("330318245307241752", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '999999999999999999'});
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '-999999999999999998'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value 78119693427168402." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '78119693427168402'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-96490893692868357.6", $type, 0);
	should_pass("-755590101850159647.2", $type, 0);
	should_pass("-5141080192436564.5", $type, 0);
	should_pass("78119693427168401.9", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value 171942968603657986." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '171942968603657986'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-949549894722090902", $type, 0);
	should_pass("-322109878631769832", $type, 0);
	should_pass("-879600105740250893", $type, 0);
	should_pass("171942968603657985", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value -214771926190724381." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '-214771926190724381'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-673138182227871496", $type, 0);
	should_pass("-790816317239260538", $type, 0);
	should_pass("-771501840474373263", $type, 0);
	should_pass("-214771926190724382", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-898677092665433495", $type, 0);
	should_pass("-811125566986646839", $type, 0);
	should_pass("252077093927926209", $type, 0);
	should_pass("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '-999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value 625897845365533055." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '625897845365533055'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-904949153608526819", $type, 0);
	should_pass("89736250999809495", $type, 0);
	should_pass("316378507306027046", $type, 0);
	should_pass("625897845365533055", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value -888403528420030673." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '-888403528420030673'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-892559497148452709", $type, 0);
	should_pass("-963657554932478572", $type, 0);
	should_pass("-931230510007482365", $type, 0);
	should_pass("-888403528420030673", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value -95776055693671313." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '-95776055693671313'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-286380458379470656", $type, 0);
	should_pass("-461116417455741628", $type, 0);
	should_pass("-561010407438011614", $type, 0);
	should_pass("-95776055693671313", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '999999999999999999'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("-868387287908872983", $type, 0);
	should_pass("-58200625491938273", $type, 0);
	should_pass("-77940022604026548", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '0'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("99137122271968136", $type, 0);
	should_pass("-256179772521919035", $type, 0);
	should_pass("794953751044983335", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 4." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '4'});
	should_pass("123456789123456789", $type, 0);
	should_pass("12345678912345678.9", $type, 0);
	should_pass("1234567891234567.89", $type, 0);
	should_pass("123456789123456.789", $type, 0);
	should_pass("12345678912345.6789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 8." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '8'});
	should_pass("123456789123456789", $type, 0);
	should_pass("1234567891234567.89", $type, 0);
	should_pass("12345678912345.6789", $type, 0);
	should_pass("123456789123.456789", $type, 0);
	should_pass("1234567891.23456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 12." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '12'});
	should_pass("123456789123456789", $type, 0);
	should_pass("123456789123456.789", $type, 0);
	should_pass("123456789123.456789", $type, 0);
	should_pass("123456789.123456789", $type, 0);
	should_pass("123456.789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 18." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '18'});
	should_pass("123456789123456789", $type, 0);
	should_pass("12345678912345.6789", $type, 0);
	should_pass("1234567891.23456789", $type, 0);
	should_pass("123456.789123456789", $type, 0);
	should_pass(".123456789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '1'});
	should_pass("9", $type, 0);
	should_pass("7", $type, 0);
	should_pass("9", $type, 0);
	should_pass("1", $type, 0);
	should_pass("8", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '5'});
	should_pass("3", $type, 0);
	should_pass("82", $type, 0);
	should_pass("513", $type, 0);
	should_pass("5330", $type, 0);
	should_pass("17254", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 9." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '9'});
	should_pass("2", $type, 0);
	should_pass("353", $type, 0);
	should_pass("95326", $type, 0);
	should_pass("2513421", $type, 0);
	should_pass("581216683", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '13'});
	should_pass("9", $type, 0);
	should_pass("5514", $type, 0);
	should_pass("1524616", $type, 0);
	should_pass("8864756997", $type, 0);
	should_pass("8178688412222", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 18." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '18'});
	should_pass("4", $type, 0);
	should_pass("82757", $type, 0);
	should_pass("321149124", $type, 0);
	should_pass("4303115591742", $type, 0);
	should_pass("526575824825222369", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("3", $type, 0);
	should_pass("2", $type, 0);
	should_pass("2", $type, 0);
	should_pass("4", $type, 0);
	should_pass("9", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\-\\d{2}\\.\\d{3}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\-\d{2}\.\d{3}$)/});
	should_pass("-24.547", $type, 0);
	should_pass("-65.424", $type, 0);
	should_pass("-31.228", $type, 0);
	should_pass("-46.582", $type, 0);
	should_pass("-12.216", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\-\\d{1}\\.\\d{8}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\-\d{1}\.\d{8}$)/});
	should_pass("-7.48951421", $type, 0);
	should_pass("-4.34531931", $type, 0);
	should_pass("-7.37470534", $type, 0);
	should_pass("-4.58314140", $type, 0);
	should_pass("-7.73893515", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\.\\d{13}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\.\d{13}$)/});
	should_pass(".2684842045582", $type, 0);
	should_pass(".1165417431543", $type, 0);
	should_pass(".1055532252427", $type, 0);
	should_pass(".2338485411688", $type, 0);
	should_pass(".7974769556356", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\d{5}\\.\\d{13}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\d{5}\.\d{13}$)/});
	should_pass("55217.9736118850526", $type, 0);
	should_pass("16876.8783301171042", $type, 0);
	should_pass("11416.7935261225030", $type, 0);
	should_pass("67916.2046755544972", $type, 0);
	should_pass("67535.5493283257017", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['0.774','885368.72','8.63882452','-0.92','549.95','-1914.0']});
	should_pass("8.63882452", $type, 0);
	should_pass("-0.92", $type, 0);
	should_pass("-1914.0", $type, 0);
	should_pass("8.63882452", $type, 0);
	should_pass("549.95", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['89.20902289982400','729089.6','108747.8431','89.98169071278','8.843008676','7.682949472786','31588397646362.1','-61113534938.0','0.575']});
	should_pass("-61113534938.0", $type, 0);
	should_pass("729089.6", $type, 0);
	should_pass("0.575", $type, 0);
	should_pass("7.682949472786", $type, 0);
	should_pass("89.20902289982400", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['840','-584.55228','-97585886185','0.672','-75.62365','-7.335','0.86054905','-5439.8474996']});
	should_pass("-97585886185", $type, 0);
	should_pass("-7.335", $type, 0);
	should_pass("0.672", $type, 0);
	should_pass("0.672", $type, 0);
	should_pass("-5439.8474996", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['613.87','1906433845.89','-2.39446916113','-5286034.1','8838363181.0150']});
	should_pass("613.87", $type, 0);
	should_pass("-2.39446916113", $type, 0);
	should_pass("613.87", $type, 0);
	should_pass("1906433845.89", $type, 0);
	should_pass("1906433845.89", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['856.89','6.9307231814179','-150','337920.941','0.3316','-82.78605057','-0.61']});
	should_pass("-82.78605057", $type, 0);
	should_pass("0.3316", $type, 0);
	should_pass("337920.941", $type, 0);
	should_pass("0.3316", $type, 0);
	should_pass("-150", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Decimal', {'whiteSpace' => 'collapse'});
	should_pass("-999999999999999999", $type, 0);
	should_pass("208837336784347682", $type, 0);
	should_pass("831121983923768014", $type, 0);
	should_pass("463294725437835008", $type, 0);
	should_pass("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 46766021207033325." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '46766021207033325'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-82035416317982814.9", $type, 0);
	should_fail("-116283630323041617.3", $type, 0);
	should_fail("-507102669884162774.8", $type, 0);
	should_fail("46766021207033324.9", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 217527397529179155." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '217527397529179155'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-642389304015569471", $type, 0);
	should_fail("194432658843846068", $type, 0);
	should_fail("-320930938798775041", $type, 0);
	should_fail("217527397529179154", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value -484062845034851418." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '-484062845034851418'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-744312015684597677", $type, 0);
	should_fail("-798318711162899803", $type, 0);
	should_fail("-756444991985341836", $type, 0);
	should_fail("-484062845034851419", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 913110463857996767." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '913110463857996767'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("219067290813932176", $type, 0);
	should_fail("476222585470221001", $type, 0);
	should_fail("-977179111791051587", $type, 0);
	should_fail("913110463857996766", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minInclusive with value 999999999999999999." => sub {
	my $type = mk_type('Decimal', {'minInclusive' => '999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("948164537304475361", $type, 0);
	should_fail("347408282265509792", $type, 0);
	should_fail("-213987886304789709", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value -999999999999999999." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '-999999999999999999'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("704874057733450020", $type, 0);
	should_fail("209113495339849242", $type, 0);
	should_fail("833990441992082941", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value 334974685437745555." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '334974685437745555'});
	should_fail("334974685437745556", $type, 0);
	should_fail("854169634314423861", $type, 0);
	should_fail("573806945776759695", $type, 0);
	should_fail("807371345967442368", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value -873150926158042127." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '-873150926158042127'});
	should_fail("-873150926158042126", $type, 0);
	should_fail("305728505095716730", $type, 0);
	should_fail("-283733388508344998", $type, 0);
	should_fail("917584284119832151", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value -276828978495828214." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '-276828978495828214'});
	should_fail("-276828978495828213", $type, 0);
	should_fail("-168341274308303273", $type, 0);
	should_fail("-55137136585436293", $type, 0);
	should_fail("468581798712038836", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxInclusive with value 187840545667389724." => sub {
	my $type = mk_type('Decimal', {'maxInclusive' => '187840545667389724'});
	should_fail("187840545667389725", $type, 0);
	should_fail("339229216664273730", $type, 0);
	should_fail("934076830476541443", $type, 0);
	should_fail("983589035502023346", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '0'});
	should_fail("12345678912345678.9", $type, 0);
	should_fail("1234567891234.56789", $type, 0);
	should_fail("123456789.123456789", $type, 0);
	should_fail("12345.6789123456789", $type, 0);
	should_fail(".123456789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 3." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '3'});
	should_fail("12345678912345.6789", $type, 0);
	should_fail("12345678912.3456789", $type, 0);
	should_fail("12345678.9123456789", $type, 0);
	should_fail("12345.6789123456789", $type, 0);
	should_fail(".123456789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 6." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '6'});
	should_fail("12345678912.3456789", $type, 0);
	should_fail("123456789.123456789", $type, 0);
	should_fail("1234567.89123456789", $type, 0);
	should_fail("12345.6789123456789", $type, 0);
	should_fail(".123456789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 9." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '9'});
	should_fail("12345678.9123456789", $type, 0);
	should_fail("123456.789123456789", $type, 0);
	should_fail("1234.56789123456789", $type, 0);
	should_fail("12.3456789123456789", $type, 0);
	should_fail(".123456789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet fractionDigits with value 12." => sub {
	my $type = mk_type('Decimal', {'fractionDigits' => '12'});
	should_fail("12345.6789123456789", $type, 0);
	should_fail("1234.56789123456789", $type, 0);
	should_fail("123.456789123456789", $type, 0);
	should_fail("12.3456789123456789", $type, 0);
	should_fail(".123456789123456789", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '1'});
	should_fail("61", $type, 0);
	should_fail("777054", $type, 0);
	should_fail("3113816699", $type, 0);
	should_fail("61315691291273", $type, 0);
	should_fail("354128147257253653", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '4'});
	should_fail("28265", $type, 0);
	should_fail("85558005", $type, 0);
	should_fail("70552163453", $type, 0);
	should_fail("17566155886475", $type, 0);
	should_fail("692412876221863375", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 7." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '7'});
	should_fail("16365494", $type, 0);
	should_fail("2968213192", $type, 0);
	should_fail("470843264218", $type, 0);
	should_fail("12171827714185", $type, 0);
	should_fail("426453427863172041", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 10." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '10'});
	should_fail("18747415133", $type, 0);
	should_fail("111010154613", $type, 0);
	should_fail("8568256181607", $type, 0);
	should_fail("34732211933321", $type, 0);
	should_fail("338610360158571185", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet totalDigits with value 13." => sub {
	my $type = mk_type('Decimal', {'totalDigits' => '13'});
	should_fail("18521730524616", $type, 0);
	should_fail("178163458326868", $type, 0);
	should_fail("3921554721062893", $type, 0);
	should_fail("21558713367427384", $type, 0);
	should_fail("373687644748891316", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value -999999999999999999." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '-999999999999999999'});
	should_fail("-999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value -742667420521034182." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '-742667420521034182'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-873668702595663188", $type, 0);
	should_fail("-875371982501205708", $type, 0);
	should_fail("-746298922746964699", $type, 0);
	should_fail("-742667420521034182", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value -990296746466916787." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '-990296746466916787'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("-994232159881783270", $type, 0);
	should_fail("-990366049657691773", $type, 0);
	should_fail("-994038375252986787", $type, 0);
	should_fail("-990296746466916787", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value 604887570436412057." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '604887570436412057'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("587916849690211326", $type, 0);
	should_fail("-505435956225881732", $type, 0);
	should_fail("-362094017196074591", $type, 0);
	should_fail("604887570436412057", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet minExclusive with value 999999999999999998." => sub {
	my $type = mk_type('Decimal', {'minExclusive' => '999999999999999998'});
	should_fail("-999999999999999999", $type, 0);
	should_fail("990234289529774656", $type, 0);
	should_fail("-168010106926399727", $type, 0);
	should_fail("-758263458208696671", $type, 0);
	should_fail("999999999999999998", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value -999999999999999998." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '-999999999999999998'});
	should_fail("-999999999999999998", $type, 0);
	should_fail("-735099782760447738", $type, 0);
	should_fail("-701067706877750217", $type, 0);
	should_fail("563399700388934165", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value -407946586294197554." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '-407946586294197554'});
	should_fail("-407946586294197554", $type, 0);
	should_fail("170561410536352337", $type, 0);
	should_fail("834811255246798541", $type, 0);
	should_fail("263175454538351659", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value -663400175032719417." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '-663400175032719417'});
	should_fail("-663400175032719417", $type, 0);
	should_fail("281117135260569906", $type, 0);
	should_fail("-341239977425938983", $type, 0);
	should_fail("-53150907639494195", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value -491326681056714730." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '-491326681056714730'});
	should_fail("-491326681056714730", $type, 0);
	should_fail("449964112725542981", $type, 0);
	should_fail("781090115734859921", $type, 0);
	should_fail("248281740579833699", $type, 0);
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet maxExclusive with value 999999999999999999." => sub {
	my $type = mk_type('Decimal', {'maxExclusive' => '999999999999999999'});
	should_fail("999999999999999999", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("33485.142484370", $type, 0);
	should_fail("22277333688275456.1", $type, 0);
	should_fail("533.47561744", $type, 0);
	should_fail("-32143132.775", $type, 0);
	should_fail("583.07", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\d{1}\\.\\d{4}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\d{1}\.\d{4}$)/});
	should_fail("-8554.601982", $type, 0);
	should_fail("944224585854343587", $type, 0);
	should_fail("421252945.60641372", $type, 0);
	should_fail("75538277749.623", $type, 0);
	should_fail("866392.8623164201", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\-\\d{5}\\.\\d{4}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\-\d{5}\.\d{4}$)/});
	should_fail("2978258.516875716", $type, 0);
	should_fail("-3333144481863.7", $type, 0);
	should_fail("5976326.11677485", $type, 0);
	should_fail("559.5603990704", $type, 0);
	should_fail("-642.26405", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\d{10}\\.\\d{3}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\d{10}\.\d{3}$)/});
	should_fail("-84225859357429657.5", $type, 0);
	should_fail("844382745.346644", $type, 0);
	should_fail("-85.56736916122194", $type, 0);
	should_fail("4.2536055668381", $type, 0);
	should_fail("463434.957553725", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet pattern with value \\-\\d{17}\\.\\d{1}." => sub {
	my $type = mk_type('Decimal', {'pattern' => qr/(?ms:^\-\d{17}\.\d{1}$)/});
	should_fail("222935976.00581813", $type, 0);
	should_fail("4763.344745968", $type, 0);
	should_fail("-41338645.5464910", $type, 0);
	should_fail("2589394455884.5340", $type, 0);
	should_fail("-5388.7212686", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['37.3299','538557030.40878244','5784970.9','-427178192921.58787','-21.68136395279','-57647479233521647','693700.4405008','4.6311217','3.7','-3073.80']});
	should_fail("-502354523120606799", $type, 0);
	should_fail("221533348282852537", $type, 0);
	should_fail("-853805601507541477", $type, 0);
	should_fail("-433480763327352080", $type, 0);
	should_fail("124650441041409543", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['832.6061','-644441.60','-43.9537851','-3.6993897','-935734286.436217144','5386.68991312147','2205242375326.127']});
	should_fail("-408689031972378824", $type, 0);
	should_fail("-106409202240518085", $type, 0);
	should_fail("-769651937952429587", $type, 0);
	should_fail("772891982319434011", $type, 0);
	should_fail("-755901886467195138", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['304640092.2488','7081563.27','2564389.772','-4141.50462135505','-358827.0','-153426.61','5.150156720404','-0.7144']});
	should_fail("177925645621303640", $type, 0);
	should_fail("-965869140580617234", $type, 0);
	should_fail("-795893491728559609", $type, 0);
	should_fail("-815977366399654568", $type, 0);
	should_fail("87705392143277105", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['-10.5985919','620.809990','454134390717.3','35','-525268.515823','-7827798518.104','-1293739.34']});
	should_fail("13775870503200948", $type, 0);
	should_fail("-38941978700236967", $type, 0);
	should_fail("-707626978704362529", $type, 0);
	should_fail("13775870503200948", $type, 0);
	should_fail("-587995474964697616", $type, 0);
	done_testing;
};

subtest "Type atomic/decimal is restricted by facet enumeration." => sub {
	my $type = mk_type('Decimal', {'enumeration' => ['-328074519.2','-16250.3','-198.9','2.82436570042079448','927.15']});
	should_fail("359155983938342026", $type, 0);
	should_fail("319004331918121497", $type, 0);
	should_fail("748689826255232170", $type, 0);
	should_fail("125609983152650927", $type, 0);
	should_fail("-888196266682436784", $type, 0);
	done_testing;
};

done_testing;

