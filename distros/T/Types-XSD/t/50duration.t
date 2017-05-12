use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/duration is restricted by facet minExclusive with value P1970Y01M01DT00H00M00S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P1970Y01M01DT00H00M00S'});
	should_pass("P1970Y01M01DT00H00M01S", $type, 0);
	should_pass("P1997Y11M11DT15H19M36S", $type, 0);
	should_pass("P2024Y03M19DT10H24M27S", $type, 0);
	should_pass("P2001Y12M19DT16H30M37S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P2015Y06M12DT06H42M35S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P2015Y06M12DT06H42M35S'});
	should_pass("P2015Y06M12DT06H42M36S", $type, 0);
	should_pass("P2024Y04M08DT18H43M25S", $type, 0);
	should_pass("P2028Y04M14DT22H36M57S", $type, 0);
	should_pass("P2026Y02M06DT14H13M13S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P2030Y05M22DT14H53M02S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P2030Y05M22DT14H53M02S'});
	should_pass("P2030Y05M22DT14H53M03S", $type, 0);
	should_pass("P2030Y06M21DT17H53M15S", $type, 0);
	should_pass("P2030Y11M13DT15H22M10S", $type, 0);
	should_pass("P2030Y09M30DT06H34M42S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P2029Y10M29DT21H06M18S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P2029Y10M29DT21H06M18S'});
	should_pass("P2029Y10M29DT21H06M19S", $type, 0);
	should_pass("P2030Y03M28DT20H53M50S", $type, 0);
	should_pass("P2030Y05M25DT04H06M40S", $type, 0);
	should_pass("P2030Y11M30DT20H45M46S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P2030Y12M31DT23H59M58S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P2030Y12M31DT23H59M58S'});
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P1970Y01M01DT00H00M00S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P1970Y01M01DT00H00M00S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P2013Y09M12DT12H40M18S", $type, 0);
	should_pass("P2008Y03M14DT18H40M18S", $type, 0);
	should_pass("P2005Y12M19DT06H31M58S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P1978Y12M21DT17H22M44S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P1978Y12M21DT17H22M44S'});
	should_pass("P1978Y12M21DT17H22M44S", $type, 0);
	should_pass("P2013Y06M18DT09H18M34S", $type, 0);
	should_pass("P2010Y05M06DT16H52M15S", $type, 0);
	should_pass("P1990Y01M25DT15H51M01S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P1989Y09M10DT10H34M11S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P1989Y09M10DT10H34M11S'});
	should_pass("P1989Y09M10DT10H34M11S", $type, 0);
	should_pass("P2017Y07M19DT04H37M22S", $type, 0);
	should_pass("P2009Y10M12DT09H40M36S", $type, 0);
	should_pass("P1994Y08M12DT06H51M28S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P2024Y01M12DT09H17M54S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P2024Y01M12DT09H17M54S'});
	should_pass("P2024Y01M12DT09H17M54S", $type, 0);
	should_pass("P2027Y02M19DT00H14M52S", $type, 0);
	should_pass("P2024Y10M23DT20H30M30S", $type, 0);
	should_pass("P2029Y08M03DT08H51M30S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P2030Y12M31DT23H59M59S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P2030Y12M31DT23H59M59S'});
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P1970Y01M01DT00H00M01S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P1970Y01M01DT00H00M01S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P1990Y06M11DT15H00M05S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P1990Y06M11DT15H00M05S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1986Y04M24DT00H21M12S", $type, 0);
	should_pass("P1971Y09M17DT08H19M32S", $type, 0);
	should_pass("P1987Y09M12DT13H23M05S", $type, 0);
	should_pass("P1990Y06M11DT15H00M04S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P2009Y03M30DT15H11M46S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P2009Y03M30DT15H11M46S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1987Y01M13DT23H21M22S", $type, 0);
	should_pass("P1989Y12M31DT02H47M51S", $type, 0);
	should_pass("P1972Y10M22DT15H02M48S", $type, 0);
	should_pass("P2009Y03M30DT15H11M45S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P1983Y12M12DT16H37M58S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P1983Y12M12DT16H37M58S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1983Y05M10DT03H50M24S", $type, 0);
	should_pass("P1970Y08M29DT13H31M28S", $type, 0);
	should_pass("P1971Y05M25DT10H29M29S", $type, 0);
	should_pass("P1983Y12M12DT16H37M57S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P2030Y12M31DT23H59M59S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P2030Y12M31DT23H59M59S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1993Y07M20DT18H29M29S", $type, 0);
	should_pass("P2010Y06M27DT18H05M25S", $type, 0);
	should_pass("P2023Y01M15DT16H37M06S", $type, 0);
	should_pass("P2030Y12M31DT23H59M58S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1970Y01M01DT00H00M00S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1970Y01M01DT00H00M00S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1970Y02M12DT08H03M16S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1970Y02M12DT08H03M16S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1970Y01M15DT15H39M46S", $type, 0);
	should_pass("P1970Y01M16DT05H01M14S", $type, 0);
	should_pass("P1970Y01M24DT03H56M38S", $type, 0);
	should_pass("P1970Y02M12DT08H03M16S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1981Y03M20DT22H33M14S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1981Y03M20DT22H33M14S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1973Y06M18DT22H11M53S", $type, 0);
	should_pass("P1971Y11M27DT21H59M21S", $type, 0);
	should_pass("P1981Y01M03DT00H54M52S", $type, 0);
	should_pass("P1981Y03M20DT22H33M14S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1989Y04M21DT11H28M41S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1989Y04M21DT11H28M41S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1981Y05M04DT21H26M39S", $type, 0);
	should_pass("P1978Y02M28DT22H43M07S", $type, 0);
	should_pass("P1981Y10M20DT02H31M54S", $type, 0);
	should_pass("P1989Y04M21DT11H28M41S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P2030Y12M31DT23H59M59S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P2030Y12M31DT23H59M59S'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P1988Y02M02DT22H28M22S", $type, 0);
	should_pass("P2023Y12M03DT05H48M36S", $type, 0);
	should_pass("P1975Y09M04DT03H30M21S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P\\d\\d76Y\\d4M2\\dDT1\\dH\\d9M\\d9S." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P\d\d76Y\d4M2\dDT1\dH\d9M\d9S$)/});
	should_pass("P1876Y04M23DT16H39M39S", $type, 0);
	should_pass("P1876Y04M22DT17H19M19S", $type, 0);
	should_pass("P1876Y04M24DT12H49M19S", $type, 0);
	should_pass("P1776Y04M25DT16H09M19S", $type, 0);
	should_pass("P1876Y04M23DT15H49M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P\\d\\d74Y0\\dM\\d6DT1\\dH\\d0M\\d7S." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P\d\d74Y0\dM\d6DT1\dH\d0M\d7S$)/});
	should_pass("P1974Y05M26DT18H00M27S", $type, 0);
	should_pass("P2074Y09M06DT18H20M17S", $type, 0);
	should_pass("P1974Y03M26DT14H10M17S", $type, 0);
	should_pass("P1874Y04M26DT13H00M37S", $type, 0);
	should_pass("P1774Y04M26DT15H10M37S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P20\\d\\dY\\d3M\\d1DT\\d4H\\d7M\\d6S." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P20\d\dY\d3M\d1DT\d4H\d7M\d6S$)/});
	should_pass("P2043Y03M11DT04H17M16S", $type, 0);
	should_pass("P2017Y03M21DT04H37M36S", $type, 0);
	should_pass("P2034Y03M01DT14H57M06S", $type, 0);
	should_pass("P2051Y03M11DT14H37M56S", $type, 0);
	should_pass("P2077Y03M01DT04H07M46S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P19\\d\\dY\\d8M\\d3DT\\d0H1\\dM\\d2S." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P19\d\dY\d8M\d3DT\d0H1\dM\d2S$)/});
	should_pass("P1941Y08M13DT00H15M02S", $type, 0);
	should_pass("P1912Y08M23DT10H14M32S", $type, 0);
	should_pass("P1944Y08M13DT00H14M32S", $type, 0);
	should_pass("P1938Y08M23DT10H13M02S", $type, 0);
	should_pass("P1948Y08M23DT10H14M52S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P\\d\\d63Y\\d4M1\\dDT0\\dH\\d4M4\\dS." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P\d\d63Y\d4M1\dDT0\dH\d4M4\dS$)/});
	should_pass("P1863Y04M14DT04H14M46S", $type, 0);
	should_pass("P1863Y04M15DT06H44M47S", $type, 0);
	should_pass("P2063Y04M17DT07H34M43S", $type, 0);
	should_pass("P1863Y04M18DT00H24M40S", $type, 0);
	should_pass("P1963Y04M13DT04H34M45S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2025Y01M14DT13H56M25S','P1983Y03M24DT09H12M25S','P1984Y01M10DT20H37M24S','P1997Y09M21DT02H26M51S','P1988Y07M27DT12H21M55S','P2000Y08M25DT00H50M37S','P1981Y11M06DT01H43M46S','P1982Y04M25DT04H30M00S','P2011Y03M13DT10H22M00S']});
	should_pass("P2000Y08M25DT00H50M37S", $type, 0);
	should_pass("P1997Y09M21DT02H26M51S", $type, 0);
	should_pass("P1988Y07M27DT12H21M55S", $type, 0);
	should_pass("P2000Y08M25DT00H50M37S", $type, 0);
	should_pass("P1983Y03M24DT09H12M25S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2030Y06M26DT21H55M47S','P1979Y03M06DT16H39M48S','P1987Y06M06DT18H56M03S','P1977Y04M02DT05H48M43S','P1995Y02M01DT05H15M19S','P2019Y06M07DT15H23M38S','P1976Y12M13DT09H35M31S','P1989Y03M16DT04H44M26S','P1993Y12M14DT04H03M02S']});
	should_pass("P1995Y02M01DT05H15M19S", $type, 0);
	should_pass("P1989Y03M16DT04H44M26S", $type, 0);
	should_pass("P2019Y06M07DT15H23M38S", $type, 0);
	should_pass("P1979Y03M06DT16H39M48S", $type, 0);
	should_pass("P1995Y02M01DT05H15M19S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2014Y02M13DT07H57M16S','P1971Y01M25DT00H00M13S','P1992Y03M13DT23H32M32S','P1999Y01M17DT20H04M34S','P1974Y07M30DT07H58M46S','P1979Y12M12DT13H36M50S','P2018Y05M02DT20H30M41S','P2005Y11M15DT09H43M12S','P1995Y06M08DT02H47M24S','P1973Y07M23DT17H25M15S']});
	should_pass("P1974Y07M30DT07H58M46S", $type, 0);
	should_pass("P1979Y12M12DT13H36M50S", $type, 0);
	should_pass("P1971Y01M25DT00H00M13S", $type, 0);
	should_pass("P2005Y11M15DT09H43M12S", $type, 0);
	should_pass("P1974Y07M30DT07H58M46S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2025Y05M27DT08H26M21S','P1992Y12M03DT11H54M34S','P2006Y06M20DT01H05M49S','P2007Y02M04DT05H26M40S','P1978Y02M20DT15H18M23S','P2017Y06M28DT06H31M49S','P2025Y04M14DT05H33M34S']});
	should_pass("P2006Y06M20DT01H05M49S", $type, 0);
	should_pass("P1978Y02M20DT15H18M23S", $type, 0);
	should_pass("P2006Y06M20DT01H05M49S", $type, 0);
	should_pass("P1992Y12M03DT11H54M34S", $type, 0);
	should_pass("P2025Y05M27DT08H26M21S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2004Y09M11DT17H07M38S','P2002Y03M13DT22H40M25S','P1995Y02M03DT12H24M43S','P2002Y11M07DT03H22M59S','P1970Y01M27DT04H00M33S','P1974Y01M22DT17H35M48S','P2012Y01M30DT22H51M53S','P2024Y05M28DT11H34M44S','P1987Y03M14DT08H37M46S']});
	should_pass("P2012Y01M30DT22H51M53S", $type, 0);
	should_pass("P1970Y01M27DT04H00M33S", $type, 0);
	should_pass("P2002Y03M13DT22H40M25S", $type, 0);
	should_pass("P1974Y01M22DT17H35M48S", $type, 0);
	should_pass("P2002Y11M07DT03H22M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Duration', {'whiteSpace' => 'collapse'});
	should_pass("P1970Y01M01DT00H00M00S", $type, 0);
	should_pass("P2015Y12M04DT03H50M05S", $type, 0);
	should_pass("P1989Y07M13DT09H21M19S", $type, 0);
	should_pass("P1980Y06M18DT05H57M31S", $type, 0);
	should_pass("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P1979Y05M22DT21H16M00S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P1979Y05M22DT21H16M00S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1970Y05M21DT18H22M32S", $type, 0);
	should_fail("P1970Y01M10DT04H04M51S", $type, 0);
	should_fail("P1973Y12M29DT05H47M26S", $type, 0);
	should_fail("P1979Y05M22DT21H15M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P2020Y07M24DT16H45M10S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P2020Y07M24DT16H45M10S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P2017Y05M05DT20H46M17S", $type, 0);
	should_fail("P1980Y09M22DT08H38M19S", $type, 0);
	should_fail("P2013Y09M05DT12H59M59S", $type, 0);
	should_fail("P2020Y07M24DT16H45M09S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P2020Y02M05DT23H43M19S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P2020Y02M05DT23H43M19S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1979Y12M11DT04H01M22S", $type, 0);
	should_fail("P1990Y09M27DT06H02M01S", $type, 0);
	should_fail("P1974Y09M01DT00H50M09S", $type, 0);
	should_fail("P2020Y02M05DT23H43M18S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P1985Y11M17DT03H28M39S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P1985Y11M17DT03H28M39S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1981Y08M20DT09H15M08S", $type, 0);
	should_fail("P1980Y11M22DT05H56M45S", $type, 0);
	should_fail("P1974Y10M08DT03H51M35S", $type, 0);
	should_fail("P1985Y11M17DT03H28M38S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minInclusive with value P2030Y12M31DT23H59M59S." => sub {
	my $type = mk_type('Duration', {'minInclusive' => 'P2030Y12M31DT23H59M59S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1992Y03M21DT22H31M44S", $type, 0);
	should_fail("P1982Y08M30DT10H29M11S", $type, 0);
	should_fail("P2005Y07M18DT17H02M03S", $type, 0);
	should_fail("P2030Y12M31DT23H59M58S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1970Y01M01DT00H00M00S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1970Y01M01DT00H00M00S'});
	should_fail("P1970Y01M01DT00H00M01S", $type, 0);
	should_fail("P1978Y09M23DT07H58M54S", $type, 0);
	should_fail("P2003Y11M12DT12H24M27S", $type, 0);
	should_fail("P1972Y12M20DT09H48M15S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P2017Y11M05DT07H47M53S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P2017Y11M05DT07H47M53S'});
	should_fail("P2017Y11M05DT07H47M54S", $type, 0);
	should_fail("P2030Y09M02DT19H53M28S", $type, 0);
	should_fail("P2025Y02M07DT17H07M02S", $type, 0);
	should_fail("P2026Y07M26DT14H18M19S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1983Y03M31DT13H03M25S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1983Y03M31DT13H03M25S'});
	should_fail("P1983Y03M31DT13H03M26S", $type, 0);
	should_fail("P2005Y01M28DT09H21M40S", $type, 0);
	should_fail("P2020Y08M15DT04H17M25S", $type, 0);
	should_fail("P1987Y04M17DT07H51M04S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P2004Y12M06DT10H36M29S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P2004Y12M06DT10H36M29S'});
	should_fail("P2004Y12M06DT10H36M30S", $type, 0);
	should_fail("P2015Y04M26DT18H05M14S", $type, 0);
	should_fail("P2026Y12M23DT19H22M29S", $type, 0);
	should_fail("P2028Y05M31DT09H15M47S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxInclusive with value P1989Y02M14DT22H12M09S." => sub {
	my $type = mk_type('Duration', {'maxInclusive' => 'P1989Y02M14DT22H12M09S'});
	should_fail("P1989Y02M14DT22H12M10S", $type, 0);
	should_fail("P1992Y11M01DT16H40M21S", $type, 0);
	should_fail("P1995Y03M22DT22H27M03S", $type, 0);
	should_fail("P2010Y01M27DT10H05M12S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P1970Y01M01DT00H00M00S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P1970Y01M01DT00H00M00S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P1974Y08M01DT01H59M52S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P1974Y08M01DT01H59M52S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1974Y03M13DT17H19M07S", $type, 0);
	should_fail("P1972Y08M14DT16H42M47S", $type, 0);
	should_fail("P1973Y03M29DT16H56M06S", $type, 0);
	should_fail("P1974Y08M01DT01H59M52S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P2030Y07M10DT08H51M22S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P2030Y07M10DT08H51M22S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1978Y12M17DT22H17M47S", $type, 0);
	should_fail("P2029Y12M09DT07H42M51S", $type, 0);
	should_fail("P2011Y05M04DT23H43M21S", $type, 0);
	should_fail("P2030Y07M10DT08H51M22S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P1993Y07M06DT16H26M06S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P1993Y07M06DT16H26M06S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P1975Y06M13DT19H10M35S", $type, 0);
	should_fail("P1982Y08M03DT00H49M53S", $type, 0);
	should_fail("P1974Y07M21DT16H02M33S", $type, 0);
	should_fail("P1993Y07M06DT16H26M06S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet minExclusive with value P2030Y12M31DT23H59M58S." => sub {
	my $type = mk_type('Duration', {'minExclusive' => 'P2030Y12M31DT23H59M58S'});
	should_fail("P1970Y01M01DT00H00M00S", $type, 0);
	should_fail("P2014Y02M19DT10H43M12S", $type, 0);
	should_fail("P1981Y11M21DT18H38M44S", $type, 0);
	should_fail("P2019Y07M05DT21H46M10S", $type, 0);
	should_fail("P2030Y12M31DT23H59M58S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P1970Y01M01DT00H00M01S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P1970Y01M01DT00H00M01S'});
	should_fail("P1970Y01M01DT00H00M01S", $type, 0);
	should_fail("P1989Y04M23DT23H47M39S", $type, 0);
	should_fail("P1983Y06M26DT22H09M28S", $type, 0);
	should_fail("P2014Y05M30DT00H06M01S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P1983Y08M22DT12H17M52S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P1983Y08M22DT12H17M52S'});
	should_fail("P1983Y08M22DT12H17M52S", $type, 0);
	should_fail("P2004Y11M19DT00H59M44S", $type, 0);
	should_fail("P2027Y12M23DT16H11M34S", $type, 0);
	should_fail("P2025Y09M06DT09H26M22S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P2024Y06M08DT17H23M35S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P2024Y06M08DT17H23M35S'});
	should_fail("P2024Y06M08DT17H23M35S", $type, 0);
	should_fail("P2029Y11M22DT00H36M33S", $type, 0);
	should_fail("P2030Y12M03DT10H22M41S", $type, 0);
	should_fail("P2029Y08M06DT14H36M28S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P1974Y04M13DT23H56M57S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P1974Y04M13DT23H56M57S'});
	should_fail("P1974Y04M13DT23H56M57S", $type, 0);
	should_fail("P2003Y03M21DT07H39M44S", $type, 0);
	should_fail("P1980Y04M18DT22H14M48S", $type, 0);
	should_fail("P2013Y08M14DT10H05M35S", $type, 0);
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet maxExclusive with value P2030Y12M31DT23H59M59S." => sub {
	my $type = mk_type('Duration', {'maxExclusive' => 'P2030Y12M31DT23H59M59S'});
	should_fail("P2030Y12M31DT23H59M59S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P\\d\\d69Y\\d2M1\\dDT\\d0H\\d9M5\\dS." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P\d\d69Y\d2M1\dDT\d0H\d9M5\dS$)/});
	should_fail("P1986Y06M24DT05H04M09S", $type, 0);
	should_fail("P1808Y03M05DT19H21M14S", $type, 0);
	should_fail("P2038Y06M26DT05H46M26S", $type, 0);
	should_fail("P1995Y05M02DT02H32M32S", $type, 0);
	should_fail("P1871Y04M03DT14H27M43S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P19\\d\\dY0\\dM2\\dDT\\d1H\\d9M\\d9S." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P19\d\dY0\dM2\dDT\d1H\d9M\d9S$)/});
	should_fail("P1813Y12M05DT03H21M34S", $type, 0);
	should_fail("P2007Y12M12DT06H56M25S", $type, 0);
	should_fail("P2092Y11M14DT19H47M40S", $type, 0);
	should_fail("P1763Y12M15DT18H26M48S", $type, 0);
	should_fail("P2021Y10M10DT07H26M26S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P\\d\\d24Y0\\dM1\\dDT1\\dH\\d0M5\\dS." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P\d\d24Y0\dM1\dDT1\dH\d0M5\dS$)/});
	should_fail("P2080Y11M20DT28H23M07S", $type, 0);
	should_fail("P1963Y10M27DT05H33M27S", $type, 0);
	should_fail("P1860Y11M01DT29H07M09S", $type, 0);
	should_fail("P1734Y10M27DT26H39M38S", $type, 0);
	should_fail("P1895Y11M04DT03H43M10S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P\\d\\d80Y\\d8M1\\dDT1\\dH3\\dM2\\dS." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P\d\d80Y\d8M1\dDT1\dH3\dM2\dS$)/});
	should_fail("P2035Y04M26DT42H16M44S", $type, 0);
	should_fail("P1953Y03M25DT56H22M31S", $type, 0);
	should_fail("P1882Y02M01DT43H46M14S", $type, 0);
	should_fail("P1816Y02M03DT41H50M58S", $type, 0);
	should_fail("P1847Y04M23DT38H01M44S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet pattern with value P17\\d\\dY\\d7M\\d3DT0\\dH0\\dM\\d5S." => sub {
	my $type = mk_type('Duration', {'pattern' => qr/(?ms:^P17\d\dY\d7M\d3DT0\dH0\dM\d5S$)/});
	should_fail("P1865Y03M10DT42H54M38S", $type, 0);
	should_fail("P2018Y05M22DT17H44M47S", $type, 0);
	should_fail("P1905Y01M08DT26H15M16S", $type, 0);
	should_fail("P1843Y02M12DT29H32M46S", $type, 0);
	should_fail("P1903Y08M21DT22H44M37S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2015Y08M23DT18H23M40S','P2001Y05M07DT11H55M34S','P1997Y08M17DT04H10M57S','P2027Y11M25DT08H24M37S','P1979Y11M05DT13H51M22S','P1970Y11M23DT19H16M51S','P1996Y02M29DT12H05M18S','P1996Y12M28DT23H45M04S','P1972Y03M02DT12H10M55S']});
	should_fail("P1977Y02M26DT14H18M13S", $type, 0);
	should_fail("P1975Y12M04DT23H29M12S", $type, 0);
	should_fail("P2030Y11M04DT11H41M43S", $type, 0);
	should_fail("P1988Y08M06DT06H19M22S", $type, 0);
	should_fail("P2005Y11M27DT00H33M07S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2022Y01M11DT20H19M23S','P1989Y05M09DT01H08M05S','P1982Y12M17DT22H56M58S','P2012Y02M22DT03H48M48S','P1984Y12M23DT12H06M46S','P1979Y02M11DT22H52M38S','P2007Y02M01DT19H26M41S','P1990Y07M09DT03H47M52S']});
	should_fail("P1981Y11M23DT16H09M50S", $type, 0);
	should_fail("P2010Y06M28DT11H03M59S", $type, 0);
	should_fail("P1992Y10M18DT14H04M45S", $type, 0);
	should_fail("P2029Y02M05DT05H00M57S", $type, 0);
	should_fail("P1989Y02M26DT09H51M25S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2021Y09M08DT03H42M27S','P2010Y05M07DT14H05M41S','P1990Y12M17DT18H41M05S','P2018Y09M13DT19H46M10S','P1983Y04M09DT10H45M44S','P2023Y12M22DT12H00M51S']});
	should_fail("P2010Y07M27DT09H27M16S", $type, 0);
	should_fail("P2026Y09M14DT21H08M32S", $type, 0);
	should_fail("P1975Y03M27DT00H38M25S", $type, 0);
	should_fail("P1981Y07M18DT07H20M45S", $type, 0);
	should_fail("P2020Y08M07DT17H01M03S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P2030Y09M20DT23H22M15S','P1995Y05M21DT23H38M45S','P1987Y02M08DT13H31M40S','P1971Y10M29DT14H33M12S','P1988Y10M13DT14H03M01S']});
	should_fail("P1984Y04M17DT14H29M44S", $type, 0);
	should_fail("P2000Y11M09DT22H21M21S", $type, 0);
	should_fail("P1982Y08M31DT16H43M07S", $type, 0);
	should_fail("P2024Y11M27DT08H56M36S", $type, 0);
	should_fail("P1994Y10M27DT19H38M01S", $type, 0);
	done_testing;
};

subtest "Type atomic/duration is restricted by facet enumeration." => sub {
	my $type = mk_type('Duration', {'enumeration' => ['P1987Y10M28DT18H24M51S','P1999Y09M16DT05H02M00S','P1979Y05M22DT05H21M45S','P2013Y09M20DT23H44M26S','P1985Y09M14DT12H30M28S','P2027Y08M14DT12H11M35S','P1972Y05M09DT19H36M52S','P1978Y04M20DT03H54M49S','P1972Y01M20DT23H15M38S','P2026Y08M11DT17H53M15S']});
	should_fail("P2026Y09M10DT04H49M57S", $type, 0);
	should_fail("P1996Y07M07DT12H07M48S", $type, 0);
	should_fail("P2002Y01M29DT05H40M29S", $type, 0);
	should_fail("P2014Y08M29DT12H35M33S", $type, 0);
	should_fail("P2000Y08M01DT22H16M07S", $type, 0);
	done_testing;
};

done_testing;

