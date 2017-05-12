use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/language is restricted by facet maxLength with value 2." => sub {
	my $type = mk_type('Language', {'maxLength' => '2'});
	should_pass("TH", $type, 0);
	should_pass("HU", $type, 0);
	should_pass("TA", $type, 0);
	should_pass("UR", $type, 0);
	should_pass("FA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 2." => sub {
	my $type = mk_type('Language', {'maxLength' => '2'});
	should_pass("SS", $type, 0);
	should_pass("BE", $type, 0);
	should_pass("QU", $type, 0);
	should_pass("LA", $type, 0);
	should_pass("RW", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 2." => sub {
	my $type = mk_type('Language', {'maxLength' => '2'});
	should_pass("RM", $type, 0);
	should_pass("KM", $type, 0);
	should_pass("EO", $type, 0);
	should_pass("BH", $type, 0);
	should_pass("LV", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 9." => sub {
	my $type = mk_type('Language', {'maxLength' => '9'});
	should_pass("IN", $type, 0);
	should_pass("CS", $type, 0);
	should_pass("SS-a", $type, 0);
	should_pass("BN-UK", $type, 0);
	should_pass("UK-Indian", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 11." => sub {
	my $type = mk_type('Language', {'maxLength' => '11'});
	should_pass("NO", $type, 0);
	should_pass("TL-a", $type, 0);
	should_pass("AA-USA", $type, 0);
	should_pass("DE-CHINA", $type, 0);
	should_pass("GD-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 2." => sub {
	my $type = mk_type('Language', {'minLength' => '2'});
	should_pass("TS", $type, 0);
	should_pass("TA-a", $type, 0);
	should_pass("CO-USA", $type, 0);
	should_pass("PT-CHINA", $type, 0);
	should_pass("YO-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 5." => sub {
	my $type = mk_type('Language', {'minLength' => '5'});
	should_pass("JW-UK", $type, 0);
	should_pass("EU-USA", $type, 0);
	should_pass("BA-LANG", $type, 0);
	should_pass("BN-CHINA", $type, 0);
	should_pass("LT-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 9." => sub {
	my $type = mk_type('Language', {'minLength' => '9'});
	should_pass("BR-Indian", $type, 0);
	should_pass("AF-Ebonics", $type, 0);
	should_pass("PA-Thailand", $type, 0);
	should_pass("OM-Indian", $type, 0);
	should_pass("FI-Ebonics", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 4." => sub {
	my $type = mk_type('Language', {'minLength' => '4'});
	should_pass("BO-a", $type, 0);
	should_pass("JW-UK", $type, 0);
	should_pass("KL-USA", $type, 0);
	should_pass("GU-LANG", $type, 0);
	should_pass("SG-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 11." => sub {
	my $type = mk_type('Language', {'minLength' => '11'});
	should_pass("HU-Thailand", $type, 0);
	should_pass("TG-Thailand", $type, 0);
	should_pass("ML-Thailand", $type, 0);
	should_pass("SO-Thailand", $type, 0);
	should_pass("IK-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 2." => sub {
	my $type = mk_type('Language', {'length' => '2'});
	should_pass("EU", $type, 0);
	should_pass("IS", $type, 0);
	should_pass("SM", $type, 0);
	should_pass("PT", $type, 0);
	should_pass("VI", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 7." => sub {
	my $type = mk_type('Language', {'length' => '7'});
	should_pass("BO-LANG", $type, 0);
	should_pass("SD-LANG", $type, 0);
	should_pass("TI-LANG", $type, 0);
	should_pass("BI-LANG", $type, 0);
	should_pass("PL-LANG", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 10." => sub {
	my $type = mk_type('Language', {'length' => '10'});
	should_pass("HU-Ebonics", $type, 0);
	should_pass("MR-Ebonics", $type, 0);
	should_pass("TT-Ebonics", $type, 0);
	should_pass("TR-Ebonics", $type, 0);
	should_pass("GN-Ebonics", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 5." => sub {
	my $type = mk_type('Language', {'length' => '5'});
	should_pass("FI-UK", $type, 0);
	should_pass("LT-UK", $type, 0);
	should_pass("TN-UK", $type, 0);
	should_pass("HU-UK", $type, 0);
	should_pass("TN-UK", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 11." => sub {
	my $type = mk_type('Language', {'length' => '11'});
	should_pass("ZH-Thailand", $type, 0);
	should_pass("TN-Thailand", $type, 0);
	should_pass("ML-Thailand", $type, 0);
	should_pass("FY-Thailand", $type, 0);
	should_pass("IS-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet pattern with value ([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*." => sub {
	my $type = mk_type('Language', {'pattern' => qr/(?ms:^([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*$)/});
	should_pass("TE-USA", $type, 0);
	should_pass("TG-USA", $type, 0);
	should_pass("TH-USA", $type, 0);
	should_pass("TI-USA", $type, 0);
	should_pass("TK-USA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet pattern with value ([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*." => sub {
	my $type = mk_type('Language', {'pattern' => qr/(?ms:^([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*$)/});
	should_pass("TL-USA", $type, 0);
	should_pass("TN-USA", $type, 0);
	should_pass("TO-USA", $type, 0);
	should_pass("TR-USA", $type, 0);
	should_pass("TS-USA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet pattern with value ([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*." => sub {
	my $type = mk_type('Language', {'pattern' => qr/(?ms:^([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*$)/});
	should_pass("AS-USA", $type, 0);
	should_pass("AY-USA", $type, 0);
	should_pass("AZ-USA", $type, 0);
	should_pass("BA-USA", $type, 0);
	should_pass("BE-USA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet pattern with value ([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*." => sub {
	my $type = mk_type('Language', {'pattern' => qr/(?ms:^([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*$)/});
	should_pass("SL-USA", $type, 0);
	should_pass("SM-USA", $type, 0);
	should_pass("SN-USA", $type, 0);
	should_pass("SO-USA", $type, 0);
	should_pass("SQ-USA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet pattern with value ([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*." => sub {
	my $type = mk_type('Language', {'pattern' => qr/(?ms:^([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{3})*$)/});
	should_pass("WO-USA", $type, 0);
	should_pass("XH-USA", $type, 0);
	should_pass("YO-USA", $type, 0);
	should_pass("ZH-USA", $type, 0);
	should_pass("ZU-USA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet enumeration." => sub {
	my $type = mk_type('Language', {'enumeration' => ['AF','AM','AR','AS','AY','AZ','BA','BE']});
	should_pass("AS", $type, 0);
	should_pass("AR", $type, 0);
	should_pass("AZ", $type, 0);
	should_pass("AS", $type, 0);
	should_pass("AS", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet enumeration." => sub {
	my $type = mk_type('Language', {'enumeration' => ['SL','SM','SN','SO','SQ','SR','SS']});
	should_pass("SL", $type, 0);
	should_pass("SQ", $type, 0);
	should_pass("SS", $type, 0);
	should_pass("SN", $type, 0);
	should_pass("SN", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet enumeration." => sub {
	my $type = mk_type('Language', {'enumeration' => ['AY','AZ','BA','BE','BG','BH','BI','BN','BO']});
	should_pass("BO", $type, 0);
	should_pass("BO", $type, 0);
	should_pass("BE", $type, 0);
	should_pass("BG", $type, 0);
	should_pass("BH", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet enumeration." => sub {
	my $type = mk_type('Language', {'enumeration' => ['BR','CA','CO','CS','CY']});
	should_pass("CA", $type, 0);
	should_pass("CO", $type, 0);
	should_pass("CY", $type, 0);
	should_pass("CS", $type, 0);
	should_pass("CY", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet enumeration." => sub {
	my $type = mk_type('Language', {'enumeration' => ['BH','BI','BN','BO','BR','CA','CO','CS','CY']});
	should_pass("CA", $type, 0);
	should_pass("CA", $type, 0);
	should_pass("CY", $type, 0);
	should_pass("CS", $type, 0);
	should_pass("CY", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Language', {'whiteSpace' => 'collapse'});
	should_pass("FO", $type, 0);
	should_pass("ZH", $type, 0);
	should_pass("EO", $type, 0);
	should_pass("BE", $type, 0);
	should_pass("PL", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 6." => sub {
	my $type = mk_type('Language', {'minLength' => '6'});
	should_fail("SK", $type, 0);
	should_fail("CY-a", $type, 0);
	should_fail("BA-a", $type, 0);
	should_fail("TW-UK", $type, 0);
	should_fail("MY", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 6." => sub {
	my $type = mk_type('Language', {'minLength' => '6'});
	should_fail("FJ", $type, 0);
	should_fail("HR-a", $type, 0);
	should_fail("XH-a", $type, 0);
	should_fail("LT-UK", $type, 0);
	should_fail("MK", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 9." => sub {
	my $type = mk_type('Language', {'minLength' => '9'});
	should_fail("MR", $type, 0);
	should_fail("YO-a", $type, 0);
	should_fail("TE-a", $type, 0);
	should_fail("SG-UK", $type, 0);
	should_fail("TO-CHINA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet minLength with value 11." => sub {
	my $type = mk_type('Language', {'minLength' => '11'});
	should_fail("ZH", $type, 0);
	should_fail("PL-a", $type, 0);
	should_fail("EN-USA", $type, 0);
	should_fail("BE-CHINA", $type, 0);
	should_fail("SD-Ebonics", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 2." => sub {
	my $type = mk_type('Language', {'maxLength' => '2'});
	should_fail("OM-a", $type, 0);
	should_fail("PL-UK", $type, 0);
	should_fail("MO-USA", $type, 0);
	should_fail("NL-LANG", $type, 0);
	should_fail("BE-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 5." => sub {
	my $type = mk_type('Language', {'maxLength' => '5'});
	should_fail("ZH-USA", $type, 0);
	should_fail("KN-LANG", $type, 0);
	should_fail("KL-CHINA", $type, 0);
	should_fail("YO-Indian", $type, 0);
	should_fail("VO-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 9." => sub {
	my $type = mk_type('Language', {'maxLength' => '9'});
	should_fail("SQ-Ebonics", $type, 0);
	should_fail("CA-Thailand", $type, 0);
	should_fail("CS-Ebonics", $type, 0);
	should_fail("TO-Thailand", $type, 0);
	should_fail("ZH-Ebonics", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 7." => sub {
	my $type = mk_type('Language', {'maxLength' => '7'});
	should_fail("ES-CHINA", $type, 0);
	should_fail("FJ-Indian", $type, 0);
	should_fail("ML-Ebonics", $type, 0);
	should_fail("SH-Thailand", $type, 0);
	should_fail("IA-CHINA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet maxLength with value 8." => sub {
	my $type = mk_type('Language', {'maxLength' => '8'});
	should_fail("AF-Indian", $type, 0);
	should_fail("KM-Ebonics", $type, 0);
	should_fail("AA-Thailand", $type, 0);
	should_fail("HR-Indian", $type, 0);
	should_fail("OM-Ebonics", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 2." => sub {
	my $type = mk_type('Language', {'length' => '2'});
	should_fail("SG-a", $type, 0);
	should_fail("HI-UK", $type, 0);
	should_fail("SI-USA", $type, 0);
	should_fail("JA-LANG", $type, 0);
	should_fail("MN-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 6." => sub {
	my $type = mk_type('Language', {'length' => '6'});
	should_fail("AF", $type, 0);
	should_fail("LN-a", $type, 0);
	should_fail("TS-UK", $type, 0);
	should_fail("SR-CHINA", $type, 0);
	should_fail("GA-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 7." => sub {
	my $type = mk_type('Language', {'length' => '7'});
	should_fail("MG", $type, 0);
	should_fail("IT", $type, 0);
	should_fail("BA-a", $type, 0);
	should_fail("SV-UK", $type, 0);
	should_fail("GU-USA", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 5." => sub {
	my $type = mk_type('Language', {'length' => '5'});
	should_fail("KL", $type, 0);
	should_fail("AR-a", $type, 0);
	should_fail("SV-USA", $type, 0);
	should_fail("IE-CHINA", $type, 0);
	should_fail("KY-Thailand", $type, 0);
	done_testing;
};

subtest "Type atomic/language is restricted by facet length with value 11." => sub {
	my $type = mk_type('Language', {'length' => '11'});
	should_fail("ML", $type, 0);
	should_fail("FJ-a", $type, 0);
	should_fail("SL-USA", $type, 0);
	should_fail("AF-CHINA", $type, 0);
	should_fail("AZ-Ebonics", $type, 0);
	done_testing;
};

done_testing;

