use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/gYear is restricted by facet minExclusive with value 1970." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '1970'});
	should_pass("1971", $type, 0);
	should_pass("1975", $type, 0);
	should_pass("2019", $type, 0);
	should_pass("1979", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 2008." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '2008'});
	should_pass("2009", $type, 0);
	should_pass("2020", $type, 0);
	should_pass("2024", $type, 0);
	should_pass("2026", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 2025." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '2025'});
	should_pass("2026", $type, 0);
	should_pass("2029", $type, 0);
	should_pass("2029", $type, 0);
	should_pass("2029", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 2012." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '2012'});
	should_pass("2013", $type, 0);
	should_pass("2016", $type, 0);
	should_pass("2023", $type, 0);
	should_pass("2017", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 2029." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '2029'});
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 1970." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '1970'});
	should_pass("1970", $type, 0);
	should_pass("2013", $type, 0);
	should_pass("1990", $type, 0);
	should_pass("1992", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 2010." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '2010'});
	should_pass("2010", $type, 0);
	should_pass("2028", $type, 0);
	should_pass("2026", $type, 0);
	should_pass("2011", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 1974." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '1974'});
	should_pass("1974", $type, 0);
	should_pass("2012", $type, 0);
	should_pass("1981", $type, 0);
	should_pass("1998", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 1997." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '1997'});
	should_pass("1997", $type, 0);
	should_pass("2015", $type, 0);
	should_pass("2021", $type, 0);
	should_pass("2028", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 2030." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '2030'});
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 1971." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '1971'});
	should_pass("1970", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2022." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2022'});
	should_pass("1970", $type, 0);
	should_pass("1973", $type, 0);
	should_pass("1983", $type, 0);
	should_pass("1971", $type, 0);
	should_pass("2021", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2003." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2003'});
	should_pass("1970", $type, 0);
	should_pass("1973", $type, 0);
	should_pass("1991", $type, 0);
	should_pass("1996", $type, 0);
	should_pass("2002", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2005." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2005'});
	should_pass("1970", $type, 0);
	should_pass("1984", $type, 0);
	should_pass("1982", $type, 0);
	should_pass("1998", $type, 0);
	should_pass("2004", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2030." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2030'});
	should_pass("1970", $type, 0);
	should_pass("2022", $type, 0);
	should_pass("1971", $type, 0);
	should_pass("2008", $type, 0);
	should_pass("2029", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1970." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1970'});
	should_pass("1970", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1975." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1975'});
	should_pass("1970", $type, 0);
	should_pass("1974", $type, 0);
	should_pass("1971", $type, 0);
	should_pass("1974", $type, 0);
	should_pass("1975", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 2019." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '2019'});
	should_pass("1970", $type, 0);
	should_pass("1975", $type, 0);
	should_pass("1976", $type, 0);
	should_pass("2001", $type, 0);
	should_pass("2019", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1998." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1998'});
	should_pass("1970", $type, 0);
	should_pass("1994", $type, 0);
	should_pass("1992", $type, 0);
	should_pass("1987", $type, 0);
	should_pass("1998", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 2030." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '2030'});
	should_pass("1970", $type, 0);
	should_pass("2028", $type, 0);
	should_pass("2002", $type, 0);
	should_pass("2020", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d47." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d47$)/});
	should_pass("2047", $type, 0);
	should_pass("1847", $type, 0);
	should_pass("2047", $type, 0);
	should_pass("1947", $type, 0);
	should_pass("1947", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d61." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d61$)/});
	should_pass("1961", $type, 0);
	should_pass("1861", $type, 0);
	should_pass("1761", $type, 0);
	should_pass("2061", $type, 0);
	should_pass("1861", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d86." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d86$)/});
	should_pass("2086", $type, 0);
	should_pass("2086", $type, 0);
	should_pass("1886", $type, 0);
	should_pass("1786", $type, 0);
	should_pass("1986", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d14." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d14$)/});
	should_pass("1814", $type, 0);
	should_pass("1814", $type, 0);
	should_pass("1914", $type, 0);
	should_pass("1814", $type, 0);
	should_pass("1914", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d21." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d21$)/});
	should_pass("1921", $type, 0);
	should_pass("1821", $type, 0);
	should_pass("1921", $type, 0);
	should_pass("1921", $type, 0);
	should_pass("1821", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2028','1999','1998','1995','2021','2006','2007','2015']});
	should_pass("2006", $type, 0);
	should_pass("1999", $type, 0);
	should_pass("2028", $type, 0);
	should_pass("2006", $type, 0);
	should_pass("1999", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2007','2020','1999','2011','1976','1984','1972','1992','2018']});
	should_pass("1976", $type, 0);
	should_pass("2018", $type, 0);
	should_pass("1976", $type, 0);
	should_pass("2011", $type, 0);
	should_pass("2020", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2004','2004','2014','1991','2001','2021']});
	should_pass("2004", $type, 0);
	should_pass("2004", $type, 0);
	should_pass("1991", $type, 0);
	should_pass("2014", $type, 0);
	should_pass("2004", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['1978','2027','2007','1970','2021','2016','2014','2015','2023','2002']});
	should_pass("2015", $type, 0);
	should_pass("2007", $type, 0);
	should_pass("2027", $type, 0);
	should_pass("2021", $type, 0);
	should_pass("2027", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2020','1988','1982','2000','1985','1994']});
	should_pass("2000", $type, 0);
	should_pass("2020", $type, 0);
	should_pass("1982", $type, 0);
	should_pass("1982", $type, 0);
	should_pass("1982", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('GYear', {'whiteSpace' => 'collapse'});
	should_pass("1970", $type, 0);
	should_pass("2006", $type, 0);
	should_pass("1981", $type, 0);
	should_pass("1979", $type, 0);
	should_pass("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 2019." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '2019'});
	should_fail("1970", $type, 0);
	should_fail("1991", $type, 0);
	should_fail("1978", $type, 0);
	should_fail("1984", $type, 0);
	should_fail("2018", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 2019." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '2019'});
	should_fail("1970", $type, 0);
	should_fail("1972", $type, 0);
	should_fail("2008", $type, 0);
	should_fail("2009", $type, 0);
	should_fail("2018", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 2017." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '2017'});
	should_fail("1970", $type, 0);
	should_fail("2004", $type, 0);
	should_fail("1999", $type, 0);
	should_fail("1974", $type, 0);
	should_fail("2016", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 1980." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '1980'});
	should_fail("1970", $type, 0);
	should_fail("1976", $type, 0);
	should_fail("1977", $type, 0);
	should_fail("1974", $type, 0);
	should_fail("1979", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minInclusive with value 2030." => sub {
	my $type = mk_type('GYear', {'minInclusive' => '2030'});
	should_fail("1970", $type, 0);
	should_fail("1973", $type, 0);
	should_fail("1976", $type, 0);
	should_fail("2009", $type, 0);
	should_fail("2029", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1970." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1970'});
	should_fail("1971", $type, 0);
	should_fail("1994", $type, 0);
	should_fail("2005", $type, 0);
	should_fail("2025", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1978." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1978'});
	should_fail("1979", $type, 0);
	should_fail("1982", $type, 0);
	should_fail("2022", $type, 0);
	should_fail("2011", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1993." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1993'});
	should_fail("1994", $type, 0);
	should_fail("2000", $type, 0);
	should_fail("2003", $type, 0);
	should_fail("2018", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1985." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1985'});
	should_fail("1986", $type, 0);
	should_fail("1997", $type, 0);
	should_fail("2012", $type, 0);
	should_fail("2017", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxInclusive with value 1982." => sub {
	my $type = mk_type('GYear', {'maxInclusive' => '1982'});
	should_fail("1983", $type, 0);
	should_fail("2021", $type, 0);
	should_fail("1990", $type, 0);
	should_fail("2027", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 1970." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '1970'});
	should_fail("1970", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 2019." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '2019'});
	should_fail("1970", $type, 0);
	should_fail("1999", $type, 0);
	should_fail("1997", $type, 0);
	should_fail("2017", $type, 0);
	should_fail("2019", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 1993." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '1993'});
	should_fail("1970", $type, 0);
	should_fail("1976", $type, 0);
	should_fail("1990", $type, 0);
	should_fail("1987", $type, 0);
	should_fail("1993", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 1988." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '1988'});
	should_fail("1970", $type, 0);
	should_fail("1983", $type, 0);
	should_fail("1987", $type, 0);
	should_fail("1973", $type, 0);
	should_fail("1988", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet minExclusive with value 2029." => sub {
	my $type = mk_type('GYear', {'minExclusive' => '2029'});
	should_fail("1970", $type, 0);
	should_fail("1986", $type, 0);
	should_fail("1994", $type, 0);
	should_fail("2021", $type, 0);
	should_fail("2029", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 1971." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '1971'});
	should_fail("1971", $type, 0);
	should_fail("1983", $type, 0);
	should_fail("2019", $type, 0);
	should_fail("2029", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 1993." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '1993'});
	should_fail("1993", $type, 0);
	should_fail("2025", $type, 0);
	should_fail("2010", $type, 0);
	should_fail("2003", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2014." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2014'});
	should_fail("2014", $type, 0);
	should_fail("2023", $type, 0);
	should_fail("2021", $type, 0);
	should_fail("2027", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2011." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2011'});
	should_fail("2011", $type, 0);
	should_fail("2019", $type, 0);
	should_fail("2016", $type, 0);
	should_fail("2026", $type, 0);
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet maxExclusive with value 2030." => sub {
	my $type = mk_type('GYear', {'maxExclusive' => '2030'});
	should_fail("2030", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d06." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d06$)/});
	should_fail("1835", $type, 0);
	should_fail("1871", $type, 0);
	should_fail("1999", $type, 0);
	should_fail("2095", $type, 0);
	should_fail("1829", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value 19\\d\\d." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^19\d\d$)/});
	should_fail("1802", $type, 0);
	should_fail("2010", $type, 0);
	should_fail("1825", $type, 0);
	should_fail("1711", $type, 0);
	should_fail("2079", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value 17\\d\\d." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^17\d\d$)/});
	should_fail("1959", $type, 0);
	should_fail("1934", $type, 0);
	should_fail("1983", $type, 0);
	should_fail("2022", $type, 0);
	should_fail("1839", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d66." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d66$)/});
	should_fail("2026", $type, 0);
	should_fail("1928", $type, 0);
	should_fail("1873", $type, 0);
	should_fail("1908", $type, 0);
	should_fail("2008", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet pattern with value \\d\\d77." => sub {
	my $type = mk_type('GYear', {'pattern' => qr/(?ms:^\d\d77$)/});
	should_fail("1802", $type, 0);
	should_fail("1864", $type, 0);
	should_fail("1851", $type, 0);
	should_fail("1707", $type, 0);
	should_fail("2015", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['1979','1992','2022','1976','2021','1995']});
	should_fail("1987", $type, 0);
	should_fail("1983", $type, 0);
	should_fail("1975", $type, 0);
	should_fail("2023", $type, 0);
	should_fail("2010", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2014','2026','1976','1979','2001','1992','1974','2011','1977']});
	should_fail("1990", $type, 0);
	should_fail("2027", $type, 0);
	should_fail("1990", $type, 0);
	should_fail("1970", $type, 0);
	should_fail("1970", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['1977','1984','1975','2024','1971','1984','2026']});
	should_fail("1987", $type, 0);
	should_fail("1989", $type, 0);
	should_fail("1987", $type, 0);
	should_fail("1997", $type, 0);
	should_fail("2009", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2018','2015','2028','1975','1996','2019','1998','1995']});
	should_fail("2006", $type, 0);
	should_fail("1987", $type, 0);
	should_fail("1997", $type, 0);
	should_fail("2027", $type, 0);
	should_fail("1994", $type, 0);
	done_testing;
};

subtest "Type atomic/gYear is restricted by facet enumeration." => sub {
	my $type = mk_type('GYear', {'enumeration' => ['2007','2028','1986','1990','2003','2003']});
	should_fail("1993", $type, 0);
	should_fail("1989", $type, 0);
	should_fail("2015", $type, 0);
	should_fail("2026", $type, 0);
	should_fail("1999", $type, 0);
	done_testing;
};

done_testing;

