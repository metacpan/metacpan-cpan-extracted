use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --01." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--01'});
	should_pass("--02", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--10", $type, 0);
	should_pass("--06", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --09." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--09'});
	should_pass("--10", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--10", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --03." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--03'});
	should_pass("--04", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--08", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --04." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--04'});
	should_pass("--05", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--09", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --11." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--11'});
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --01." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--01'});
	should_pass("--01", $type, 0);
	should_pass("--01", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --05." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--05'});
	should_pass("--05", $type, 0);
	should_pass("--10", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --07." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--07'});
	should_pass("--07", $type, 0);
	should_pass("--08", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --11." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--11'});
	should_pass("--11", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --12." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--12'});
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --02." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--02'});
	should_pass("--01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --02." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--02'});
	should_pass("--01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --11." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--11'});
	should_pass("--01", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--10", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --09." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--09'});
	should_pass("--01", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--08", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --12." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--12'});
	should_pass("--01", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--08", $type, 0);
	should_pass("--08", $type, 0);
	should_pass("--11", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --01." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--01'});
	should_pass("--01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --09." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--09'});
	should_pass("--01", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--09", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --04." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--04'});
	should_pass("--01", $type, 0);
	should_pass("--04", $type, 0);
	should_pass("--03", $type, 0);
	should_pass("--03", $type, 0);
	should_pass("--04", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --03." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--03'});
	should_pass("--01", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--03", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --12." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--12'});
	should_pass("--01", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--08", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --1\\d." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--1\d$)/});
	should_pass("--11", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --\\d2." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--\d2$)/});
	should_pass("--02", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --\\d9." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--\d9$)/});
	should_pass("--09", $type, 0);
	should_pass("--09", $type, 0);
	should_pass("--09", $type, 0);
	should_pass("--09", $type, 0);
	should_pass("--09", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --\\d6." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--\d6$)/});
	should_pass("--06", $type, 0);
	should_pass("--06", $type, 0);
	should_pass("--06", $type, 0);
	should_pass("--06", $type, 0);
	should_pass("--06", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --0\\d." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--0\d$)/});
	should_pass("--05", $type, 0);
	should_pass("--01", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--03", $type, 0);
	should_pass("--08", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--01','--01','--01','--08','--02','--05','--04','--02','--08']});
	should_pass("--02", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--08", $type, 0);
	should_pass("--01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--02','--12','--12','--06','--04','--11']});
	should_pass("--06", $type, 0);
	should_pass("--06", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--02','--12','--03','--04','--11','--02','--11']});
	should_pass("--12", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--12", $type, 0);
	should_pass("--04", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--07','--07','--03','--05','--05','--02','--07','--10','--04']});
	should_pass("--05", $type, 0);
	should_pass("--10", $type, 0);
	should_pass("--07", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--06','--05','--02','--01','--06','--05']});
	should_pass("--05", $type, 0);
	should_pass("--02", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--05", $type, 0);
	should_pass("--02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('GMonth', {'whiteSpace' => 'collapse'});
	should_pass("--01", $type, 0);
	should_pass("--03", $type, 0);
	should_pass("--11", $type, 0);
	should_pass("--09", $type, 0);
	should_pass("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --12." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--12'});
	should_fail("--01", $type, 0);
	should_fail("--06", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--04", $type, 0);
	should_fail("--11", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --10." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--10'});
	should_fail("--01", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--09", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --10." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--10'});
	should_fail("--01", $type, 0);
	should_fail("--03", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--03", $type, 0);
	should_fail("--09", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --04." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--04'});
	should_fail("--01", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--03", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minInclusive with value --12." => sub {
	my $type = mk_type('GMonth', {'minInclusive' => '--12'});
	should_fail("--01", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--11", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --01." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--01'});
	should_fail("--02", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --05." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--05'});
	should_fail("--06", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --05." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--05'});
	should_fail("--06", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--06", $type, 0);
	should_fail("--06", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --03." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--03'});
	should_fail("--04", $type, 0);
	should_fail("--06", $type, 0);
	should_fail("--09", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxInclusive with value --03." => sub {
	my $type = mk_type('GMonth', {'maxInclusive' => '--03'});
	should_fail("--04", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--05", $type, 0);
	should_fail("--05", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --01." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--01'});
	should_fail("--01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --02." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--02'});
	should_fail("--01", $type, 0);
	should_fail("--01", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --01." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--01'});
	should_fail("--01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --04." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--04'});
	should_fail("--01", $type, 0);
	should_fail("--04", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--03", $type, 0);
	should_fail("--04", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet minExclusive with value --11." => sub {
	my $type = mk_type('GMonth', {'minExclusive' => '--11'});
	should_fail("--01", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--06", $type, 0);
	should_fail("--11", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --02." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--02'});
	should_fail("--02", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--12", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --10." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--10'});
	should_fail("--10", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--12", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --06." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--06'});
	should_fail("--06", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--09", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --08." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--08'});
	should_fail("--08", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--09", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet maxExclusive with value --12." => sub {
	my $type = mk_type('GMonth', {'maxExclusive' => '--12'});
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --0\\d." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--0\d$)/});
	should_fail("--10", $type, 0);
	should_fail("--12", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--12", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --\\d1." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--\d1$)/});
	should_fail("--06", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--05", $type, 0);
	should_fail("--04", $type, 0);
	should_fail("--04", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --0\\d." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--0\d$)/});
	should_fail("--11", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --0\\d." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--0\d$)/});
	should_fail("--10", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--10", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--11", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet pattern with value --1\\d." => sub {
	my $type = mk_type('GMonth', {'pattern' => qr/(?ms:^--1\d$)/});
	should_fail("--03", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--08", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--06','--09','--02','--03','--03','--11','--07']});
	should_fail("--08", $type, 0);
	should_fail("--05", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--04", $type, 0);
	should_fail("--05", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--05','--11','--03','--04','--06','--02','--06','--11']});
	should_fail("--01", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--08", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--10','--12','--07','--04','--06','--07']});
	should_fail("--08", $type, 0);
	should_fail("--02", $type, 0);
	should_fail("--03", $type, 0);
	should_fail("--05", $type, 0);
	should_fail("--03", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--04','--10','--04','--07','--11','--07','--07']});
	should_fail("--01", $type, 0);
	should_fail("--12", $type, 0);
	should_fail("--06", $type, 0);
	should_fail("--05", $type, 0);
	should_fail("--03", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonth', {'enumeration' => ['--08','--04','--05','--09','--05','--10','--12','--10']});
	should_fail("--03", $type, 0);
	should_fail("--07", $type, 0);
	should_fail("--03", $type, 0);
	should_fail("--11", $type, 0);
	should_fail("--03", $type, 0);
	done_testing;
};

done_testing;

