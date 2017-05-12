use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --01-01." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--01-01'});
	should_pass("--01-02", $type, 0);
	should_pass("--01-14", $type, 0);
	should_pass("--07-21", $type, 0);
	should_pass("--07-11", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --10-23." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--10-23'});
	should_pass("--10-24", $type, 0);
	should_pass("--11-28", $type, 0);
	should_pass("--12-30", $type, 0);
	should_pass("--12-13", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --06-21." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--06-21'});
	should_pass("--06-22", $type, 0);
	should_pass("--11-30", $type, 0);
	should_pass("--12-22", $type, 0);
	should_pass("--09-27", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --01-01." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--01-01'});
	should_pass("--01-02", $type, 0);
	should_pass("--12-08", $type, 0);
	should_pass("--01-17", $type, 0);
	should_pass("--02-16", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --12-30." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--12-30'});
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --01-01." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--01-01'});
	should_pass("--01-01", $type, 0);
	should_pass("--11-14", $type, 0);
	should_pass("--01-29", $type, 0);
	should_pass("--09-11", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --06-11." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--06-11'});
	should_pass("--06-11", $type, 0);
	should_pass("--11-30", $type, 0);
	should_pass("--12-19", $type, 0);
	should_pass("--10-20", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --07-02." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--07-02'});
	should_pass("--07-02", $type, 0);
	should_pass("--07-19", $type, 0);
	should_pass("--11-16", $type, 0);
	should_pass("--07-22", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --03-04." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--03-04'});
	should_pass("--03-04", $type, 0);
	should_pass("--03-09", $type, 0);
	should_pass("--04-19", $type, 0);
	should_pass("--05-18", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --12-31." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--12-31'});
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --01-02." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--01-02'});
	should_pass("--01-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --10-09." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--10-09'});
	should_pass("--01-01", $type, 0);
	should_pass("--03-19", $type, 0);
	should_pass("--07-24", $type, 0);
	should_pass("--02-01", $type, 0);
	should_pass("--10-08", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --07-23." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--07-23'});
	should_pass("--01-01", $type, 0);
	should_pass("--05-03", $type, 0);
	should_pass("--01-17", $type, 0);
	should_pass("--01-20", $type, 0);
	should_pass("--07-22", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --11-27." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--11-27'});
	should_pass("--01-01", $type, 0);
	should_pass("--07-12", $type, 0);
	should_pass("--03-03", $type, 0);
	should_pass("--08-25", $type, 0);
	should_pass("--11-26", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --12-31." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--12-31'});
	should_pass("--01-01", $type, 0);
	should_pass("--07-29", $type, 0);
	should_pass("--10-26", $type, 0);
	should_pass("--02-01", $type, 0);
	should_pass("--12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --01-01." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--01-01'});
	should_pass("--01-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --02-24." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--02-24'});
	should_pass("--01-01", $type, 0);
	should_pass("--02-11", $type, 0);
	should_pass("--01-22", $type, 0);
	should_pass("--02-01", $type, 0);
	should_pass("--02-24", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --06-11." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--06-11'});
	should_pass("--01-01", $type, 0);
	should_pass("--01-05", $type, 0);
	should_pass("--05-21", $type, 0);
	should_pass("--02-23", $type, 0);
	should_pass("--06-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --07-01." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--07-01'});
	should_pass("--01-01", $type, 0);
	should_pass("--06-24", $type, 0);
	should_pass("--01-03", $type, 0);
	should_pass("--03-15", $type, 0);
	should_pass("--07-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --12-31." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--12-31'});
	should_pass("--01-01", $type, 0);
	should_pass("--11-28", $type, 0);
	should_pass("--07-29", $type, 0);
	should_pass("--05-03", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --\\d2-1\\d." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--\d2-1\d$)/});
	should_pass("--02-13", $type, 0);
	should_pass("--02-13", $type, 0);
	should_pass("--02-17", $type, 0);
	should_pass("--02-17", $type, 0);
	should_pass("--02-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --\\d1-2\\d." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--\d1-2\d$)/});
	should_pass("--01-25", $type, 0);
	should_pass("--01-22", $type, 0);
	should_pass("--01-24", $type, 0);
	should_pass("--01-23", $type, 0);
	should_pass("--01-25", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --0\\d-\\d8." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--0\d-\d8$)/});
	should_pass("--07-08", $type, 0);
	should_pass("--08-18", $type, 0);
	should_pass("--09-28", $type, 0);
	should_pass("--02-18", $type, 0);
	should_pass("--05-18", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --\\d3-0\\d." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--\d3-0\d$)/});
	should_pass("--03-01", $type, 0);
	should_pass("--03-04", $type, 0);
	should_pass("--03-03", $type, 0);
	should_pass("--03-01", $type, 0);
	should_pass("--03-06", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --0\\d-1\\d." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--0\d-1\d$)/});
	should_pass("--05-11", $type, 0);
	should_pass("--05-15", $type, 0);
	should_pass("--07-17", $type, 0);
	should_pass("--03-16", $type, 0);
	should_pass("--05-17", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--08-18','--08-19','--05-19','--11-08','--09-16','--05-29','--11-18','--07-05']});
	should_pass("--11-18", $type, 0);
	should_pass("--11-18", $type, 0);
	should_pass("--08-18", $type, 0);
	should_pass("--11-08", $type, 0);
	should_pass("--08-19", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--09-24','--01-28','--08-31','--08-20','--12-06']});
	should_pass("--12-06", $type, 0);
	should_pass("--08-20", $type, 0);
	should_pass("--08-20", $type, 0);
	should_pass("--08-20", $type, 0);
	should_pass("--01-28", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--12-23','--07-11','--06-24','--10-27','--09-07','--03-29','--12-01','--01-29','--07-09','--10-05']});
	should_pass("--07-09", $type, 0);
	should_pass("--12-01", $type, 0);
	should_pass("--01-29", $type, 0);
	should_pass("--10-27", $type, 0);
	should_pass("--07-09", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--06-07','--11-20','--01-29','--11-11','--11-17','--05-08','--07-06','--12-01','--05-07','--09-03']});
	should_pass("--07-06", $type, 0);
	should_pass("--01-29", $type, 0);
	should_pass("--06-07", $type, 0);
	should_pass("--05-08", $type, 0);
	should_pass("--05-08", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--05-21','--09-18','--03-28','--04-03','--09-13','--08-07','--07-11','--09-03','--02-23']});
	should_pass("--09-13", $type, 0);
	should_pass("--09-03", $type, 0);
	should_pass("--02-23", $type, 0);
	should_pass("--09-13", $type, 0);
	should_pass("--03-28", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('GMonthDay', {'whiteSpace' => 'collapse'});
	should_pass("--01-01", $type, 0);
	should_pass("--04-14", $type, 0);
	should_pass("--02-09", $type, 0);
	should_pass("--08-09", $type, 0);
	should_pass("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --08-23." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--08-23'});
	should_fail("--01-01", $type, 0);
	should_fail("--07-12", $type, 0);
	should_fail("--07-21", $type, 0);
	should_fail("--07-05", $type, 0);
	should_fail("--08-22", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --06-04." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--06-04'});
	should_fail("--01-01", $type, 0);
	should_fail("--03-03", $type, 0);
	should_fail("--01-06", $type, 0);
	should_fail("--04-04", $type, 0);
	should_fail("--06-03", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --07-26." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--07-26'});
	should_fail("--01-01", $type, 0);
	should_fail("--07-14", $type, 0);
	should_fail("--03-23", $type, 0);
	should_fail("--03-26", $type, 0);
	should_fail("--07-25", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --04-03." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--04-03'});
	should_fail("--01-01", $type, 0);
	should_fail("--03-04", $type, 0);
	should_fail("--01-26", $type, 0);
	should_fail("--01-21", $type, 0);
	should_fail("--04-02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minInclusive with value --12-31." => sub {
	my $type = mk_type('GMonthDay', {'minInclusive' => '--12-31'});
	should_fail("--01-01", $type, 0);
	should_fail("--01-13", $type, 0);
	should_fail("--09-28", $type, 0);
	should_fail("--04-05", $type, 0);
	should_fail("--12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --01-01." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--01-01'});
	should_fail("--01-02", $type, 0);
	should_fail("--05-02", $type, 0);
	should_fail("--03-27", $type, 0);
	should_fail("--01-16", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --07-17." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--07-17'});
	should_fail("--07-18", $type, 0);
	should_fail("--09-25", $type, 0);
	should_fail("--10-07", $type, 0);
	should_fail("--08-10", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --08-08." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--08-08'});
	should_fail("--08-09", $type, 0);
	should_fail("--11-18", $type, 0);
	should_fail("--10-10", $type, 0);
	should_fail("--09-03", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --10-12." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--10-12'});
	should_fail("--10-13", $type, 0);
	should_fail("--11-05", $type, 0);
	should_fail("--11-10", $type, 0);
	should_fail("--10-30", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxInclusive with value --10-20." => sub {
	my $type = mk_type('GMonthDay', {'maxInclusive' => '--10-20'});
	should_fail("--10-21", $type, 0);
	should_fail("--12-05", $type, 0);
	should_fail("--11-30", $type, 0);
	should_fail("--12-18", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --01-01." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--01-01'});
	should_fail("--01-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --11-02." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--11-02'});
	should_fail("--01-01", $type, 0);
	should_fail("--08-11", $type, 0);
	should_fail("--04-10", $type, 0);
	should_fail("--03-28", $type, 0);
	should_fail("--11-02", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --07-10." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--07-10'});
	should_fail("--01-01", $type, 0);
	should_fail("--04-19", $type, 0);
	should_fail("--05-01", $type, 0);
	should_fail("--01-27", $type, 0);
	should_fail("--07-10", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --12-26." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--12-26'});
	should_fail("--01-01", $type, 0);
	should_fail("--10-22", $type, 0);
	should_fail("--03-26", $type, 0);
	should_fail("--08-29", $type, 0);
	should_fail("--12-26", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet minExclusive with value --12-30." => sub {
	my $type = mk_type('GMonthDay', {'minExclusive' => '--12-30'});
	should_fail("--01-01", $type, 0);
	should_fail("--03-15", $type, 0);
	should_fail("--03-23", $type, 0);
	should_fail("--08-22", $type, 0);
	should_fail("--12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --01-02." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--01-02'});
	should_fail("--01-02", $type, 0);
	should_fail("--10-23", $type, 0);
	should_fail("--08-12", $type, 0);
	should_fail("--05-31", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --06-29." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--06-29'});
	should_fail("--06-29", $type, 0);
	should_fail("--11-02", $type, 0);
	should_fail("--07-28", $type, 0);
	should_fail("--10-19", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --05-20." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--05-20'});
	should_fail("--05-20", $type, 0);
	should_fail("--07-14", $type, 0);
	should_fail("--08-06", $type, 0);
	should_fail("--09-09", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --01-11." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--01-11'});
	should_fail("--01-11", $type, 0);
	should_fail("--10-24", $type, 0);
	should_fail("--07-10", $type, 0);
	should_fail("--02-05", $type, 0);
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet maxExclusive with value --12-31." => sub {
	my $type = mk_type('GMonthDay', {'maxExclusive' => '--12-31'});
	should_fail("--12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --\\d1-1\\d." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--\d1-1\d$)/});
	should_fail("--04-04", $type, 0);
	should_fail("--06-07", $type, 0);
	should_fail("--08-03", $type, 0);
	should_fail("--05-04", $type, 0);
	should_fail("--08-23", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --\\d6-\\d8." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--\d6-\d8$)/});
	should_fail("--08-21", $type, 0);
	should_fail("--03-06", $type, 0);
	should_fail("--07-12", $type, 0);
	should_fail("--05-15", $type, 0);
	should_fail("--05-24", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --0\\d-\\d0." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--0\d-\d0$)/});
	should_fail("--10-17", $type, 0);
	should_fail("--12-24", $type, 0);
	should_fail("--11-14", $type, 0);
	should_fail("--11-04", $type, 0);
	should_fail("--12-15", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --0\\d-\\d6." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--0\d-\d6$)/});
	should_fail("--10-14", $type, 0);
	should_fail("--10-18", $type, 0);
	should_fail("--11-11", $type, 0);
	should_fail("--11-03", $type, 0);
	should_fail("--11-14", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet pattern with value --\\d5-\\d9." => sub {
	my $type = mk_type('GMonthDay', {'pattern' => qr/(?ms:^--\d5-\d9$)/});
	should_fail("--03-17", $type, 0);
	should_fail("--08-16", $type, 0);
	should_fail("--07-17", $type, 0);
	should_fail("--08-20", $type, 0);
	should_fail("--08-22", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--06-17','--09-05','--12-30','--08-16','--10-22','--03-31','--05-10','--08-07','--10-03']});
	should_fail("--04-12", $type, 0);
	should_fail("--03-26", $type, 0);
	should_fail("--04-29", $type, 0);
	should_fail("--09-09", $type, 0);
	should_fail("--03-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--10-14','--12-08','--01-22','--09-23','--08-09']});
	should_fail("--07-13", $type, 0);
	should_fail("--06-15", $type, 0);
	should_fail("--12-04", $type, 0);
	should_fail("--04-21", $type, 0);
	should_fail("--07-05", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--03-16','--01-30','--11-04','--06-25','--03-08','--09-19','--04-26','--03-27']});
	should_fail("--02-15", $type, 0);
	should_fail("--11-29", $type, 0);
	should_fail("--03-04", $type, 0);
	should_fail("--05-09", $type, 0);
	should_fail("--10-29", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--07-17','--08-11','--06-27','--11-23','--12-01','--02-23']});
	should_fail("--08-07", $type, 0);
	should_fail("--04-06", $type, 0);
	should_fail("--12-27", $type, 0);
	should_fail("--02-27", $type, 0);
	should_fail("--09-18", $type, 0);
	done_testing;
};

subtest "Type atomic/gMonthDay is restricted by facet enumeration." => sub {
	my $type = mk_type('GMonthDay', {'enumeration' => ['--06-11','--04-09','--04-03','--06-02','--04-16']});
	should_fail("--04-24", $type, 0);
	should_fail("--09-22", $type, 0);
	should_fail("--08-13", $type, 0);
	should_fail("--11-16", $type, 0);
	should_fail("--11-06", $type, 0);
	done_testing;
};

done_testing;

