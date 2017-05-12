use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '0'});
	should_pass("1", $type, 0);
	should_pass("127", $type, 0);
	should_pass("214", $type, 0);
	should_pass("55", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 172." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '172'});
	should_pass("173", $type, 0);
	should_pass("190", $type, 0);
	should_pass("183", $type, 0);
	should_pass("209", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 253." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '253'});
	should_pass("254", $type, 0);
	should_pass("254", $type, 0);
	should_pass("254", $type, 0);
	should_pass("254", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 145." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '145'});
	should_pass("146", $type, 0);
	should_pass("218", $type, 0);
	should_pass("234", $type, 0);
	should_pass("169", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 254." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '254'});
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '0'});
	should_pass("0", $type, 0);
	should_pass("169", $type, 0);
	should_pass("133", $type, 0);
	should_pass("108", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 14." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '14'});
	should_pass("14", $type, 0);
	should_pass("36", $type, 0);
	should_pass("195", $type, 0);
	should_pass("16", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 18." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '18'});
	should_pass("18", $type, 0);
	should_pass("112", $type, 0);
	should_pass("221", $type, 0);
	should_pass("200", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 25." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '25'});
	should_pass("25", $type, 0);
	should_pass("220", $type, 0);
	should_pass("197", $type, 0);
	should_pass("214", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 255." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '255'});
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '1'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 162." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '162'});
	should_pass("0", $type, 0);
	should_pass("139", $type, 0);
	should_pass("112", $type, 0);
	should_pass("155", $type, 0);
	should_pass("161", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 10." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '10'});
	should_pass("0", $type, 0);
	should_pass("2", $type, 0);
	should_pass("4", $type, 0);
	should_pass("8", $type, 0);
	should_pass("9", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 3." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '3'});
	should_pass("0", $type, 0);
	should_pass("0", $type, 0);
	should_pass("0", $type, 0);
	should_pass("1", $type, 0);
	should_pass("2", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 255." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '255'});
	should_pass("0", $type, 0);
	should_pass("105", $type, 0);
	should_pass("26", $type, 0);
	should_pass("135", $type, 0);
	should_pass("254", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '0'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 232." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '232'});
	should_pass("0", $type, 0);
	should_pass("107", $type, 0);
	should_pass("218", $type, 0);
	should_pass("51", $type, 0);
	should_pass("232", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 104." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '104'});
	should_pass("0", $type, 0);
	should_pass("67", $type, 0);
	should_pass("65", $type, 0);
	should_pass("86", $type, 0);
	should_pass("104", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 217." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '217'});
	should_pass("0", $type, 0);
	should_pass("91", $type, 0);
	should_pass("99", $type, 0);
	should_pass("104", $type, 0);
	should_pass("217", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 255." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '255'});
	should_pass("0", $type, 0);
	should_pass("186", $type, 0);
	should_pass("43", $type, 0);
	should_pass("211", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('UnsignedByte', {'fractionDigits' => '0'});
	should_pass("0", $type, 0);
	should_pass("195", $type, 0);
	should_pass("23", $type, 0);
	should_pass("126", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedByte', {'totalDigits' => '1'});
	should_pass("5", $type, 0);
	should_pass("3", $type, 0);
	should_pass("7", $type, 0);
	should_pass("2", $type, 0);
	should_pass("3", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('UnsignedByte', {'totalDigits' => '2'});
	should_pass("4", $type, 0);
	should_pass("67", $type, 0);
	should_pass("1", $type, 0);
	should_pass("10", $type, 0);
	should_pass("3", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('UnsignedByte', {'totalDigits' => '3'});
	should_pass("2", $type, 0);
	should_pass("46", $type, 0);
	should_pass("136", $type, 0);
	should_pass("3", $type, 0);
	should_pass("62", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("6", $type, 0);
	should_pass("5", $type, 0);
	should_pass("6", $type, 0);
	should_pass("8", $type, 0);
	should_pass("5", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_pass("43", $type, 0);
	should_pass("67", $type, 0);
	should_pass("48", $type, 0);
	should_pass("29", $type, 0);
	should_pass("88", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_pass("242", $type, 0);
	should_pass("222", $type, 0);
	should_pass("234", $type, 0);
	should_pass("222", $type, 0);
	should_pass("233", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("8", $type, 0);
	should_pass("4", $type, 0);
	should_pass("3", $type, 0);
	should_pass("4", $type, 0);
	should_pass("5", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_pass("52", $type, 0);
	should_pass("83", $type, 0);
	should_pass("45", $type, 0);
	should_pass("62", $type, 0);
	should_pass("77", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['21','255','57','70','6','45','8','90','85','14']});
	should_pass("70", $type, 0);
	should_pass("85", $type, 0);
	should_pass("8", $type, 0);
	should_pass("255", $type, 0);
	should_pass("21", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['8','40','6','65','49']});
	should_pass("8", $type, 0);
	should_pass("8", $type, 0);
	should_pass("6", $type, 0);
	should_pass("49", $type, 0);
	should_pass("40", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['61','8','7','101','255','111','47','66','91','99']});
	should_pass("91", $type, 0);
	should_pass("66", $type, 0);
	should_pass("99", $type, 0);
	should_pass("101", $type, 0);
	should_pass("111", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['8','43','15','255','83','72','71']});
	should_pass("15", $type, 0);
	should_pass("255", $type, 0);
	should_pass("71", $type, 0);
	should_pass("15", $type, 0);
	should_pass("43", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['1','21','55','9','132','255','17']});
	should_pass("132", $type, 0);
	should_pass("132", $type, 0);
	should_pass("132", $type, 0);
	should_pass("255", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('UnsignedByte', {'whiteSpace' => 'collapse'});
	should_pass("0", $type, 0);
	should_pass("208", $type, 0);
	should_pass("197", $type, 0);
	should_pass("20", $type, 0);
	should_pass("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 70." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '70'});
	should_fail("0", $type, 0);
	should_fail("7", $type, 0);
	should_fail("13", $type, 0);
	should_fail("65", $type, 0);
	should_fail("69", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 202." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '202'});
	should_fail("0", $type, 0);
	should_fail("9", $type, 0);
	should_fail("108", $type, 0);
	should_fail("102", $type, 0);
	should_fail("201", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 252." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '252'});
	should_fail("0", $type, 0);
	should_fail("33", $type, 0);
	should_fail("148", $type, 0);
	should_fail("40", $type, 0);
	should_fail("251", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 171." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '171'});
	should_fail("0", $type, 0);
	should_fail("10", $type, 0);
	should_fail("0", $type, 0);
	should_fail("129", $type, 0);
	should_fail("170", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minInclusive with value 255." => sub {
	my $type = mk_type('UnsignedByte', {'minInclusive' => '255'});
	should_fail("0", $type, 0);
	should_fail("225", $type, 0);
	should_fail("90", $type, 0);
	should_fail("22", $type, 0);
	should_fail("254", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '0'});
	should_fail("1", $type, 0);
	should_fail("20", $type, 0);
	should_fail("133", $type, 0);
	should_fail("169", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 68." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '68'});
	should_fail("69", $type, 0);
	should_fail("156", $type, 0);
	should_fail("224", $type, 0);
	should_fail("173", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 195." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '195'});
	should_fail("196", $type, 0);
	should_fail("218", $type, 0);
	should_fail("216", $type, 0);
	should_fail("233", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 39." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '39'});
	should_fail("40", $type, 0);
	should_fail("246", $type, 0);
	should_fail("148", $type, 0);
	should_fail("251", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxInclusive with value 7." => sub {
	my $type = mk_type('UnsignedByte', {'maxInclusive' => '7'});
	should_fail("8", $type, 0);
	should_fail("74", $type, 0);
	should_fail("85", $type, 0);
	should_fail("118", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedByte', {'totalDigits' => '1'});
	should_fail("55", $type, 0);
	should_fail("230", $type, 0);
	should_fail("12", $type, 0);
	should_fail("212", $type, 0);
	should_fail("62", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('UnsignedByte', {'totalDigits' => '2'});
	should_fail("247", $type, 0);
	should_fail("121", $type, 0);
	should_fail("187", $type, 0);
	should_fail("121", $type, 0);
	should_fail("185", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '0'});
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 35." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '35'});
	should_fail("0", $type, 0);
	should_fail("31", $type, 0);
	should_fail("13", $type, 0);
	should_fail("16", $type, 0);
	should_fail("35", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 137." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '137'});
	should_fail("0", $type, 0);
	should_fail("1", $type, 0);
	should_fail("47", $type, 0);
	should_fail("99", $type, 0);
	should_fail("137", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 251." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '251'});
	should_fail("0", $type, 0);
	should_fail("219", $type, 0);
	should_fail("89", $type, 0);
	should_fail("178", $type, 0);
	should_fail("251", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet minExclusive with value 254." => sub {
	my $type = mk_type('UnsignedByte', {'minExclusive' => '254'});
	should_fail("0", $type, 0);
	should_fail("205", $type, 0);
	should_fail("204", $type, 0);
	should_fail("184", $type, 0);
	should_fail("254", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '1'});
	should_fail("1", $type, 0);
	should_fail("147", $type, 0);
	should_fail("103", $type, 0);
	should_fail("9", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 122." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '122'});
	should_fail("122", $type, 0);
	should_fail("240", $type, 0);
	should_fail("133", $type, 0);
	should_fail("143", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 136." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '136'});
	should_fail("136", $type, 0);
	should_fail("162", $type, 0);
	should_fail("225", $type, 0);
	should_fail("234", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 113." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '113'});
	should_fail("113", $type, 0);
	should_fail("147", $type, 0);
	should_fail("199", $type, 0);
	should_fail("185", $type, 0);
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet maxExclusive with value 255." => sub {
	my $type = mk_type('UnsignedByte', {'maxExclusive' => '255'});
	should_fail("255", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("27", $type, 0);
	should_fail("221", $type, 0);
	should_fail("31", $type, 0);
	should_fail("72", $type, 0);
	should_fail("56", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_fail("7", $type, 0);
	should_fail("8", $type, 0);
	should_fail("232", $type, 0);
	should_fail("8", $type, 0);
	should_fail("223", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_fail("85", $type, 0);
	should_fail("85", $type, 0);
	should_fail("46", $type, 0);
	should_fail("5", $type, 0);
	should_fail("1", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("75", $type, 0);
	should_fail("232", $type, 0);
	should_fail("223", $type, 0);
	should_fail("56", $type, 0);
	should_fail("232", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('UnsignedByte', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_fail("1", $type, 0);
	should_fail("234", $type, 0);
	should_fail("4", $type, 0);
	should_fail("223", $type, 0);
	should_fail("1", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['1','107','54','255','95','12','67','63']});
	should_fail("53", $type, 0);
	should_fail("38", $type, 0);
	should_fail("81", $type, 0);
	should_fail("152", $type, 0);
	should_fail("103", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['78','21','24','73','87','9','55','255','168','84']});
	should_fail("48", $type, 0);
	should_fail("74", $type, 0);
	should_fail("198", $type, 0);
	should_fail("213", $type, 0);
	should_fail("98", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['31','5','7','66','59','44','93']});
	should_fail("77", $type, 0);
	should_fail("58", $type, 0);
	should_fail("147", $type, 0);
	should_fail("231", $type, 0);
	should_fail("193", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['3','66','2','255','9','10','48','7']});
	should_fail("193", $type, 0);
	should_fail("80", $type, 0);
	should_fail("219", $type, 0);
	should_fail("39", $type, 0);
	should_fail("47", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedByte is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedByte', {'enumeration' => ['76','9','28','1','50','72','23']});
	should_fail("63", $type, 0);
	should_fail("182", $type, 0);
	should_fail("45", $type, 0);
	should_fail("40", $type, 0);
	should_fail("107", $type, 0);
	done_testing;
};

done_testing;

