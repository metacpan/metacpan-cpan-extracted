use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 1970-01." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '1970-01'});
	should_pass("1970-02", $type, 0);
	should_pass("1995-03", $type, 0);
	should_pass("2012-10", $type, 0);
	should_pass("2001-06", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 2030-01." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '2030-01'});
	should_pass("2030-02", $type, 0);
	should_pass("2030-10", $type, 0);
	should_pass("2030-08", $type, 0);
	should_pass("2030-06", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 2029-04." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '2029-04'});
	should_pass("2029-05", $type, 0);
	should_pass("2030-03", $type, 0);
	should_pass("2030-02", $type, 0);
	should_pass("2030-01", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 1970-06." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '1970-06'});
	should_pass("1970-07", $type, 0);
	should_pass("1982-10", $type, 0);
	should_pass("1989-07", $type, 0);
	should_pass("1993-10", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 2030-11." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '2030-11'});
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1970-01." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1970-01'});
	should_pass("1970-01", $type, 0);
	should_pass("2010-04", $type, 0);
	should_pass("2016-04", $type, 0);
	should_pass("2001-05", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 2012-02." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '2012-02'});
	should_pass("2012-02", $type, 0);
	should_pass("2013-02", $type, 0);
	should_pass("2012-04", $type, 0);
	should_pass("2030-11", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1974-11." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1974-11'});
	should_pass("1974-11", $type, 0);
	should_pass("1998-12", $type, 0);
	should_pass("1979-10", $type, 0);
	should_pass("2030-08", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1988-05." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1988-05'});
	should_pass("1988-05", $type, 0);
	should_pass("2017-08", $type, 0);
	should_pass("2018-09", $type, 0);
	should_pass("1993-01", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 2030-12." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '2030-12'});
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1970-02." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1970-02'});
	should_pass("1970-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1983-06." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1983-06'});
	should_pass("1970-01", $type, 0);
	should_pass("1976-09", $type, 0);
	should_pass("1981-04", $type, 0);
	should_pass("1977-01", $type, 0);
	should_pass("1983-05", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1971-05." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1971-05'});
	should_pass("1970-01", $type, 0);
	should_pass("1970-08", $type, 0);
	should_pass("1971-02", $type, 0);
	should_pass("1971-04", $type, 0);
	should_pass("1971-04", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1981-02." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1981-02'});
	should_pass("1970-01", $type, 0);
	should_pass("1978-11", $type, 0);
	should_pass("1970-10", $type, 0);
	should_pass("1978-11", $type, 0);
	should_pass("1981-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 2030-12." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '2030-12'});
	should_pass("1970-01", $type, 0);
	should_pass("1995-06", $type, 0);
	should_pass("1981-08", $type, 0);
	should_pass("2001-12", $type, 0);
	should_pass("2030-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 1970-01." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '1970-01'});
	should_pass("1970-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 2010-06." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '2010-06'});
	should_pass("1970-01", $type, 0);
	should_pass("1994-07", $type, 0);
	should_pass("1971-10", $type, 0);
	should_pass("1985-10", $type, 0);
	should_pass("2010-06", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 1986-01." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '1986-01'});
	should_pass("1970-01", $type, 0);
	should_pass("1972-02", $type, 0);
	should_pass("1976-12", $type, 0);
	should_pass("1975-11", $type, 0);
	should_pass("1986-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 2014-07." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '2014-07'});
	should_pass("1970-01", $type, 0);
	should_pass("2007-06", $type, 0);
	should_pass("1984-02", $type, 0);
	should_pass("1981-10", $type, 0);
	should_pass("2014-07", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 2030-12." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '2030-12'});
	should_pass("1970-01", $type, 0);
	should_pass("1981-09", $type, 0);
	should_pass("1999-10", $type, 0);
	should_pass("2012-01", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value 17\\d\\d-\\d1." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^17\d\d-\d1$)/});
	should_pass("1747-01", $type, 0);
	should_pass("1726-01", $type, 0);
	should_pass("1790-01", $type, 0);
	should_pass("1781-01", $type, 0);
	should_pass("1701-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value \\d\\d31-\\d3." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^\d\d31-\d3$)/});
	should_pass("1831-03", $type, 0);
	should_pass("1831-03", $type, 0);
	should_pass("2031-03", $type, 0);
	should_pass("2031-03", $type, 0);
	should_pass("1831-03", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value \\d\\d76-0\\d." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^\d\d76-0\d$)/});
	should_pass("1876-08", $type, 0);
	should_pass("1876-09", $type, 0);
	should_pass("1876-05", $type, 0);
	should_pass("1976-08", $type, 0);
	should_pass("1876-03", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value 17\\d\\d-0\\d." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^17\d\d-0\d$)/});
	should_pass("1718-04", $type, 0);
	should_pass("1709-06", $type, 0);
	should_pass("1710-08", $type, 0);
	should_pass("1704-07", $type, 0);
	should_pass("1797-03", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value 18\\d\\d-\\d2." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^18\d\d-\d2$)/});
	should_pass("1866-02", $type, 0);
	should_pass("1864-02", $type, 0);
	should_pass("1877-02", $type, 0);
	should_pass("1887-02", $type, 0);
	should_pass("1833-02", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['2017-03','2028-04','1980-03','2014-08','2017-10']});
	should_pass("2017-03", $type, 0);
	should_pass("2028-04", $type, 0);
	should_pass("2028-04", $type, 0);
	should_pass("1980-03", $type, 0);
	should_pass("2014-08", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['2017-08','1986-04','2000-01','2015-06','2010-09','2002-07','2020-10','2012-02']});
	should_pass("2010-09", $type, 0);
	should_pass("1986-04", $type, 0);
	should_pass("2015-06", $type, 0);
	should_pass("2010-09", $type, 0);
	should_pass("2000-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['1978-12','2002-12','2001-09','1972-08','1973-09']});
	should_pass("2001-09", $type, 0);
	should_pass("2001-09", $type, 0);
	should_pass("2001-09", $type, 0);
	should_pass("1978-12", $type, 0);
	should_pass("1972-08", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['1984-02','2007-01','2027-09','1974-01','2006-11','2007-11']});
	should_pass("2027-09", $type, 0);
	should_pass("2027-09", $type, 0);
	should_pass("1974-01", $type, 0);
	should_pass("2007-11", $type, 0);
	should_pass("2027-09", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['2020-08','2027-03','1991-12','1978-06','1992-07','1998-08','2027-02','2013-02']});
	should_pass("1991-12", $type, 0);
	should_pass("2027-03", $type, 0);
	should_pass("1991-12", $type, 0);
	should_pass("1991-12", $type, 0);
	should_pass("1998-08", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('GYearMonth', {'whiteSpace' => 'collapse'});
	should_pass("1970-01", $type, 0);
	should_pass("1985-10", $type, 0);
	should_pass("1988-04", $type, 0);
	should_pass("2013-03", $type, 0);
	should_pass("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1975-10." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1975-10'});
	should_fail("1970-01", $type, 0);
	should_fail("1975-02", $type, 0);
	should_fail("1972-09", $type, 0);
	should_fail("1970-07", $type, 0);
	should_fail("1975-09", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1998-12." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1998-12'});
	should_fail("1970-01", $type, 0);
	should_fail("1990-10", $type, 0);
	should_fail("1998-06", $type, 0);
	should_fail("1985-06", $type, 0);
	should_fail("1998-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1997-07." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1997-07'});
	should_fail("1970-01", $type, 0);
	should_fail("1993-03", $type, 0);
	should_fail("1971-11", $type, 0);
	should_fail("1992-03", $type, 0);
	should_fail("1997-06", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 1973-02." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '1973-02'});
	should_fail("1970-01", $type, 0);
	should_fail("1970-12", $type, 0);
	should_fail("1971-10", $type, 0);
	should_fail("1970-03", $type, 0);
	should_fail("1973-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minInclusive with value 2030-12." => sub {
	my $type = mk_type('GYearMonth', {'minInclusive' => '2030-12'});
	should_fail("1970-01", $type, 0);
	should_fail("2022-02", $type, 0);
	should_fail("2010-09", $type, 0);
	should_fail("2012-08", $type, 0);
	should_fail("2030-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 1970-01." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '1970-01'});
	should_fail("1970-02", $type, 0);
	should_fail("1997-03", $type, 0);
	should_fail("2005-06", $type, 0);
	should_fail("2029-12", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 1977-09." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '1977-09'});
	should_fail("1977-10", $type, 0);
	should_fail("1982-06", $type, 0);
	should_fail("2000-11", $type, 0);
	should_fail("2013-09", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 1983-01." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '1983-01'});
	should_fail("1983-02", $type, 0);
	should_fail("2018-02", $type, 0);
	should_fail("2002-05", $type, 0);
	should_fail("1996-09", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 1971-08." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '1971-08'});
	should_fail("1971-09", $type, 0);
	should_fail("1997-08", $type, 0);
	should_fail("1996-10", $type, 0);
	should_fail("2022-06", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxInclusive with value 2004-01." => sub {
	my $type = mk_type('GYearMonth', {'maxInclusive' => '2004-01'});
	should_fail("2004-02", $type, 0);
	should_fail("2012-02", $type, 0);
	should_fail("2019-09", $type, 0);
	should_fail("2027-06", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 1970-01." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '1970-01'});
	should_fail("1970-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 2009-09." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '2009-09'});
	should_fail("1970-01", $type, 0);
	should_fail("1994-07", $type, 0);
	should_fail("1992-03", $type, 0);
	should_fail("1996-11", $type, 0);
	should_fail("2009-09", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 2018-11." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '2018-11'});
	should_fail("1970-01", $type, 0);
	should_fail("1972-10", $type, 0);
	should_fail("1978-05", $type, 0);
	should_fail("2018-03", $type, 0);
	should_fail("2018-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 1982-07." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '1982-07'});
	should_fail("1970-01", $type, 0);
	should_fail("1979-08", $type, 0);
	should_fail("1976-04", $type, 0);
	should_fail("1975-10", $type, 0);
	should_fail("1982-07", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet minExclusive with value 2030-11." => sub {
	my $type = mk_type('GYearMonth', {'minExclusive' => '2030-11'});
	should_fail("1970-01", $type, 0);
	should_fail("1997-04", $type, 0);
	should_fail("2018-05", $type, 0);
	should_fail("2022-06", $type, 0);
	should_fail("2030-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1970-02." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1970-02'});
	should_fail("1970-02", $type, 0);
	should_fail("2005-03", $type, 0);
	should_fail("2011-06", $type, 0);
	should_fail("2021-05", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 2014-09." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '2014-09'});
	should_fail("2014-09", $type, 0);
	should_fail("2026-08", $type, 0);
	should_fail("2030-08", $type, 0);
	should_fail("2019-06", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1995-01." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1995-01'});
	should_fail("1995-01", $type, 0);
	should_fail("2015-07", $type, 0);
	should_fail("2009-04", $type, 0);
	should_fail("2012-05", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 1979-10." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '1979-10'});
	should_fail("1979-10", $type, 0);
	should_fail("2017-11", $type, 0);
	should_fail("2013-05", $type, 0);
	should_fail("2005-10", $type, 0);
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet maxExclusive with value 2030-12." => sub {
	my $type = mk_type('GYearMonth', {'maxExclusive' => '2030-12'});
	should_fail("2030-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value \\d\\d10-0\\d." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^\d\d10-0\d$)/});
	should_fail("1959-12", $type, 0);
	should_fail("1856-11", $type, 0);
	should_fail("2028-11", $type, 0);
	should_fail("1829-10", $type, 0);
	should_fail("1796-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value 19\\d\\d-0\\d." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^19\d\d-0\d$)/});
	should_fail("1854-11", $type, 0);
	should_fail("1853-10", $type, 0);
	should_fail("1829-10", $type, 0);
	should_fail("1728-10", $type, 0);
	should_fail("1883-12", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value 19\\d\\d-\\d6." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^19\d\d-\d6$)/});
	should_fail("1806-04", $type, 0);
	should_fail("1831-05", $type, 0);
	should_fail("1888-04", $type, 0);
	should_fail("1850-02", $type, 0);
	should_fail("2025-03", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value \\d\\d54-0\\d." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^\d\d54-0\d$)/});
	should_fail("1994-10", $type, 0);
	should_fail("1791-12", $type, 0);
	should_fail("2056-10", $type, 0);
	should_fail("1987-11", $type, 0);
	should_fail("1885-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet pattern with value \\d\\d41-\\d2." => sub {
	my $type = mk_type('GYearMonth', {'pattern' => qr/(?ms:^\d\d41-\d2$)/});
	should_fail("1862-03", $type, 0);
	should_fail("1869-07", $type, 0);
	should_fail("1847-04", $type, 0);
	should_fail("1759-06", $type, 0);
	should_fail("1768-08", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['2021-10','2022-04','1972-07','1993-07','1998-03','2023-02','2015-04','1994-08']});
	should_fail("1981-09", $type, 0);
	should_fail("2022-01", $type, 0);
	should_fail("2008-05", $type, 0);
	should_fail("2013-11", $type, 0);
	should_fail("2003-10", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['1992-01','1977-04','2002-11','2007-11','1987-06','1973-10','1981-03','2009-03','1998-01','2030-06']});
	should_fail("2027-07", $type, 0);
	should_fail("1978-05", $type, 0);
	should_fail("2013-05", $type, 0);
	should_fail("2010-06", $type, 0);
	should_fail("1999-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['1970-11','1998-12','2002-10','1974-08','2009-10','1982-05','2005-02','1984-01','2019-10']});
	should_fail("2008-10", $type, 0);
	should_fail("1983-05", $type, 0);
	should_fail("1974-09", $type, 0);
	should_fail("1982-09", $type, 0);
	should_fail("2026-01", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['1977-11','2013-06','2009-03','1990-01','2027-11']});
	should_fail("2020-08", $type, 0);
	should_fail("2030-08", $type, 0);
	should_fail("2024-04", $type, 0);
	should_fail("2021-01", $type, 0);
	should_fail("1978-11", $type, 0);
	done_testing;
};

subtest "Type atomic/gYearMonth is restricted by facet enumeration." => sub {
	my $type = mk_type('GYearMonth', {'enumeration' => ['2003-07','2020-06','2013-03','1976-03','1995-10','2019-04','1989-04','1991-05']});
	should_fail("2016-02", $type, 0);
	should_fail("1972-04", $type, 0);
	should_fail("1977-07", $type, 0);
	should_fail("2017-06", $type, 0);
	should_fail("1973-09", $type, 0);
	done_testing;
};

done_testing;

