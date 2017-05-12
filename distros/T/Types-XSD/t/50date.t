use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/date is restricted by facet minExclusive with value 1970-01-01." => sub {
	my $type = mk_type('Date', {'minExclusive' => '1970-01-01'});
	should_pass("1970-01-02", $type, 0);
	should_pass("2016-05-28", $type, 0);
	should_pass("2020-11-21", $type, 0);
	should_pass("2003-11-08", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2027-03-05." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2027-03-05'});
	should_pass("2027-03-06", $type, 0);
	should_pass("2027-11-29", $type, 0);
	should_pass("2030-05-22", $type, 0);
	should_pass("2029-12-10", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2005-11-17." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2005-11-17'});
	should_pass("2005-11-18", $type, 0);
	should_pass("2014-03-09", $type, 0);
	should_pass("2015-05-23", $type, 0);
	should_pass("2015-07-12", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2025-01-09." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2025-01-09'});
	should_pass("2025-01-10", $type, 0);
	should_pass("2025-02-13", $type, 0);
	should_pass("2029-03-07", $type, 0);
	should_pass("2028-04-05", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2030-12-30." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2030-12-30'});
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 1970-01-01." => sub {
	my $type = mk_type('Date', {'minInclusive' => '1970-01-01'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1992-02-28", $type, 0);
	should_pass("2002-08-18", $type, 0);
	should_pass("2020-03-01", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 1973-09-08." => sub {
	my $type = mk_type('Date', {'minInclusive' => '1973-09-08'});
	should_pass("1973-09-08", $type, 0);
	should_pass("2017-08-17", $type, 0);
	should_pass("1975-08-29", $type, 0);
	should_pass("1995-01-12", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2005-07-30." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2005-07-30'});
	should_pass("2005-07-30", $type, 0);
	should_pass("2022-05-28", $type, 0);
	should_pass("2017-06-11", $type, 0);
	should_pass("2013-12-12", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 1979-03-05." => sub {
	my $type = mk_type('Date', {'minInclusive' => '1979-03-05'});
	should_pass("1979-03-05", $type, 0);
	should_pass("2014-06-05", $type, 0);
	should_pass("2022-09-30", $type, 0);
	should_pass("1994-09-26", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2030-12-31." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2030-12-31'});
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 1970-01-02." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '1970-01-02'});
	should_pass("1970-01-01", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2016-09-05." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2016-09-05'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1987-02-26", $type, 0);
	should_pass("1994-04-13", $type, 0);
	should_pass("1986-10-18", $type, 0);
	should_pass("2016-09-04", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 1990-01-30." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '1990-01-30'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1975-12-28", $type, 0);
	should_pass("1984-11-27", $type, 0);
	should_pass("1978-10-23", $type, 0);
	should_pass("1990-01-29", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2027-10-13." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2027-10-13'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1975-06-19", $type, 0);
	should_pass("2011-10-11", $type, 0);
	should_pass("1977-03-18", $type, 0);
	should_pass("2027-10-12", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2030-12-31." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2030-12-31'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1971-11-24", $type, 0);
	should_pass("2003-11-21", $type, 0);
	should_pass("2013-07-19", $type, 0);
	should_pass("2030-12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 1970-01-01." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '1970-01-01'});
	should_pass("1970-01-01", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 2029-09-09." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '2029-09-09'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1982-06-16", $type, 0);
	should_pass("2005-09-03", $type, 0);
	should_pass("2023-12-26", $type, 0);
	should_pass("2029-09-09", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 2020-12-27." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '2020-12-27'});
	should_pass("1970-01-01", $type, 0);
	should_pass("2016-06-30", $type, 0);
	should_pass("1994-03-09", $type, 0);
	should_pass("2014-12-19", $type, 0);
	should_pass("2020-12-27", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 1971-01-23." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '1971-01-23'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1970-06-21", $type, 0);
	should_pass("1970-11-24", $type, 0);
	should_pass("1970-03-11", $type, 0);
	should_pass("1971-01-23", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 2030-12-31." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '2030-12-31'});
	should_pass("1970-01-01", $type, 0);
	should_pass("2006-09-25", $type, 0);
	should_pass("2022-02-18", $type, 0);
	should_pass("1982-05-02", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d58-0\\d-\\d8." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d58-0\d-\d8$)/});
	should_pass("1858-06-28", $type, 0);
	should_pass("1858-05-08", $type, 0);
	should_pass("1958-02-08", $type, 0);
	should_pass("1958-08-28", $type, 0);
	should_pass("1958-08-18", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d10-\\d4-1\\d." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d10-\d4-1\d$)/});
	should_pass("1910-04-16", $type, 0);
	should_pass("1710-04-16", $type, 0);
	should_pass("1910-04-16", $type, 0);
	should_pass("1810-04-17", $type, 0);
	should_pass("1710-04-17", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d90-\\d7-2\\d." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d90-\d7-2\d$)/});
	should_pass("1890-07-24", $type, 0);
	should_pass("2090-07-21", $type, 0);
	should_pass("1990-07-23", $type, 0);
	should_pass("1990-07-27", $type, 0);
	should_pass("1990-07-22", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value 17\\d\\d-\\d0-1\\d." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^17\d\d-\d0-1\d$)/});
	should_pass("1748-10-16", $type, 0);
	should_pass("1731-10-17", $type, 0);
	should_pass("1734-10-17", $type, 0);
	should_pass("1769-10-12", $type, 0);
	should_pass("1728-10-16", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d44-\\d2-\\d5." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d44-\d2-\d5$)/});
	should_pass("1844-02-15", $type, 0);
	should_pass("1744-02-05", $type, 0);
	should_pass("1944-02-05", $type, 0);
	should_pass("2044-02-15", $type, 0);
	should_pass("1944-02-25", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['1975-06-11','1997-12-26','1998-11-16','2023-08-17','2010-04-24','2028-06-23','2015-03-13','2026-01-04']});
	should_pass("2028-06-23", $type, 0);
	should_pass("2026-01-04", $type, 0);
	should_pass("1998-11-16", $type, 0);
	should_pass("1997-12-26", $type, 0);
	should_pass("2023-08-17", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['2013-10-28','2009-09-16','1974-02-14','2027-04-22','2027-07-03','2001-08-03','2015-12-10']});
	should_pass("2009-09-16", $type, 0);
	should_pass("2009-09-16", $type, 0);
	should_pass("1974-02-14", $type, 0);
	should_pass("2009-09-16", $type, 0);
	should_pass("2027-07-03", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['2005-06-19','1973-10-26','1992-08-14','1973-09-16','1990-04-07','1995-07-16','1985-09-24']});
	should_pass("1973-10-26", $type, 0);
	should_pass("1995-07-16", $type, 0);
	should_pass("1990-04-07", $type, 0);
	should_pass("1992-08-14", $type, 0);
	should_pass("1973-09-16", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['1991-09-06','2022-07-25','2021-10-20','1984-08-15','1975-11-02','2000-02-01']});
	should_pass("1991-09-06", $type, 0);
	should_pass("2021-10-20", $type, 0);
	should_pass("1975-11-02", $type, 0);
	should_pass("1975-11-02", $type, 0);
	should_pass("2022-07-25", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['1972-02-04','2010-06-24','2022-08-04','2006-12-31','1992-01-14','2027-09-16','1980-07-02','2013-06-03']});
	should_pass("2006-12-31", $type, 0);
	should_pass("2027-09-16", $type, 0);
	should_pass("2006-12-31", $type, 0);
	should_pass("2027-09-16", $type, 0);
	should_pass("2010-06-24", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Date', {'whiteSpace' => 'collapse'});
	should_pass("1970-01-01", $type, 0);
	should_pass("1988-10-01", $type, 0);
	should_pass("1980-12-11", $type, 0);
	should_pass("2006-08-12", $type, 0);
	should_pass("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2010-10-14." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2010-10-14'});
	should_fail("1970-01-01", $type, 0);
	should_fail("2005-09-16", $type, 0);
	should_fail("1974-02-08", $type, 0);
	should_fail("1976-04-01", $type, 0);
	should_fail("2010-10-13", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2022-10-26." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2022-10-26'});
	should_fail("1970-01-01", $type, 0);
	should_fail("2001-09-15", $type, 0);
	should_fail("1997-06-24", $type, 0);
	should_fail("2022-01-05", $type, 0);
	should_fail("2022-10-25", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2004-12-05." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2004-12-05'});
	should_fail("1970-01-01", $type, 0);
	should_fail("1995-11-19", $type, 0);
	should_fail("1997-12-03", $type, 0);
	should_fail("1970-05-18", $type, 0);
	should_fail("2004-12-04", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2023-07-31." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2023-07-31'});
	should_fail("1970-01-01", $type, 0);
	should_fail("2004-08-16", $type, 0);
	should_fail("1972-01-13", $type, 0);
	should_fail("1994-08-02", $type, 0);
	should_fail("2023-07-30", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minInclusive with value 2030-12-31." => sub {
	my $type = mk_type('Date', {'minInclusive' => '2030-12-31'});
	should_fail("1970-01-01", $type, 0);
	should_fail("2012-02-22", $type, 0);
	should_fail("1974-04-29", $type, 0);
	should_fail("2023-01-19", $type, 0);
	should_fail("2030-12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 1970-01-01." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '1970-01-01'});
	should_fail("1970-01-02", $type, 0);
	should_fail("2014-06-29", $type, 0);
	should_fail("1994-05-21", $type, 0);
	should_fail("1978-04-13", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 1995-12-15." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '1995-12-15'});
	should_fail("1995-12-16", $type, 0);
	should_fail("1997-04-27", $type, 0);
	should_fail("1998-11-29", $type, 0);
	should_fail("2007-04-14", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 2020-08-23." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '2020-08-23'});
	should_fail("2020-08-24", $type, 0);
	should_fail("2025-02-08", $type, 0);
	should_fail("2026-06-28", $type, 0);
	should_fail("2023-11-28", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 2013-11-30." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '2013-11-30'});
	should_fail("2013-12-01", $type, 0);
	should_fail("2030-12-20", $type, 0);
	should_fail("2017-12-03", $type, 0);
	should_fail("2029-07-17", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxInclusive with value 1985-01-05." => sub {
	my $type = mk_type('Date', {'maxInclusive' => '1985-01-05'});
	should_fail("1985-01-06", $type, 0);
	should_fail("2017-10-04", $type, 0);
	should_fail("1991-08-21", $type, 0);
	should_fail("2019-05-04", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 1970-01-01." => sub {
	my $type = mk_type('Date', {'minExclusive' => '1970-01-01'});
	should_fail("1970-01-01", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2026-12-09." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2026-12-09'});
	should_fail("1970-01-01", $type, 0);
	should_fail("1970-09-30", $type, 0);
	should_fail("2020-02-25", $type, 0);
	should_fail("2015-05-09", $type, 0);
	should_fail("2026-12-09", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2010-09-26." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2010-09-26'});
	should_fail("1970-01-01", $type, 0);
	should_fail("1997-01-26", $type, 0);
	should_fail("1978-01-21", $type, 0);
	should_fail("2004-01-25", $type, 0);
	should_fail("2010-09-26", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2027-08-11." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2027-08-11'});
	should_fail("1970-01-01", $type, 0);
	should_fail("1977-04-20", $type, 0);
	should_fail("1976-10-24", $type, 0);
	should_fail("1985-05-27", $type, 0);
	should_fail("2027-08-11", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet minExclusive with value 2030-12-30." => sub {
	my $type = mk_type('Date', {'minExclusive' => '2030-12-30'});
	should_fail("1970-01-01", $type, 0);
	should_fail("2011-12-16", $type, 0);
	should_fail("2004-05-15", $type, 0);
	should_fail("1983-10-10", $type, 0);
	should_fail("2030-12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 1970-01-02." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '1970-01-02'});
	should_fail("1970-01-02", $type, 0);
	should_fail("2014-07-21", $type, 0);
	should_fail("2023-12-27", $type, 0);
	should_fail("1971-11-15", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2003-05-06." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2003-05-06'});
	should_fail("2003-05-06", $type, 0);
	should_fail("2028-05-02", $type, 0);
	should_fail("2027-11-22", $type, 0);
	should_fail("2004-08-11", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2011-10-16." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2011-10-16'});
	should_fail("2011-10-16", $type, 0);
	should_fail("2027-07-04", $type, 0);
	should_fail("2022-07-19", $type, 0);
	should_fail("2024-08-04", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2012-11-19." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2012-11-19'});
	should_fail("2012-11-19", $type, 0);
	should_fail("2025-08-14", $type, 0);
	should_fail("2013-08-06", $type, 0);
	should_fail("2028-07-19", $type, 0);
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet maxExclusive with value 2030-12-31." => sub {
	my $type = mk_type('Date', {'maxExclusive' => '2030-12-31'});
	should_fail("2030-12-31", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d54-0\\d-\\d8." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d54-0\d-\d8$)/});
	should_fail("1842-11-10", $type, 0);
	should_fail("1944-12-23", $type, 0);
	should_fail("1940-11-25", $type, 0);
	should_fail("1944-12-06", $type, 0);
	should_fail("1936-11-14", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d79-0\\d-\\d5." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d79-0\d-\d5$)/});
	should_fail("1817-10-11", $type, 0);
	should_fail("1994-12-07", $type, 0);
	should_fail("1712-10-24", $type, 0);
	should_fail("1945-11-16", $type, 0);
	should_fail("1949-11-07", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d35-0\\d-\\d7." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d35-0\d-\d7$)/});
	should_fail("1910-10-18", $type, 0);
	should_fail("1939-11-06", $type, 0);
	should_fail("2011-11-22", $type, 0);
	should_fail("1898-10-23", $type, 0);
	should_fail("2066-11-26", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value 19\\d\\d-\\d0-2\\d." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^19\d\d-\d0-2\d$)/});
	should_fail("1868-04-03", $type, 0);
	should_fail("1775-08-02", $type, 0);
	should_fail("1816-07-12", $type, 0);
	should_fail("1871-03-05", $type, 0);
	should_fail("2029-09-17", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet pattern with value \\d\\d32-0\\d-\\d7." => sub {
	my $type = mk_type('Date', {'pattern' => qr/(?ms:^\d\d32-0\d-\d7$)/});
	should_fail("2039-11-14", $type, 0);
	should_fail("1914-11-02", $type, 0);
	should_fail("1992-11-13", $type, 0);
	should_fail("2012-12-20", $type, 0);
	should_fail("1931-11-06", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['1976-06-22','2010-12-07','1970-04-11','2027-10-27','1983-05-21','2027-03-15','1997-05-10','1976-08-08']});
	should_fail("2022-07-14", $type, 0);
	should_fail("1993-01-02", $type, 0);
	should_fail("1983-12-28", $type, 0);
	should_fail("1989-01-15", $type, 0);
	should_fail("1976-03-07", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['2023-02-23','1995-09-28','1995-12-10','2006-07-02','1995-09-08','2021-08-05','1995-01-21','2000-08-30','2003-12-04']});
	should_fail("2003-10-14", $type, 0);
	should_fail("2025-03-18", $type, 0);
	should_fail("1990-12-20", $type, 0);
	should_fail("2003-04-17", $type, 0);
	should_fail("1974-03-26", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['1992-02-13','1972-08-22','1994-03-25','2003-03-09','1987-01-18','1987-03-10','1984-12-12']});
	should_fail("1985-03-29", $type, 0);
	should_fail("2012-08-17", $type, 0);
	should_fail("2019-05-15", $type, 0);
	should_fail("2025-05-20", $type, 0);
	should_fail("1988-02-08", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['1995-02-10','2027-11-23','1999-02-04','2008-04-14','2030-03-15','1993-02-19','2024-09-17']});
	should_fail("1994-06-04", $type, 0);
	should_fail("1994-11-01", $type, 0);
	should_fail("1975-01-06", $type, 0);
	should_fail("1974-04-22", $type, 0);
	should_fail("2019-12-30", $type, 0);
	done_testing;
};

subtest "Type atomic/date is restricted by facet enumeration." => sub {
	my $type = mk_type('Date', {'enumeration' => ['2021-08-02','1979-08-30','1978-11-27','1988-03-05','2019-10-13','1988-10-15','1982-07-19','2021-06-12','2010-08-11']});
	should_fail("2023-06-17", $type, 0);
	should_fail("1999-06-24", $type, 0);
	should_fail("1979-02-19", $type, 0);
	should_fail("2022-06-20", $type, 0);
	should_fail("1984-01-21", $type, 0);
	done_testing;
};

done_testing;

