use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '0'});
	should_pass("1", $type, 0);
	should_pass("60599", $type, 0);
	should_pass("29941", $type, 0);
	should_pass("7914", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 40528." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '40528'});
	should_pass("40529", $type, 0);
	should_pass("58050", $type, 0);
	should_pass("58259", $type, 0);
	should_pass("52022", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 42506." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '42506'});
	should_pass("42507", $type, 0);
	should_pass("60318", $type, 0);
	should_pass("49883", $type, 0);
	should_pass("56231", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 909." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '909'});
	should_pass("910", $type, 0);
	should_pass("9903", $type, 0);
	should_pass("55987", $type, 0);
	should_pass("48817", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 65534." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '65534'});
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 0." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '0'});
	should_pass("0", $type, 0);
	should_pass("682", $type, 0);
	should_pass("22318", $type, 0);
	should_pass("12648", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 57532." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '57532'});
	should_pass("57532", $type, 0);
	should_pass("65510", $type, 0);
	should_pass("60479", $type, 0);
	should_pass("64532", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 957." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '957'});
	should_pass("957", $type, 0);
	should_pass("17033", $type, 0);
	should_pass("13341", $type, 0);
	should_pass("54459", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 27948." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '27948'});
	should_pass("27948", $type, 0);
	should_pass("28588", $type, 0);
	should_pass("40398", $type, 0);
	should_pass("40034", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 65535." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '65535'});
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '1'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 8410." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '8410'});
	should_pass("0", $type, 0);
	should_pass("1562", $type, 0);
	should_pass("5726", $type, 0);
	should_pass("608", $type, 0);
	should_pass("8409", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 64347." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '64347'});
	should_pass("0", $type, 0);
	should_pass("16585", $type, 0);
	should_pass("51668", $type, 0);
	should_pass("56497", $type, 0);
	should_pass("64346", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 43532." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '43532'});
	should_pass("0", $type, 0);
	should_pass("36506", $type, 0);
	should_pass("30026", $type, 0);
	should_pass("29076", $type, 0);
	should_pass("43531", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 65535." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '65535'});
	should_pass("0", $type, 0);
	should_pass("47452", $type, 0);
	should_pass("64877", $type, 0);
	should_pass("18765", $type, 0);
	should_pass("65534", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '0'});
	should_pass("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 48200." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '48200'});
	should_pass("0", $type, 0);
	should_pass("42650", $type, 0);
	should_pass("27539", $type, 0);
	should_pass("7601", $type, 0);
	should_pass("48200", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 21008." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '21008'});
	should_pass("0", $type, 0);
	should_pass("3932", $type, 0);
	should_pass("13434", $type, 0);
	should_pass("397", $type, 0);
	should_pass("21008", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 56477." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '56477'});
	should_pass("0", $type, 0);
	should_pass("29538", $type, 0);
	should_pass("1753", $type, 0);
	should_pass("172", $type, 0);
	should_pass("56477", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 65535." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '65535'});
	should_pass("0", $type, 0);
	should_pass("18833", $type, 0);
	should_pass("38602", $type, 0);
	should_pass("391", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('UnsignedShort', {'fractionDigits' => '0'});
	should_pass("0", $type, 0);
	should_pass("6747", $type, 0);
	should_pass("38272", $type, 0);
	should_pass("59261", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '1'});
	should_pass("3", $type, 0);
	should_pass("2", $type, 0);
	should_pass("3", $type, 0);
	should_pass("1", $type, 0);
	should_pass("6", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '2'});
	should_pass("9", $type, 0);
	should_pass("14", $type, 0);
	should_pass("2", $type, 0);
	should_pass("14", $type, 0);
	should_pass("2", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '3'});
	should_pass("5", $type, 0);
	should_pass("48", $type, 0);
	should_pass("138", $type, 0);
	should_pass("8", $type, 0);
	should_pass("93", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '4'});
	should_pass("7", $type, 0);
	should_pass("23", $type, 0);
	should_pass("683", $type, 0);
	should_pass("7638", $type, 0);
	should_pass("5", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '5'});
	should_pass("5", $type, 0);
	should_pass("89", $type, 0);
	should_pass("519", $type, 0);
	should_pass("4769", $type, 0);
	should_pass("36744", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_pass("3", $type, 0);
	should_pass("3", $type, 0);
	should_pass("4", $type, 0);
	should_pass("4", $type, 0);
	should_pass("5", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_pass("13", $type, 0);
	should_pass("79", $type, 0);
	should_pass("21", $type, 0);
	should_pass("33", $type, 0);
	should_pass("38", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_pass("426", $type, 0);
	should_pass("375", $type, 0);
	should_pass("768", $type, 0);
	should_pass("927", $type, 0);
	should_pass("397", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{4}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{4}$)/});
	should_pass("8774", $type, 0);
	should_pass("6476", $type, 0);
	should_pass("7578", $type, 0);
	should_pass("8532", $type, 0);
	should_pass("8142", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("61213", $type, 0);
	should_pass("62223", $type, 0);
	should_pass("62314", $type, 0);
	should_pass("61324", $type, 0);
	should_pass("62324", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['603','121','51760','65535','357','272','570','28']});
	should_pass("272", $type, 0);
	should_pass("65535", $type, 0);
	should_pass("603", $type, 0);
	should_pass("272", $type, 0);
	should_pass("570", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['9294','4614','296','7','30','67']});
	should_pass("30", $type, 0);
	should_pass("30", $type, 0);
	should_pass("7", $type, 0);
	should_pass("9294", $type, 0);
	should_pass("67", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['58929','12','4','2521','3449','1963','6997','609']});
	should_pass("1963", $type, 0);
	should_pass("2521", $type, 0);
	should_pass("12", $type, 0);
	should_pass("58929", $type, 0);
	should_pass("6997", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['3331','794','91','5792','5361','72','1768','37','464']});
	should_pass("72", $type, 0);
	should_pass("5361", $type, 0);
	should_pass("1768", $type, 0);
	should_pass("72", $type, 0);
	should_pass("794", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['3386','700','1','2341','65535','88','3784','870']});
	should_pass("1", $type, 0);
	should_pass("88", $type, 0);
	should_pass("2341", $type, 0);
	should_pass("3784", $type, 0);
	should_pass("870", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('UnsignedShort', {'whiteSpace' => 'collapse'});
	should_pass("0", $type, 0);
	should_pass("8388", $type, 0);
	should_pass("3715", $type, 0);
	should_pass("11321", $type, 0);
	should_pass("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 34783." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '34783'});
	should_fail("0", $type, 0);
	should_fail("11617", $type, 0);
	should_fail("22743", $type, 0);
	should_fail("844", $type, 0);
	should_fail("34782", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 3790." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '3790'});
	should_fail("0", $type, 0);
	should_fail("1600", $type, 0);
	should_fail("483", $type, 0);
	should_fail("459", $type, 0);
	should_fail("3789", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 38462." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '38462'});
	should_fail("0", $type, 0);
	should_fail("32823", $type, 0);
	should_fail("16049", $type, 0);
	should_fail("8155", $type, 0);
	should_fail("38461", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 5951." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '5951'});
	should_fail("0", $type, 0);
	should_fail("3365", $type, 0);
	should_fail("2685", $type, 0);
	should_fail("681", $type, 0);
	should_fail("5950", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minInclusive with value 65535." => sub {
	my $type = mk_type('UnsignedShort', {'minInclusive' => '65535'});
	should_fail("0", $type, 0);
	should_fail("51880", $type, 0);
	should_fail("58412", $type, 0);
	should_fail("11545", $type, 0);
	should_fail("65534", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 0." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '0'});
	should_fail("1", $type, 0);
	should_fail("38371", $type, 0);
	should_fail("18297", $type, 0);
	should_fail("6389", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 48934." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '48934'});
	should_fail("48935", $type, 0);
	should_fail("61089", $type, 0);
	should_fail("63415", $type, 0);
	should_fail("49623", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 2825." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '2825'});
	should_fail("2826", $type, 0);
	should_fail("60219", $type, 0);
	should_fail("3218", $type, 0);
	should_fail("37938", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 65125." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '65125'});
	should_fail("65126", $type, 0);
	should_fail("65317", $type, 0);
	should_fail("65385", $type, 0);
	should_fail("65355", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxInclusive with value 10406." => sub {
	my $type = mk_type('UnsignedShort', {'maxInclusive' => '10406'});
	should_fail("10407", $type, 0);
	should_fail("10624", $type, 0);
	should_fail("63037", $type, 0);
	should_fail("36430", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '1'});
	should_fail("31", $type, 0);
	should_fail("867", $type, 0);
	should_fail("2657", $type, 0);
	should_fail("28578", $type, 0);
	should_fail("72", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '2'});
	should_fail("856", $type, 0);
	should_fail("3781", $type, 0);
	should_fail("17128", $type, 0);
	should_fail("989", $type, 0);
	should_fail("1262", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '3'});
	should_fail("5657", $type, 0);
	should_fail("33010", $type, 0);
	should_fail("9302", $type, 0);
	should_fail("54666", $type, 0);
	should_fail("8783", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('UnsignedShort', {'totalDigits' => '4'});
	should_fail("64754", $type, 0);
	should_fail("43975", $type, 0);
	should_fail("38842", $type, 0);
	should_fail("27812", $type, 0);
	should_fail("48740", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 0." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '0'});
	should_fail("0", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 32874." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '32874'});
	should_fail("0", $type, 0);
	should_fail("8315", $type, 0);
	should_fail("1494", $type, 0);
	should_fail("26771", $type, 0);
	should_fail("32874", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 52307." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '52307'});
	should_fail("0", $type, 0);
	should_fail("17019", $type, 0);
	should_fail("47976", $type, 0);
	should_fail("51235", $type, 0);
	should_fail("52307", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 1078." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '1078'});
	should_fail("0", $type, 0);
	should_fail("658", $type, 0);
	should_fail("159", $type, 0);
	should_fail("548", $type, 0);
	should_fail("1078", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet minExclusive with value 65534." => sub {
	my $type = mk_type('UnsignedShort', {'minExclusive' => '65534'});
	should_fail("0", $type, 0);
	should_fail("20499", $type, 0);
	should_fail("6193", $type, 0);
	should_fail("48976", $type, 0);
	should_fail("65534", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 1." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '1'});
	should_fail("1", $type, 0);
	should_fail("57138", $type, 0);
	should_fail("21058", $type, 0);
	should_fail("60680", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 51084." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '51084'});
	should_fail("51084", $type, 0);
	should_fail("61302", $type, 0);
	should_fail("53499", $type, 0);
	should_fail("56872", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 24084." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '24084'});
	should_fail("24084", $type, 0);
	should_fail("41115", $type, 0);
	should_fail("62818", $type, 0);
	should_fail("61052", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 33466." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '33466'});
	should_fail("33466", $type, 0);
	should_fail("41042", $type, 0);
	should_fail("34745", $type, 0);
	should_fail("49171", $type, 0);
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet maxExclusive with value 65535." => sub {
	my $type = mk_type('UnsignedShort', {'maxExclusive' => '65535'});
	should_fail("65535", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{1}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{1}$)/});
	should_fail("3416", $type, 0);
	should_fail("3949", $type, 0);
	should_fail("336", $type, 0);
	should_fail("3947", $type, 0);
	should_fail("7853", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_fail("64421", $type, 0);
	should_fail("936", $type, 0);
	should_fail("7", $type, 0);
	should_fail("138", $type, 0);
	should_fail("5241", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{3}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{3}$)/});
	should_fail("2", $type, 0);
	should_fail("62124", $type, 0);
	should_fail("7", $type, 0);
	should_fail("3", $type, 0);
	should_fail("4475", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{4}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{4}$)/});
	should_fail("369", $type, 0);
	should_fail("62312", $type, 0);
	should_fail("67", $type, 0);
	should_fail("38", $type, 0);
	should_fail("67", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('UnsignedShort', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("855", $type, 0);
	should_fail("7577", $type, 0);
	should_fail("6589", $type, 0);
	should_fail("23", $type, 0);
	should_fail("946", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['310','49655','2781','23','12','8314']});
	should_fail("50490", $type, 0);
	should_fail("51650", $type, 0);
	should_fail("50490", $type, 0);
	should_fail("30382", $type, 0);
	should_fail("30202", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['265','9','920','7','291','8068','4053','22','955','9249']});
	should_fail("16296", $type, 0);
	should_fail("23916", $type, 0);
	should_fail("47521", $type, 0);
	should_fail("7648", $type, 0);
	should_fail("24149", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['1191','2','8','441','3200','1449']});
	should_fail("43284", $type, 0);
	should_fail("61880", $type, 0);
	should_fail("28982", $type, 0);
	should_fail("58692", $type, 0);
	should_fail("23002", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['7','399','65535','64','36379','56']});
	should_fail("27298", $type, 0);
	should_fail("18770", $type, 0);
	should_fail("11640", $type, 0);
	should_fail("33210", $type, 0);
	should_fail("14191", $type, 0);
	done_testing;
};

subtest "Type atomic/unsignedShort is restricted by facet enumeration." => sub {
	my $type = mk_type('UnsignedShort', {'enumeration' => ['199','534','4255','81','6560','13','3451','388','5311']});
	should_fail("65535", $type, 0);
	should_fail("48492", $type, 0);
	should_fail("53156", $type, 0);
	should_fail("63266", $type, 0);
	should_fail("31363", $type, 0);
	done_testing;
};

done_testing;

