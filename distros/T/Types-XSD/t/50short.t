use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/short is restricted by facet minExclusive with value -32768." => sub {
	my $type = mk_type('Short', {'minExclusive' => '-32768'});
	should_pass("-32767", $type, 0);
	should_pass("17213", $type, 0);
	should_pass("-28122", $type, 0);
	should_pass("-4838", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value 16190." => sub {
	my $type = mk_type('Short', {'minExclusive' => '16190'});
	should_pass("16191", $type, 0);
	should_pass("28276", $type, 0);
	should_pass("19313", $type, 0);
	should_pass("31624", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value -20001." => sub {
	my $type = mk_type('Short', {'minExclusive' => '-20001'});
	should_pass("-20000", $type, 0);
	should_pass("11131", $type, 0);
	should_pass("8642", $type, 0);
	should_pass("810", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value 6725." => sub {
	my $type = mk_type('Short', {'minExclusive' => '6725'});
	should_pass("6726", $type, 0);
	should_pass("22862", $type, 0);
	should_pass("10221", $type, 0);
	should_pass("16905", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value 32766." => sub {
	my $type = mk_type('Short', {'minExclusive' => '32766'});
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value -32768." => sub {
	my $type = mk_type('Short', {'minInclusive' => '-32768'});
	should_pass("-32768", $type, 0);
	should_pass("-7551", $type, 0);
	should_pass("-17722", $type, 0);
	should_pass("1204", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 11066." => sub {
	my $type = mk_type('Short', {'minInclusive' => '11066'});
	should_pass("11066", $type, 0);
	should_pass("22866", $type, 0);
	should_pass("18900", $type, 0);
	should_pass("14964", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value -26402." => sub {
	my $type = mk_type('Short', {'minInclusive' => '-26402'});
	should_pass("-26402", $type, 0);
	should_pass("-13745", $type, 0);
	should_pass("-25094", $type, 0);
	should_pass("-5991", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 10698." => sub {
	my $type = mk_type('Short', {'minInclusive' => '10698'});
	should_pass("10698", $type, 0);
	should_pass("26195", $type, 0);
	should_pass("23808", $type, 0);
	should_pass("22312", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 32767." => sub {
	my $type = mk_type('Short', {'minInclusive' => '32767'});
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value -32767." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '-32767'});
	should_pass("-32768", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value -8209." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '-8209'});
	should_pass("-32768", $type, 0);
	should_pass("-27515", $type, 0);
	should_pass("-14331", $type, 0);
	should_pass("-31226", $type, 0);
	should_pass("-8210", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value -14442." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '-14442'});
	should_pass("-32768", $type, 0);
	should_pass("-25304", $type, 0);
	should_pass("-25964", $type, 0);
	should_pass("-25615", $type, 0);
	should_pass("-14443", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value 21269." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '21269'});
	should_pass("-32768", $type, 0);
	should_pass("-4982", $type, 0);
	should_pass("20891", $type, 0);
	should_pass("19578", $type, 0);
	should_pass("21268", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value 32767." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '32767'});
	should_pass("-32768", $type, 0);
	should_pass("31953", $type, 0);
	should_pass("-26115", $type, 0);
	should_pass("23045", $type, 0);
	should_pass("32766", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value -32768." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '-32768'});
	should_pass("-32768", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value 2249." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '2249'});
	should_pass("-32768", $type, 0);
	should_pass("-17742", $type, 0);
	should_pass("-14557", $type, 0);
	should_pass("-27127", $type, 0);
	should_pass("2249", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value -25835." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '-25835'});
	should_pass("-32768", $type, 0);
	should_pass("-27611", $type, 0);
	should_pass("-30459", $type, 0);
	should_pass("-29273", $type, 0);
	should_pass("-25835", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value -24465." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '-24465'});
	should_pass("-32768", $type, 0);
	should_pass("-28633", $type, 0);
	should_pass("-25802", $type, 0);
	should_pass("-25248", $type, 0);
	should_pass("-24465", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value 32767." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '32767'});
	should_pass("-32768", $type, 0);
	should_pass("26073", $type, 0);
	should_pass("-6557", $type, 0);
	should_pass("14683", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet fractionDigits with value 0." => sub {
	my $type = mk_type('Short', {'fractionDigits' => '0'});
	should_pass("-32768", $type, 0);
	should_pass("-15359", $type, 0);
	should_pass("-12604", $type, 0);
	should_pass("28392", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Short', {'totalDigits' => '1'});
	should_pass("5", $type, 0);
	should_pass("3", $type, 0);
	should_pass("3", $type, 0);
	should_pass("9", $type, 0);
	should_pass("7", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('Short', {'totalDigits' => '2'});
	should_pass("8", $type, 0);
	should_pass("46", $type, 0);
	should_pass("8", $type, 0);
	should_pass("12", $type, 0);
	should_pass("6", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('Short', {'totalDigits' => '3'});
	should_pass("2", $type, 0);
	should_pass("51", $type, 0);
	should_pass("655", $type, 0);
	should_pass("1", $type, 0);
	should_pass("12", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('Short', {'totalDigits' => '4'});
	should_pass("2", $type, 0);
	should_pass("54", $type, 0);
	should_pass("468", $type, 0);
	should_pass("5547", $type, 0);
	should_pass("7", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 5." => sub {
	my $type = mk_type('Short', {'totalDigits' => '5'});
	should_pass("3", $type, 0);
	should_pass("41", $type, 0);
	should_pass("764", $type, 0);
	should_pass("4635", $type, 0);
	should_pass("16428", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_pass("-31224", $type, 0);
	should_pass("-31431", $type, 0);
	should_pass("-31512", $type, 0);
	should_pass("-31225", $type, 0);
	should_pass("-31443", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\-\\d{3}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\-\d{3}$)/});
	should_pass("-572", $type, 0);
	should_pass("-678", $type, 0);
	should_pass("-295", $type, 0);
	should_pass("-448", $type, 0);
	should_pass("-524", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_pass("-8", $type, 0);
	should_pass("-8", $type, 0);
	should_pass("-8", $type, 0);
	should_pass("-3", $type, 0);
	should_pass("-8", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_pass("86", $type, 0);
	should_pass("67", $type, 0);
	should_pass("56", $type, 0);
	should_pass("48", $type, 0);
	should_pass("62", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_pass("31456", $type, 0);
	should_pass("31345", $type, 0);
	should_pass("31221", $type, 0);
	should_pass("31234", $type, 0);
	should_pass("31624", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['-8076','5805','11013','-5','7589','-84']});
	should_pass("11013", $type, 0);
	should_pass("11013", $type, 0);
	should_pass("-84", $type, 0);
	should_pass("5805", $type, 0);
	should_pass("-8076", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['4','-7086','154','589','3','-32768','78','-888']});
	should_pass("154", $type, 0);
	should_pass("3", $type, 0);
	should_pass("3", $type, 0);
	should_pass("-32768", $type, 0);
	should_pass("78", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['448','-172','-9314','740','-570']});
	should_pass("-570", $type, 0);
	should_pass("-570", $type, 0);
	should_pass("-570", $type, 0);
	should_pass("740", $type, 0);
	should_pass("-9314", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['902','19','4452','41','6','-8727']});
	should_pass("6", $type, 0);
	should_pass("6", $type, 0);
	should_pass("4452", $type, 0);
	should_pass("19", $type, 0);
	should_pass("41", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['-49','370','74','3112','3174','-45','32767']});
	should_pass("74", $type, 0);
	should_pass("32767", $type, 0);
	should_pass("-45", $type, 0);
	should_pass("74", $type, 0);
	should_pass("3112", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Short', {'whiteSpace' => 'collapse'});
	should_pass("-32768", $type, 0);
	should_pass("6618", $type, 0);
	should_pass("-6402", $type, 0);
	should_pass("-19297", $type, 0);
	should_pass("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 19101." => sub {
	my $type = mk_type('Short', {'minInclusive' => '19101'});
	should_fail("-32768", $type, 0);
	should_fail("16520", $type, 0);
	should_fail("12214", $type, 0);
	should_fail("3202", $type, 0);
	should_fail("19100", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value -5120." => sub {
	my $type = mk_type('Short', {'minInclusive' => '-5120'});
	should_fail("-32768", $type, 0);
	should_fail("-22160", $type, 0);
	should_fail("-9704", $type, 0);
	should_fail("-15662", $type, 0);
	should_fail("-5121", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 26269." => sub {
	my $type = mk_type('Short', {'minInclusive' => '26269'});
	should_fail("-32768", $type, 0);
	should_fail("-32296", $type, 0);
	should_fail("-22041", $type, 0);
	should_fail("16409", $type, 0);
	should_fail("26268", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 14671." => sub {
	my $type = mk_type('Short', {'minInclusive' => '14671'});
	should_fail("-32768", $type, 0);
	should_fail("13055", $type, 0);
	should_fail("-1872", $type, 0);
	should_fail("-24417", $type, 0);
	should_fail("14670", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minInclusive with value 32767." => sub {
	my $type = mk_type('Short', {'minInclusive' => '32767'});
	should_fail("-32768", $type, 0);
	should_fail("11466", $type, 0);
	should_fail("15729", $type, 0);
	should_fail("-926", $type, 0);
	should_fail("32766", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value -32768." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '-32768'});
	should_fail("-32767", $type, 0);
	should_fail("-18854", $type, 0);
	should_fail("32591", $type, 0);
	should_fail("2052", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value -6204." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '-6204'});
	should_fail("-6203", $type, 0);
	should_fail("834", $type, 0);
	should_fail("15414", $type, 0);
	should_fail("-5410", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value -24936." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '-24936'});
	should_fail("-24935", $type, 0);
	should_fail("15", $type, 0);
	should_fail("-1864", $type, 0);
	should_fail("-845", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value 24888." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '24888'});
	should_fail("24889", $type, 0);
	should_fail("30103", $type, 0);
	should_fail("26629", $type, 0);
	should_fail("32766", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxInclusive with value 2651." => sub {
	my $type = mk_type('Short', {'maxInclusive' => '2651'});
	should_fail("2652", $type, 0);
	should_fail("11075", $type, 0);
	should_fail("8514", $type, 0);
	should_fail("13224", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 1." => sub {
	my $type = mk_type('Short', {'totalDigits' => '1'});
	should_fail("51", $type, 0);
	should_fail("644", $type, 0);
	should_fail("3267", $type, 0);
	should_fail("15585", $type, 0);
	should_fail("62", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 2." => sub {
	my $type = mk_type('Short', {'totalDigits' => '2'});
	should_fail("424", $type, 0);
	should_fail("7042", $type, 0);
	should_fail("31473", $type, 0);
	should_fail("842", $type, 0);
	should_fail("7593", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 3." => sub {
	my $type = mk_type('Short', {'totalDigits' => '3'});
	should_fail("6133", $type, 0);
	should_fail("21567", $type, 0);
	should_fail("4598", $type, 0);
	should_fail("21557", $type, 0);
	should_fail("1787", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet totalDigits with value 4." => sub {
	my $type = mk_type('Short', {'totalDigits' => '4'});
	should_fail("18587", $type, 0);
	should_fail("28450", $type, 0);
	should_fail("27965", $type, 0);
	should_fail("25147", $type, 0);
	should_fail("31987", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value -32768." => sub {
	my $type = mk_type('Short', {'minExclusive' => '-32768'});
	should_fail("-32768", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value -18150." => sub {
	my $type = mk_type('Short', {'minExclusive' => '-18150'});
	should_fail("-32768", $type, 0);
	should_fail("-22506", $type, 0);
	should_fail("-24820", $type, 0);
	should_fail("-23399", $type, 0);
	should_fail("-18150", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value -30410." => sub {
	my $type = mk_type('Short', {'minExclusive' => '-30410'});
	should_fail("-32768", $type, 0);
	should_fail("-31021", $type, 0);
	should_fail("-31134", $type, 0);
	should_fail("-31509", $type, 0);
	should_fail("-30410", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value 18160." => sub {
	my $type = mk_type('Short', {'minExclusive' => '18160'});
	should_fail("-32768", $type, 0);
	should_fail("-18491", $type, 0);
	should_fail("-8369", $type, 0);
	should_fail("-29369", $type, 0);
	should_fail("18160", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet minExclusive with value 32766." => sub {
	my $type = mk_type('Short', {'minExclusive' => '32766'});
	should_fail("-32768", $type, 0);
	should_fail("-9951", $type, 0);
	should_fail("-3126", $type, 0);
	should_fail("30239", $type, 0);
	should_fail("32766", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value -32767." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '-32767'});
	should_fail("-32767", $type, 0);
	should_fail("11252", $type, 0);
	should_fail("31729", $type, 0);
	should_fail("-21256", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value -32719." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '-32719'});
	should_fail("-32719", $type, 0);
	should_fail("-28629", $type, 0);
	should_fail("-25994", $type, 0);
	should_fail("-13596", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value -31994." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '-31994'});
	should_fail("-31994", $type, 0);
	should_fail("-30590", $type, 0);
	should_fail("28507", $type, 0);
	should_fail("14160", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value 13491." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '13491'});
	should_fail("13491", $type, 0);
	should_fail("19175", $type, 0);
	should_fail("28305", $type, 0);
	should_fail("17791", $type, 0);
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet maxExclusive with value 32767." => sub {
	my $type = mk_type('Short', {'maxExclusive' => '32767'});
	should_fail("32767", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\-\\d{5}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\-\d{5}$)/});
	should_fail("-4", $type, 0);
	should_fail("-52", $type, 0);
	should_fail("637", $type, 0);
	should_fail("-7", $type, 0);
	should_fail("-556", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\-\\d{3}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\-\d{3}$)/});
	should_fail("-94", $type, 0);
	should_fail("99", $type, 0);
	should_fail("-2361", $type, 0);
	should_fail("31222", $type, 0);
	should_fail("-9", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\-\\d{1}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\-\d{1}$)/});
	should_fail("42", $type, 0);
	should_fail("585", $type, 0);
	should_fail("-37", $type, 0);
	should_fail("-37", $type, 0);
	should_fail("156", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\d{2}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\d{2}$)/});
	should_fail("193", $type, 0);
	should_fail("611", $type, 0);
	should_fail("795", $type, 0);
	should_fail("2", $type, 0);
	should_fail("-3574", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet pattern with value \\d{5}." => sub {
	my $type = mk_type('Short', {'pattern' => qr/(?ms:^\d{5}$)/});
	should_fail("-895", $type, 0);
	should_fail("3625", $type, 0);
	should_fail("217", $type, 0);
	should_fail("7582", $type, 0);
	should_fail("49", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['180','9','-53','-541','-701','605','4219','-617','485','2161']});
	should_fail("-25871", $type, 0);
	should_fail("15402", $type, 0);
	should_fail("-22645", $type, 0);
	should_fail("4289", $type, 0);
	should_fail("17544", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['78','402','4258','-285','-982','581','32767','-65','-989']});
	should_fail("-10725", $type, 0);
	should_fail("-29670", $type, 0);
	should_fail("-17752", $type, 0);
	should_fail("10505", $type, 0);
	should_fail("21905", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['533','-52','1','-5309','26','64']});
	should_fail("14800", $type, 0);
	should_fail("-14241", $type, 0);
	should_fail("27690", $type, 0);
	should_fail("27690", $type, 0);
	should_fail("-25304", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['582','6052','10544','-298','-1','24','-60','6601','-32768']});
	should_fail("-19678", $type, 0);
	should_fail("-3079", $type, 0);
	should_fail("8129", $type, 0);
	should_fail("-19678", $type, 0);
	should_fail("-29696", $type, 0);
	done_testing;
};

subtest "Type atomic/short is restricted by facet enumeration." => sub {
	my $type = mk_type('Short', {'enumeration' => ['25','32','-8','9','-960']});
	should_fail("21151", $type, 0);
	should_fail("20850", $type, 0);
	should_fail("19698", $type, 0);
	should_fail("-16635", $type, 0);
	should_fail("-23570", $type, 0);
	done_testing;
};

done_testing;

