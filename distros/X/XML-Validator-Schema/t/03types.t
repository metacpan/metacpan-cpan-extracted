#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw(no_plan);
use XML::Validator::Schema::TypeLibrary;
my $lib = XML::Validator::Schema::TypeLibrary->new();

sub supported_type {
    return 1 if $lib->find(name => shift);
    return 0;
}

our $LAST_MSG;
sub check_type {
    my $type = $lib->find(name => shift);
    return 0 unless $type;
    my ($ok, $msg) = $type->check(shift);
    $LAST_MSG = $msg;
    return $ok;
}
    

ok(supported_type('string'));
ok(check_type(string => "any ol' thang"));
ok(check_type(string => ""));

ok(supported_type('integer'));
ok(check_type(integer => "0"));
ok(check_type(integer => "1"));
ok(check_type(integer => "-1"));
ok(check_type(integer => "2147483647"));
ok(check_type(integer => "-2147483648"));
ok(check_type(integer => "12147483648"));
ok(check_type(integer => "-12147483648"));

ok(supported_type('nonPositiveInteger'));
ok(    check_type(nonPositiveInteger => "0"));
ok(not check_type(nonPositiveInteger => "1"));
ok(    check_type(nonPositiveInteger => "-1"));
ok(not check_type(nonPositiveInteger => "2147483647"));
ok(    check_type(nonPositiveInteger => "-2147483648"));
ok(not check_type(nonPositiveInteger => "12147483648"));
ok(    check_type(nonPositiveInteger => "-12147483648"));

ok(supported_type('nonNegativeInteger'));
ok(    check_type(nonNegativeInteger => "0"));
ok(    check_type(nonNegativeInteger => "1"));
ok(not check_type(nonNegativeInteger => "-1"));
ok(    check_type(nonNegativeInteger => "2147483647"));
ok(not check_type(nonNegativeInteger => "-2147483648"));
ok(    check_type(nonNegativeInteger => "12147483648"));
ok(not check_type(nonNegativeInteger => "-12147483648"));

ok(supported_type('positiveInteger'));
ok(not check_type(positiveInteger => "0"));
ok(    check_type(positiveInteger => "1"));
ok(not check_type(positiveInteger => "-1"));
ok(    check_type(positiveInteger => "2147483647"));
ok(not check_type(positiveInteger => "-2147483648"));
ok(    check_type(positiveInteger => "12147483648"));
ok(not check_type(positiveInteger => "-12147483648"));

ok(supported_type('negativeInteger'));
ok(not check_type(negativeInteger => "0"));
ok(not check_type(negativeInteger => "1"));
ok(    check_type(negativeInteger => "-1"));
ok(not check_type(negativeInteger => "2147483647"));
ok(    check_type(negativeInteger => "-2147483648"));
ok(not check_type(negativeInteger => "12147483648"));
ok(    check_type(negativeInteger => "-12147483648"));

ok(supported_type('int'));
ok(check_type(int => "1"));
ok(check_type(int => "-1"));
ok(check_type(int => "2147483647"));
ok(check_type(int => "-2147483648"));
ok(not check_type(int => "12147483648"));
ok(not check_type(int => "-12147483648"));

ok(supported_type('unsignedInt'));
ok(check_type(unsignedInt => "1"));
ok(not check_type(unsignedInt => "-1"));
ok(check_type(unsignedInt => "2147483647"));
ok(not check_type(unsignedInt => "-2147483648"));
ok(not check_type(unsignedInt => "12147483648"));
ok(not check_type(unsignedInt => "-12147483648"));

ok(supported_type('short'));
ok(check_type(short => "1"));
ok(check_type(short => "-1"));
ok(not check_type(short => "2147483647"));
ok(not check_type(short => "-2147483648"));

ok(supported_type('unsignedShort'));
ok(check_type(unsignedShort => "1"));
ok(not check_type(unsignedShort => "-1"));
ok(not check_type(unsignedShort => "2147483647"));
ok(not check_type(unsignedShort => "-2147483648"));

ok(supported_type('byte'));
ok(check_type(byte => "1"));
ok(check_type(byte => "-1"));
ok(not check_type(byte => "255"));
ok(not check_type(byte => "-255"));

ok(supported_type('unsignedByte'));
ok(check_type(unsignedByte => "1"));
ok(not check_type(unsignedByte => "-1"));
ok(check_type(unsignedByte => "255"));
ok(not check_type(unsignedByte => "-255"));

ok(supported_type('boolean'));
ok(check_type(boolean => "0"));
ok(check_type(boolean => "1"));
ok(check_type(boolean => "true"));
ok(check_type(boolean => "false"));
ok(not check_type(boolean => "foo"));

ok(supported_type('dateTime'));
ok(check_type(dateTime => "1999-05-31T13:20:00-05:00"));
ok(check_type(dateTime => "1999-05-31T13:20:00+05:00"));
ok(check_type(dateTime => "1999-05-31T13:20:00"));
ok(check_type(dateTime => "1999-05-31T13:20:00Z"));
ok(check_type(dateTime => "-1999-05-31T13:20:00Z"));
ok(check_type(dateTime => "+1999-05-31T13:20:00Z"));
ok(not check_type(dateTime => "99-05-31T13:20:00-05:00"));

ok(supported_type('NMTOKEN'));
ok(check_type(NMTOKEN => ""));
ok(check_type(NMTOKEN => "sam"));
ok(check_type(NMTOKEN => "123sam.-_:"));
ok(not check_type(NMTOKEN => "123sam.-_:!"));

ok(supported_type('normalizedString'));
ok(check_type(normalizedString => ""));
ok(check_type(normalizedString => "sam"));
ok(check_type(normalizedString => "\n\ns\na\nm\n\n"));

ok(supported_type('token'));
ok(check_type(normalizedString => ""));
ok(check_type(normalizedString => "sam"));
ok(check_type(normalizedString => "\n\ns\na\nm\n\n"));

ok(supported_type('double'));
ok(check_type(double => '-1E4'));
ok(check_type(double => '1267.43233E12'));
ok(check_type(double => '12.78e-2'));
ok(check_type(double => '12'));
ok(check_type(double => '012'));
ok(check_type(double => 'INF'));
ok(not check_type(double => 'A'));
ok(not check_type(double => 'b10.5'));
ok(not check_type(double => ''));

ok(supported_type('QName'));
ok(check_type(QName =>'pre:myElement'));
ok(check_type(QName =>'myElement'));
ok(check_type(QName =>'a123:b3212'));
ok(check_type(QName =>'b3212'));
ok(not check_type(QName =>':myElement'));
ok(not check_type(QName =>'pre:3myElement'));


ok(supported_type('base64Binary'));
ok(check_type(base64Binary => '1968'));
ok(check_type(base64Binary => '0FB8'));
ok(check_type(base64Binary => '0fb8'));
ok(check_type(base64Binary => '0F'));
ok(check_type(base64Binary => 'FFFF00'));
ok(check_type(base64Binary => 'FFZq09'));
ok(check_type(base64Binary => 'F+Zq09'));


ok(supported_type('date'));
ok(check_type(date => '1968-04-02'));
ok(check_type(date => '-0045-01-01'));
ok(check_type(date => '11968-04-02'));
ok(check_type(date => '1968-04-02+05:00'));
ok(check_type(date => '1968-04-02Z'));
ok(not check_type(date => '68-04-02'));
ok(not check_type(date => '1968-4-2'));
ok(not check_type(date => '1968/04/02'));
ok(not check_type(date => '04-02-1968'));
ok(not check_type(date => '1968-04-31'));


ok(supported_type('gDay'));
ok(check_type(gDay => '---02'));
ok(check_type(gDay => '---02-05:00'));
ok(check_type(gDay => '---02Z'));
ok(not check_type(gDay => '02'));
ok(not check_type(gDay => '---2'));
ok(not check_type(gDay => '---32'));


ok(supported_type('gMonth'));
ok(check_type(gMonth => '--04'));
ok(check_type(gMonth => '--04-05:00'));
ok(check_type(gMonth => '--04Z'));
ok(not check_type(gMonth => '04'));
ok(not check_type(gMonth => '--4'));
ok(not check_type(gMonth => '--13'));


ok(supported_type('gMonthDay'));
ok(check_type(gMonthDay => '--04-02'));
ok(check_type(gMonthDay => '--04-02-05:00'));
ok(check_type(gMonthDay => '--04-12Z'));
ok(not check_type(gMonthDay => '--4-12Z'));
ok(not check_type(gMonthDay => '--4-12'));
ok(not check_type(gMonthDay => '--04-12+26:00'));


ok(supported_type('gYear'));
ok(check_type(gYear => '1968'));
ok(check_type(gYear => '1968-05:00'));
ok(check_type(gYear => '11968'));
ok(check_type(gYear => '0968'));
ok(check_type(gYear => '-0045'));
ok(not check_type(gYear => '68'));
ok(not check_type(gYear => '968'));
ok(not check_type(gYear => '1968-25:00'));


ok(supported_type('gYearMonth'));
ok(check_type(gYearMonth => '1968-04'));
ok(check_type(gYearMonth => '1968-04-05:00'));
ok(check_type(gYearMonth => '1968-12Z'));
ok(not check_type(gYearMonth => '68-04'));
ok(not check_type(gYearMonth => '1968'));
ok(not check_type(gYearMonth => '1968-4'));
ok(not check_type(gYearMonth => '1968-13'));


ok(supported_type('hexBinary'));
ok(check_type(hexBinary => '1968'));
ok(check_type(hexBinary => '0FB8'));
ok(check_type(hexBinary => '0fb8'));
ok(check_type(hexBinary => '0F'));
ok(check_type(hexBinary => 'FFFF00'));
ok(not check_type(hexBinary => 'FB8'));


ok(supported_type('time'));
ok(check_type(time => '13:30:59'));
ok(check_type(time => '13:20:30.5555'));
ok(check_type(time => '13:20:30-05:00'));
ok(check_type(time => '13:20:30Z'));
ok(not check_type(time => '5:20:30'));
ok(not check_type(time => '05:0:30'));
ok(not check_type(time => '05:20:3'));
ok(not check_type(time => '05:20:'));
ok(not check_type(time => '05:20.5:30'));
ok(not check_type(time => '05:65:30'));
