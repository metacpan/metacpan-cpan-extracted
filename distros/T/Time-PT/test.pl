#!/usr/bin/perl -w
# 3AAFVlt - test.pl created by Pip@CPAN.Org to validate Time::PT
#     functionality.  
#   Before `make install' is performed this script should be run with
#     `make test'.  After `make install' it should work as `perl test.pl'.

use strict;
use Test;
BEGIN { plan tests => 16 } # 16,79,82
use Time::PT;

my $rslt; my $fldz; my $tnum = 0; our $lded = 1;
my @rdat = ();
ok(1);

$fldz = new Time::PT;
ok($fldz);

$rslt = $fldz->get_century();
ok($rslt, 0);

$rslt = $fldz->set_century(20);
ok($rslt, 20);

$fldz = Time::PT->new();
ok($fldz);

$fldz = Time::PT->new('str' => '0123456789');
ok($fldz);

$fldz = Time::PT->new('hash' => { 'jink' => 31 });
ok($fldz);

$rslt = $fldz->get_jink();
ok($rslt, 31);

$fldz = Time::PT->new('list' => [ 0, 3, 6, 9, 12, 15, 18, 21, 24, 27 ]);
ok($fldz);

@rdat = $fldz->ymd();
ok($rdat[1], 6);

@rdat = $fldz->ymd(4, 8, 12);
ok($rdat[1], 8);

$fldz = Time::PT->new('9876543210');
ok($fldz);

$rslt = $fldz->j(127);
ok($rslt, 127);

@rdat = $fldz->FooIsMyJoy(4, 8, 12);
ok($rdat[2], 12);
ok($rdat[7], 127);

$fldz = Time::PT->new('verbose' => 'July 4, 2004');
$rslt = $fldz->day();
ok($rslt, 4);


## done w/ 16 tests
#print "16 tests complete\n";
#$rslt = $fldz->month();
#ok($rslt, 7);
#$rslt = $fldz->year();
#ok($rslt, 2004);
#$fldz = Time::PT->new('verbose' => 'Tuesday, April 1 15:32:16:33 2003');
#$rslt = $fldz->day();
#ok($rslt, 1);
#$rslt = $fldz->month();
#ok($rslt, 4);
#$rslt = $fldz->year();
#ok($rslt, 2003);
#$rslt = "$fldz";
#ok($rslt, '341FWGX');
#my $fld2 = Time::PT->new('3C193GQ');
#$rslt = ($fldz cmp $fld2);
#ok($rslt, 'lt');
#$rslt = ($fldz <=> $fld2);
#ok($rslt, -1);
#$fld2 = Time::PT->new('3AB');
#$rslt = "$fld2";
#ok($rslt, '3AB0000');
#$fld2 = Time::PT->new('3C1HqZ4JG');
#$rslt = "$fld2";
#ok($rslt, '3C1HqZ4JG');
#print "26 tests complete\n";
#$fldz = Time::PT->new('1234567');
#$fldz += '321';
#$rslt = "$fldz";
#ok($rslt, '1234888');
#$fldz = Time::PT->new('1234567');
#$fldz -= '123';
#$rslt = "$fldz";
#ok($rslt, '1234444');
#$fldz = Time::PT->new('3C7');
#$rslt = $fldz->color();
#ok("$rslt", "\e[1;31m3\e[0;33mC\e[1;33m7");
#$rslt = $fldz->color('Simp');
#ok($rslt, '!R!O!Y');# ok($rslt, 'RbobYb');
#$fldz = Time::PT->new('');
##$rslt = $fldz->Y;  # test if new('') creates 0 year or 2000
##print "rslt:$rslt\n";
#$rslt = $fldz + '1234567';
#ok("$rslt", '1234567');
#$fldz = Time::PT->new('1234567');
#$rslt = $fldz + '1234567';
#ok("$rslt", '2468ACE');
#$fldz = Time::PT->new('');
#$rslt = $fldz + '1234';
#ok("$rslt", '1234');
#$fldz = Time::PT->new('1234');
#$rslt = $fldz + '1234';
#ok("$rslt", '1235234');
#print "34 tests complete\n";
## test carry
#$fldz = Time::PT->new('');
#$rslt = $fldz + 'x';
#ok("$rslt", 'x');
#$fldz = Time::PT->new('7777777');
#$rslt = $fldz + 'x';
#ok("$rslt", '7777786');
#$fldz = Time::PT->new('7777777');
#$rslt = $fldz + 'uvwx';
#ok("$rslt", '779G566');
#$fldz = Time::PT->new('7777777');
#$rslt = $fldz - '3333333';
#ok("$rslt", '4444444');
#$fldz = Time::PT->new('7777777');
#$rslt = $fldz - '3333';
#ok("$rslt", '7774444');
#$fldz = Time::PT->new('7777777');
#$rslt = $fldz - '8';
#ok("$rslt", '777776x');
#$fldz = Time::PT->new('777776x');
#$rslt = $fldz + '8';
#ok("$rslt", '7777777');
#
#$fldz = Time::PT->new('3C7Jr8L');
#$rslt = $fldz->frm;
#ok($rslt, 21);
#$rslt = $fldz->sec;
#ok($rslt, 8);
#$rslt = $fldz->min;
#ok($rslt, 53);
#$rslt = $fldz->hour;
#ok($rslt, 19);
#$rslt = $fldz->mday;
#ok($rslt, 7);
#$rslt = $fldz->mon;
#ok($rslt, 12);
#$rslt = $fldz->_mon;
#ok($rslt, 11);
#print "48 tests complete\n";
#$rslt = $fldz->monname('Feb');
#ok($rslt, 'Feb');
#$rslt = $fldz->O;
#ok($rslt, 2);
#$rslt = $fldz->fullmonth();
#ok($rslt, 'February');
#$rslt = $fldz->month();
#ok($rslt, 2);
#$rslt = $fldz->month(3);
#ok($rslt, 3);
#$rslt = $fldz->mon();
#ok($rslt, 3);
#$rslt = $fldz->_mon();
#ok($rslt, 2);
#$rslt = $fldz->monname();
#ok($rslt, 'Mar');
#$rslt = $fldz->fullmonth();
#ok($rslt, 'March');
#$rslt = $fldz->year();
#ok($rslt, 2003);
#$rslt = $fldz->_year();
#ok($rslt, 103);
#$rslt = $fldz->yy();
#ok($rslt, '03');
#$rslt = $fldz->dow();
#ok($rslt, 5);
#$rslt = $fldz->day_of_week();
#ok($rslt, 5);
#$rslt = $fldz->_wday();
#ok($rslt, 5);
#print "63 tests complete\n";
#$rslt = $fldz->wday();
#ok($rslt, 6);
#$rslt = $fldz->wdayname();
#ok($rslt, 'Fri');
#$rslt = $fldz->day();
#ok($rslt, 7);
#$rslt = $fldz->fullday();
#ok($rslt, 'Friday');
#$rslt = $fldz->yday();
#ok($rslt, 65);
#$rslt = $fldz->day_of_year();
#ok($rslt, 65);
#$rslt = $fldz->isdst();
#ok($rslt, 0);
#$rslt = $fldz->daylight_savings();
#ok($rslt, 0);
#$rslt = $fldz->hms();
#ok($rslt, 3);
#$rslt = $fldz->hmsf();
#ok($rslt, 4);
#$rslt = $fldz->time();
#ok($rslt, 4);
#my @rslt = $fldz->monname('Jen', 'Fab', 'Mer', 'Epr', 'Moy', 'Jin', 'Jil', 'Eug', 'Sap', 'Uct', 'Nev', 'Doc');
#ok($rslt, 4);
#$fldz = Time::PT->new('241');
#$rslt = $fldz->color('HTML');
#ok($rslt, '<a href="http://Ax9.Org/pt?241"><font color="#FF1B2B">2</font><font color="#FF7B2B">4</font><font color="#FFFF1B">1</font></a>');
#$fldz = Time::PT->new('3CB636B');
#$rslt = $fldz->color('HTML');
#ok($rslt, '<a href="http://Ax9.Org/pt?3CB636B"><font color="#FF1B2B">3</font><font color="#FF7B2B">C</font><font color="#FFFF1B">B</font><font color="#1BFF3B">6</font><font color="#1BFFFF">3</font><font color="#1B7BFF">6</font><font color="#BB1BFF">B</font></a>');
#
## these are for when 0 months/days can be handled by math functions
#$fldz = Time::PT->new('7777777');
#$rslt = $fldz - '8888888';
#$rslt = "$rslt";
#ok($rslt, '2BxMwwx');
#$fldz = Time::PT->new('2BxMwwx');
#$rslt = $fldz + '8888888';
#$rslt = "$rslt";
#ok($rslt, '7777777');
#print "79 tests complete\n";
##$fldz = Time::PT->new('3');
##$rslt = $fldz - '1';
##$rslt = "$rslt";
##ok($rslt, '7777777');
##$fldz = Time::PT->new('30UNxxx');
##$rslt = $fldz + '1';
##$rslt = "$rslt";
##ok($rslt, '7777777');
##
##$fldz = Time::PT->new('');
##$rslt = $fldz + '';
##$rslt = "$rslt";
##ok($rslt, '0000000');
