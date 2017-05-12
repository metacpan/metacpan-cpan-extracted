use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/byte is restricted by facet minExclusive with value -128." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '-128'});
	should_pass("-127", $type, 0);
	should_pass("-3", $type, 0);
	should_pass("125", $type, 0);
	should_pass("97", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 32." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '32'});
	should_pass("33", $type, 0);
	should_pass("56", $type, 0);
	should_pass("47", $type, 0);
	should_pass("110", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 79." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '79'});
	should_pass("80", $type, 0);
	should_pass("111", $type, 0);
	should_pass("113", $type, 0);
	should_pass("84", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 95." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '95'});
	should_pass("96", $type, 0);
	should_pass("122", $type, 0);
	should_pass("109", $type, 0);
	should_pass("97", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 126." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '126'});
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value -128." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '-128'});
	should_pass("-128", $type, 0);
	should_pass("125", $type, 0);
	should_pass("-103", $type, 0);
	should_pass("122", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value 35." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '35'});
	should_pass("35", $type, 0);
	should_pass("56", $type, 0);
	should_pass("36", $type, 0);
	should_pass("47", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value 28." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '28'});
	should_pass("28", $type, 0);
	should_pass("60", $type, 0);
	should_pass("113", $type, 0);
	should_pass("35", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value -50." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '-50'});
	should_pass("-50", $type, 0);
	should_pass("52", $type, 0);
	should_pass("124", $type, 0);
	should_pass("62", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value 127." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '127'});
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value -127." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '-127'});
	should_pass("-128", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value -15." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '-15'});
	should_pass("-128", $type, 0);
	should_pass("-116", $type, 0);
	should_pass("-56", $type, 0);
	should_pass("-41", $type, 0);
	should_pass("-16", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value 103." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '103'});
	should_pass("-128", $type, 0);
	should_pass("-1", $type, 0);
	should_pass("44", $type, 0);
	should_pass("68", $type, 0);
	should_pass("102", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value 110." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '110'});
	should_pass("-128", $type, 0);
	should_pass("-100", $type, 0);
	should_pass("-59", $type, 0);
	should_pass("-42", $type, 0);
	should_pass("109", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value 127." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '127'});
	should_pass("-128", $type, 0);
	should_pass("3", $type, 0);
	should_pass("-73", $type, 0);
	should_pass("-19", $type, 0);
	should_pass("126", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value -128." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '-128'});
	should_pass("-128", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value 123." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '123'});
	should_pass("-128", $type, 0);
	should_pass("117", $type, 0);
	should_pass("-75", $type, 0);
	should_pass("11", $type, 0);
	should_pass("123", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value 17." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '17'});
	should_pass("-128", $type, 0);
	should_pass("1", $type, 0);
	should_pass("-5", $type, 0);
	should_pass("-112", $type, 0);
	should_pass("17", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value -47." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '-47'});
	should_pass("-128", $type, 0);
	should_pass("-81", $type, 0);
	should_pass("-69", $type, 0);
	should_pass("-98", $type, 0);
	should_pass("-47", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value 127." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '127'});
	should_pass("-128", $type, 0);
	should_pass("96", $type, 0);
	should_pass("-55", $type, 0);
	should_pass("-57", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Byte', {'fractionDigits' => '0'});
	should_pass("-128", $type, 0);
	should_pass("31", $type, 0);
	should_pass("24", $type, 0);
	should_pass("-13", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Byte', {'totalDigits' => '1'});
	should_pass("7", $type, 0);
	should_pass("6", $type, 0);
	should_pass("8", $type, 0);
	should_pass("5", $type, 0);
	should_pass("4", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('Byte', {'totalDigits' => '2'});
	should_pass("4", $type, 0);
	should_pass("31", $type, 0);
	should_pass("8", $type, 0);
	should_pass("81", $type, 0);
	should_pass("5", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('Byte', {'totalDigits' => '3'});
	should_pass("4", $type, 0);
	should_pass("78", $type, 0);
	should_pass("118", $type, 0);
	should_pass("7", $type, 0);
	should_pass("40", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\-\\d{3}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\-\d{3}$)/});
	should_pass("-113", $type, 0);
	should_pass("-114", $type, 0);
	should_pass("-113", $type, 0);
	should_pass("-114", $type, 0);
	should_pass("-112", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\-\\d{2}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\-\d{2}$)/});
	should_pass("-84", $type, 0);
	should_pass("-58", $type, 0);
	should_pass("-64", $type, 0);
	should_pass("-44", $type, 0);
	should_pass("-52", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-4", $type, 0);
	should_pass("-4", $type, 0);
	should_pass("-1", $type, 0);
	should_pass("-2", $type, 0);
	should_pass("-7", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("8", $type, 0);
	should_pass("2", $type, 0);
	should_pass("6", $type, 0);
	should_pass("5", $type, 0);
	should_pass("6", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_pass("114", $type, 0);
	should_pass("113", $type, 0);
	should_pass("113", $type, 0);
	should_pass("114", $type, 0);
	should_pass("116", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['-5','-4','-7','88','-128','20','127','-59','84']});
	should_pass("-59", $type, 0);
	should_pass("127", $type, 0);
	should_pass("-128", $type, 0);
	should_pass("-128", $type, 0);
	should_pass("-59", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['9','127','64','-81','3','-7','-93','50']});
	should_pass("-93", $type, 0);
	should_pass("3", $type, 0);
	should_pass("-93", $type, 0);
	should_pass("-7", $type, 0);
	should_pass("50", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['60','62','5','-128','4','57','127','30']});
	should_pass("62", $type, 0);
	should_pass("127", $type, 0);
	should_pass("-128", $type, 0);
	should_pass("-128", $type, 0);
	should_pass("-128", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['-5','96','127','-48','33','69','-60','-86']});
	should_pass("-48", $type, 0);
	should_pass("69", $type, 0);
	should_pass("33", $type, 0);
	should_pass("-48", $type, 0);
	should_pass("-60", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['-3','-128','41','127','-5','14','-45','-35','-89']});
	should_pass("-35", $type, 0);
	should_pass("14", $type, 0);
	should_pass("-45", $type, 0);
	should_pass("-128", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Byte', {'whiteSpace' => 'collapse'});
	should_pass("-128", $type, 0);
	should_pass("-125", $type, 0);
	should_pass("90", $type, 0);
	should_pass("-89", $type, 0);
	should_pass("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value -17." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '-17'});
	should_fail("-128", $type, 0);
	should_fail("-102", $type, 0);
	should_fail("-24", $type, 0);
	should_fail("-53", $type, 0);
	should_fail("-18", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '0'});
	should_fail("-128", $type, 0);
	should_fail("-124", $type, 0);
	should_fail("-110", $type, 0);
	should_fail("-15", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value -107." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '-107'});
	should_fail("-128", $type, 0);
	should_fail("-125", $type, 0);
	should_fail("-117", $type, 0);
	should_fail("-124", $type, 0);
	should_fail("-108", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value 19." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '19'});
	should_fail("-128", $type, 0);
	should_fail("4", $type, 0);
	should_fail("-64", $type, 0);
	should_fail("-14", $type, 0);
	should_fail("18", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minInclusive with value 127." => sub {
	my $type = mk_type('Byte', {'minInclusive' => '127'});
	should_fail("-128", $type, 0);
	should_fail("-85", $type, 0);
	should_fail("64", $type, 0);
	should_fail("36", $type, 0);
	should_fail("126", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value -128." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '-128'});
	should_fail("-127", $type, 0);
	should_fail("67", $type, 0);
	should_fail("15", $type, 0);
	should_fail("123", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value 122." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '122'});
	should_fail("123", $type, 0);
	should_fail("125", $type, 0);
	should_fail("126", $type, 0);
	should_fail("124", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value -93." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '-93'});
	should_fail("-92", $type, 0);
	should_fail("6", $type, 0);
	should_fail("-16", $type, 0);
	should_fail("-84", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value -91." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '-91'});
	should_fail("-90", $type, 0);
	should_fail("-56", $type, 0);
	should_fail("-22", $type, 0);
	should_fail("-41", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxInclusive with value -100." => sub {
	my $type = mk_type('Byte', {'maxInclusive' => '-100'});
	should_fail("-99", $type, 0);
	should_fail("-11", $type, 0);
	should_fail("91", $type, 0);
	should_fail("-1", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Byte', {'totalDigits' => '1'});
	should_fail("99", $type, 0);
	should_fail("108", $type, 0);
	should_fail("44", $type, 0);
	should_fail("113", $type, 0);
	should_fail("45", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('Byte', {'totalDigits' => '2'});
	should_fail("116", $type, 0);
	should_fail("126", $type, 0);
	should_fail("109", $type, 0);
	should_fail("111", $type, 0);
	should_fail("115", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value -128." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '-128'});
	should_fail("-128", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 17." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '17'});
	should_fail("-128", $type, 0);
	should_fail("-120", $type, 0);
	should_fail("-78", $type, 0);
	should_fail("-9", $type, 0);
	should_fail("17", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 113." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '113'});
	should_fail("-128", $type, 0);
	should_fail("8", $type, 0);
	should_fail("34", $type, 0);
	should_fail("75", $type, 0);
	should_fail("113", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value -118." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '-118'});
	should_fail("-128", $type, 0);
	should_fail("-118", $type, 0);
	should_fail("-119", $type, 0);
	should_fail("-121", $type, 0);
	should_fail("-118", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet minExclusive with value 126." => sub {
	my $type = mk_type('Byte', {'minExclusive' => '126'});
	should_fail("-128", $type, 0);
	should_fail("75", $type, 0);
	should_fail("-69", $type, 0);
	should_fail("91", $type, 0);
	should_fail("126", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value -127." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '-127'});
	should_fail("-127", $type, 0);
	should_fail("113", $type, 0);
	should_fail("-100", $type, 0);
	should_fail("2", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value 48." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '48'});
	should_fail("48", $type, 0);
	should_fail("119", $type, 0);
	should_fail("59", $type, 0);
	should_fail("74", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value 100." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '100'});
	should_fail("100", $type, 0);
	should_fail("113", $type, 0);
	should_fail("110", $type, 0);
	should_fail("115", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value -38." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '-38'});
	should_fail("-38", $type, 0);
	should_fail("35", $type, 0);
	should_fail("80", $type, 0);
	should_fail("-22", $type, 0);
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet maxExclusive with value 127." => sub {
	my $type = mk_type('Byte', {'maxExclusive' => '127'});
	should_fail("127", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\-\\d{3}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\-\d{3}$)/});
	should_fail("32", $type, 0);
	should_fail("3", $type, 0);
	should_fail("9", $type, 0);
	should_fail("5", $type, 0);
	should_fail("2", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\-\\d{2}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\-\d{2}$)/});
	should_fail("115", $type, 0);
	should_fail("-112", $type, 0);
	should_fail("-113", $type, 0);
	should_fail("3", $type, 0);
	should_fail("112", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("63", $type, 0);
	should_fail("-86", $type, 0);
	should_fail("111", $type, 0);
	should_fail("-77", $type, 0);
	should_fail("116", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("-115", $type, 0);
	should_fail("72", $type, 0);
	should_fail("-112", $type, 0);
	should_fail("-95", $type, 0);
	should_fail("-43", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('Byte', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_fail("24", $type, 0);
	should_fail("1", $type, 0);
	should_fail("-25", $type, 0);
	should_fail("9", $type, 0);
	should_fail("-1", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['1','5','-2','-128','-21']});
	should_fail("101", $type, 0);
	should_fail("-53", $type, 0);
	should_fail("39", $type, 0);
	should_fail("-110", $type, 0);
	should_fail("33", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['55','2','-6','38','11','127','28','86']});
	should_fail("-92", $type, 0);
	should_fail("-120", $type, 0);
	should_fail("-122", $type, 0);
	should_fail("-80", $type, 0);
	should_fail("44", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['-128','-3','-13','-68','-36','63','-8','-71','75']});
	should_fail("-18", $type, 0);
	should_fail("127", $type, 0);
	should_fail("79", $type, 0);
	should_fail("-82", $type, 0);
	should_fail("-82", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['-50','-128','127','-6','69','-11','-51','3']});
	should_fail("20", $type, 0);
	should_fail("-24", $type, 0);
	should_fail("10", $type, 0);
	should_fail("27", $type, 0);
	should_fail("28", $type, 0);
	done_testing;
};

subtest "Type atomic/byte is restricted by facet enumeration." => sub {
	my $type = mk_type('Byte', {'enumeration' => ['-2','-85','82','127','17','-3','10']});
	should_fail("-126", $type, 0);
	should_fail("-23", $type, 0);
	should_fail("22", $type, 0);
	should_fail("-102", $type, 0);
	should_fail("-102", $type, 0);
	done_testing;
};

done_testing;

