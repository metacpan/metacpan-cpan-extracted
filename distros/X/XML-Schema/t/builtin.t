#============================================================= -*-perl-*-
#
# t/builtin.t
#
# Test the various built in simple types defined by XML::Schema.
# Types are defined in the XML::Schema::Type::Builtin module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: builtin.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Type::Builtin;
use XML::Schema::Facet::Builtin;

#$XML::Schema::Base::DEBUG = 1;
#$XML::Schema::Type::Simple::DEBUG = 1;

#ntests(70);
my ($pkg, $type, $item);


#========================================================================
# Primitive datatypes
#========================================================================

#------------------------------------------------------------------------
# string

$pkg  = 'XML::Schema::Type::string';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->{ name }, 'string' );

#------------------------------------------------------------------------
# boolean

$pkg = 'XML::Schema::Type::boolean';
my $bool = $pkg->new();
ok( $bool, $pkg->error()  );
match( $bool->instance('true')->{ value }, 'true' );
match( $bool->instance("  \ntrue\n  ")->{ value }, "true" );
match( $bool->instance("false")->{ value }, "false" );
match( $bool->instance("  \n\t\rfalse\r\t\n  ")->{ value }, "false" );
ok( ! $bool->instance("maybe") );
match( $bool->error(), 'value is not boolean (true/false)' );

#------------------------------------------------------------------------
# float

$pkg = 'XML::Schema::Type::float';
my $float = $pkg->new();
ok( $float, $pkg->error() );
ok( ! $float->instance('') );
match( $float->error(), 'value is empty' );
ok( ! $float->instance('four point five') );
match( $float->error(), 'value is not a valid float' );
ok( $float->instance('123e104') );
ok( ! $float->instance('123e105') );
match( $float->error(), 'float exponent is not valid (-149 <= e <= 104)' );
ok( $float->instance('123e-149') );
ok( ! $float->instance('123e-150') );
match( $float->error(), 'float exponent is not valid (-149 <= e <= 104)' );
my $f;

ok( $f = $float->instance('1234.56e27') );
match( $f->{ sign }, '' );
match( $f->{ infinity }, 0 );
match( $f->{ nan }, 0 );
match( $f->{ mantissa }, '1234.56' );
match( $f->{ exp_sign }, '' );
match( $f->{ exp_value }, 27 );
match( $f->{ exponent }, 27 );

ok( $f = $float->instance('-0.1e-27') );
match( $f->{ sign }, '-' );
match( $f->{ infinity }, 0 );
match( $f->{ nan }, 0 );
match( $f->{ mantissa }, '0.1' );
match( $f->{ exp_sign }, '-' );
match( $f->{ exp_value }, 27 );
match( $f->{ exponent }, '-27' );

ok( $f = $float->instance('NaN') );
match( $f->{ sign }, '' );
match( $f->{ infinity }, 0 );
match( $f->{ nan }, 1 );
match( $f->{ mantissa }, '' );
match( $f->{ exponent }, '' );

ok( $f = $float->instance('-INF') );
match( $f->{ sign }, '-' );
match( $f->{ infinity }, 1 );
match( $f->{ nan }, 0 );
match( $f->{ mantissa }, '' );
match( $f->{ exponent }, '' );

#------------------------------------------------------------------------
# double

$pkg = 'XML::Schema::Type::double';
my $dbl = $pkg->new();
ok( $dbl, $pkg->error() );
ok( ! $dbl->instance('') );
match( $dbl->error(), 'value is empty' );
ok( ! $dbl->instance('four point five') );
match( $dbl->error(), 'value is not a valid double' );
ok( $dbl->instance('123e970') );
ok( ! $dbl->instance('123e971') );
match( $dbl->error(), 'double exponent is not valid (-1075 <= e <= 970)' );
ok( $dbl->instance('123e-1075') );
ok( ! $dbl->instance('123e-1076') );
match( $dbl->error(), 'double exponent is not valid (-1075 <= e <= 970)' );
my $d;

ok( $d = $dbl->instance('1234.56e27') );
match( $d->{ sign }, '' );
match( $d->{ infinity }, 0 );
match( $d->{ nan }, 0 );
match( $d->{ mantissa }, '1234.56' );
match( $d->{ exp_sign }, '' );
match( $d->{ exp_value }, 27 );
match( $d->{ exponent }, 27 );

ok( $d = $dbl->instance('-0.1e-27') );
match( $d->{ sign }, '-' );
match( $d->{ infinity }, 0 );
match( $d->{ nan }, 0 );
match( $d->{ mantissa }, '0.1' );
match( $d->{ exp_sign }, '-' );
match( $d->{ exp_value }, 27 );
match( $d->{ exponent }, '-27' );

ok( $d = $dbl->instance('NaN') );
match( $d->{ sign }, '' );
match( $d->{ infinity }, 0 );
match( $d->{ nan }, 1 );
match( $d->{ mantissa }, '' );
match( $d->{ exponent }, '' );

ok( $d = $dbl->instance('-INF') );
match( $d->{ sign }, '-' );
match( $d->{ infinity }, 1 );
match( $d->{ nan }, 0 );
match( $d->{ mantissa }, '' );
match( $d->{ exponent }, '' );

#------------------------------------------------------------------------
# decimal

$pkg = 'XML::Schema::Type::decimal';
my $dec = $pkg->new();
ok( $dec );
match( $dec->instance(123)->{ value }, 123 );
match( $dec->instance("  123  ")->{ value }, "123" );
match( $dec->instance("  \n123\n  ")->{ value }, "123" );
match( $dec->instance("123.45")->{ value }, "123.45" );
match( $dec->instance("-123.45")->{ value }, "-123.45" );
match( $dec->instance("+123.45")->{ value }, "+123.45" );
ok( ! $dec->instance("123 four") );
match( $dec->error(), 'value is not a decimal' );

#------------------------------------------------------------------------
# timeDuration

$pkg = 'XML::Schema::Type::timeDuration';
my $time = $pkg->new();
ok( $time );
# general case
ok( $time->instance(" \n\t -P10Y9M8DT7H6M5.4S\n\n  "), $time->error() );
ok( $time->instance('-P10Y9M8DT7H6M5.4S'), $time->error() );
ok( $time->instance('P10Y9M8DT7H6M5.4S'), $time->error() );
ok( $time->instance('P10Y9M8D'), $time->error() );
ok( $time->instance('PT7H6M5S'), $time->error() );
ok( $time->instance('P1Y'), $time->error() );
ok( $time->instance('P2M'), $time->error() );
ok( $time->instance('P3D'), $time->error() );
ok( $time->instance('PT4H'), $time->error() );
ok( $time->instance('PT5M'), $time->error() );
ok( $time->instance('PT6S'), $time->error() );
ok( $time->instance('PT6.7S'), $time->error() );
ok( $time->instance('P0Y1347M'), $time->error() );
ok( $time->instance('P0Y1347M0D'), $time->error() );
# test failures
ok( ! $time->instance('') );
match( $time->error(), 'value is empty' );
ok( ! $time->instance('foo bar') );
match( $time->error(), 'value is not a valid timeDuration' );
ok( ! $time->instance('PT') );
match( $time->error(), 'value is not a valid timeDuration' );
ok( ! $time->instance('P10DT') );
match( $time->error(), 'value is not a valid timeDuration' );
ok( ! $time->instance('P') );
match( $time->error(), 'value must specify at least one date/time item' );
ok( ! $time->instance(123) );
match( $time->error(), 'value is not a valid timeDuration' );

# re-create type object (earlier bug caused this to fail because of the
# init() method permanently shifting values from @FACETS.
$time = $pkg->new();
ok( $time );
ok( ! $time->instance(123) );
match( $time->error(), 'value is not a valid timeDuration' );

# test zero_date, zero_time and zero
my $z = $time->instance('PT10M');
ok( $z );
ok( $z->{ zero_date } );
ok( ! $z->{ zero_time } );
ok( ! $z->{ zero } );

$z = $time->instance('P10M');
ok( $z );
ok( ! $z->{ zero_date } );
ok( $z->{ zero_time } );
ok( ! $z->{ zero } );

$z = $time->instance('P0Y');
ok( $z );
ok( $z->{ zero_date } );
ok( $z->{ zero_time } );
ok( $z->{ zero } );

#------------------------------------------------------------------------
# recurringDuration

$pkg = 'XML::Schema::Type::recurringDuration';
my $dur = $pkg->new();
ok( ! $dur );
match( $pkg->error(), "duration not defined" );

#$XML::Schema::Type::Simple::DEBUG = 1;
package XML::Schema::Type::Test::recDur1;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( @FACETS );
@FACETS = (
    duration => 'P10M',
);

package main;
$pkg = 'XML::Schema::Type::Test::recDur1';
$dur = $pkg->new( );
ok( ! $dur );
match( $pkg->error(), "period not defined" );

package XML::Schema::Type::Test::recDur2;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( @FACETS );
@FACETS = (
    duration => 'P10M',
    period   => '456',
);

package main;
$pkg = 'XML::Schema::Type::Test::recDur2';
$dur = $pkg->new( );
ok( ! $dur );
match( $pkg->error(), 'period value is not a valid timeDuration' );

package XML::Schema::Type::Test::recDur3;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( @FACETS );
@FACETS = (
    duration => 'P10Y',
    period   => 'PT10M',
);

package main;
$pkg = 'XML::Schema::Type::Test::recDur3';
$dur = $pkg->new( );
ok( $dur );

# NOTE: these don't parse according to the period/duration
ok( $dur->instance("2001-03-19T13:43:12.6") );
ok( $dur->instance("2001-03-19T13:43:12Z") );
ok( $dur->instance("2001-03-19T13:43:12-04:00") );
ok( $dur->instance("2001-03-19T13:43:12+01:02") );

#------------------------------------------------------------------------
# binary

$pkg = 'XML::Schema::Type::binary';
my $bin = $pkg->new();
ok( ! $bin );
match( $pkg->error(), "encoding not defined" );

package XML::Schema::Test::Binary::Bad;
use base qw( XML::Schema::Type::binary );
use vars qw( @FACETS );

@FACETS = (
    encoding => 'base63',
);

package main;

$pkg = 'XML::Schema::Test::Binary::Bad';
$bin = $pkg->new();
ok( ! $bin );
match( $pkg->error(), "encoding value must be 'hex' or 'base64'" );

package XML::Schema::Test::Binary::Good;
use base qw( XML::Schema::Type::binary );
use vars qw( @FACETS );

@FACETS = (
    encoding => 'base64',
    length   => 4,
);

package main;

$pkg = 'XML::Schema::Test::Binary::Good';
$bin = $pkg->new();
ok( $bin );
ok( $bin->instance(pack('C4', 65, 66, 67, 68)) );
ok( ! $bin->instance(pack('C5', 65, 66, 67, 68, 69)) );
match( $bin->error(), "string has 5 characters (required length: 4)" );

#------------------------------------------------------------------------
# uriReference

#------------------------------------------------------------------------
# ID 

#------------------------------------------------------------------------
# IDREF

#------------------------------------------------------------------------
# ENTITY

#------------------------------------------------------------------------
# QName

$pkg = 'XML::Schema::Type::QName';
my $qname = $pkg->new();
my $q;
ok( $q = $qname->instance("foo") );
match( $q->{ prefix }, '' );
match( $q->{ local }, 'foo' );
ok( $q = $qname->instance("foo:bar") );
match( $q->{ prefix }, 'foo' );
match( $q->{ local }, 'bar' );
ok( $q = $qname->instance("foo-bar:biz-baz") );
match( $q->{ prefix }, 'foo-bar' );
match( $q->{ local }, 'biz-baz' );

ok( ! $qname->instance('') );
match( $qname->error(), 'value is empty' );
ok( ! $qname->instance("999") );
match( $qname->error(), 'value is not a valid QName' );


#========================================================================
# Derived datatypes
#========================================================================

#------------------------------------------------------------------------
# CDATA

$pkg = 'XML::Schema::Type::CDATA';
my $cdata = $pkg->new();
ok( $cdata );
match( $cdata->name(), 'CDATA' );

$item = $cdata->instance("  \tThe cat\n\tsat on\r\tthe mat\n\t  ");
ok( $item );
match( $item->{ value }, "   The cat  sat on  the mat    ");

#------------------------------------------------------------------------
# token

$pkg = 'XML::Schema::Type::token';
my $token = $pkg->new();
ok( $token );
match( $token->name(), 'token' );

$item = $token->instance("  \tThe cat\n\tsat on\r\tthe mat\n\t  ");
ok( $item );
match( $item->{ value }, "The cat sat on the mat");

#------------------------------------------------------------------------
# language

$pkg = 'XML::Schema::Type::language';
my $lang = $pkg->new();
$item = $lang->instance("not a language");
ok( !$item );
match( $lang->error(), 'value is not a language' );
ok( $lang->instance("en-GB") );

#------------------------------------------------------------------------
# IDREFS
# ENTITIES

#------------------------------------------------------------------------
# NMTOKEN

$pkg = 'XML::Schema::Type::NMTOKEN';
$token = $pkg->new();
ok( $token );
ok( $token->instance('foo_bar:baz') );
ok( $token->instance('_foo-bar:baz.wiz_') );
ok( $token->instance('_foo-bar:baz.wiz_') );
match( $token->instance('  99-flake  ')->{ value }, '99-flake' );
ok( !$token->instance('foo!bar') );
match( $token->error(), 'value is not a valid NMTOKEN' );

#------------------------------------------------------------------------
# NMTOKENS

#------------------------------------------------------------------------
# Name

$pkg = 'XML::Schema::Type::Name';
my $name = $pkg->new();
ok( $name->instance("foo") );
ok( $name->instance(":foo") );
ok( $name->instance("  _foo_bar.baz-wiz:wax  ") );
ok( ! $name->instance("-foo") );
match( $name->error(), 'value is not a valid Name' );

#------------------------------------------------------------------------
# NCName

$pkg = 'XML::Schema::Type::NCName';
$name = $pkg->new();
ok( $name->instance("foo") );
ok( $name->instance("  _foo_bar.baz-wiz_wax  ") );
ok( ! $name->instance("-foo") );
match( $name->error(), 'value is not a valid NCName' );
ok( ! $name->instance("  _foo_bar.baz-wiz:wax  ") );
match( $name->error(), 'value is not a valid NCName' );
ok( ! $name->instance(":foo") );
match( $name->error(), 'value is not a valid NCName' );

#------------------------------------------------------------------------
# NOTATION

#------------------------------------------------------------------------
# integer

$pkg = 'XML::Schema::Type::integer';
my $int = $pkg->new();
ok( $int );
match( $int->name(), 'integer' );

$item = $int->instance("foo");
ok( ! $item );
match( $int->error(), "value is not a decimal");

ok( ($item = $int->instance(200)) );
ok( ($item = $int->instance(-200)) );
ok( ($item = $int->instance(+200)) );
ok( ! ($item = $int->instance('')) );
match( $int->error(), "value is empty");
ok( ! ($item = $int->instance(123.4)) );
match( $int->error(), "value is not an integer");

#------------------------------------------------------------------------
# nonPositiveInteger

$pkg = 'XML::Schema::Type::nonPositiveInteger';
$int = $pkg->new();
ok( $int );
ok( ! $int->instance(200) );
match( $int->error(), "value is positive");
ok( defined $int->instance(0) );
ok( $int->instance(-1), $int->error() );

#------------------------------------------------------------------------
# negativeInteger

$pkg = 'XML::Schema::Type::negativeInteger';
$int = $pkg->new();
ok( $int );
match( $int->name(), 'negativeInteger' );

ok( ! $int->instance("foo") );
match( $int->error(), "value is not a decimal");

ok( ! $int->instance(200) );
match( $int->error(), "value is not negative");
ok( ! $int->instance(0) );
match( $int->error(), "value is not negative");
ok( $int->instance(-200) );
ok( ! $int->instance('') );
match( $int->error(), "value is empty");

#------------------------------------------------------------------------
# long

$pkg = 'XML::Schema::Type::long';
my $min = "-9223372036854775808";
my $max =  "9223372036854775807";

my $long = $pkg->new();
ok( $long );
ok( $long->instance(20) );
ok( $long->instance(-20) );
ok( $long->instance($min) );
ok( $long->instance($max) );

# NOTE: unable to correctly validate the failure of the following 2 tests
# because Perl converts the numeric to a double of the form 
# -9.22337203685478e+18.  This is not a legal decimal (from which long is
# derived) and fails the decimal test with "value is not a decimal".

ok( ! $long->instance($min - 1) );
#match( $long->error(), "value is less than $min" );
ok( ! $long->instance($max + 1) );
#match( $long->error(), "value is greater than $max" );

#------------------------------------------------------------------------
# int

$pkg = 'XML::Schema::Type::int';
$min = -2147483648;
$max = 2147483647;

$int = $pkg->new();
ok( $int );
ok( $int->instance(20) );
ok( $int->instance(-20) );
ok( $int->instance($min) );
ok( $int->instance($max) );
ok( ! $int->instance($min - 1) );
match( $int->error(), 
       "value is " . ($min - 1) . " (required minInclusive: $min)" );
ok( ! $int->instance($max + 1) );
match( $int->error(),
       "value is " . ($max + 1) . " (required maxInclusive: $max)" );

#------------------------------------------------------------------------
# short

$pkg = 'XML::Schema::Type::short';
$min = -32768;
$max =  32767;

my $short = $pkg->new();
ok( $short );
ok( $short->instance(20) );
ok( $short->instance(-20) );
ok( $short->instance($min) );
ok( $short->instance($max) );
ok( ! $short->instance($min - 1) );
match( $short->error(), 
       "value is " . ($min - 1) . " (required minInclusive: $min)" );
ok( ! $short->instance($max + 1) );
match( $short->error(),
       "value is " . ($max + 1) . " (required maxInclusive: $max)" );

#------------------------------------------------------------------------
# byte

$pkg = 'XML::Schema::Type::byte';
my $byte = $pkg->new();
ok( $byte );
ok( $byte->instance(-30) );
ok( $byte->instance(30) );
ok( ! $byte->instance("foo") );
match( $byte->error(), "value is not a decimal");
ok( ! $byte->instance(200) );
match( $byte->error(), "value is 200 (required maxInclusive: 127)" );
ok( ! $byte->instance(-200) );
match( $byte->error(), "value is -200 (required minInclusive: -128)" );

#------------------------------------------------------------------------
# nonNegativeInteger

$pkg = 'XML::Schema::Type::nonNegativeInteger';
$int = $pkg->new();
ok( $int );
ok( ! $int->instance(-200) );
match( $int->error(), "value is negative");
ok( defined $int->instance(0) );
ok( $int->instance(1) );

#------------------------------------------------------------------------
# unsignedLong

$pkg = 'XML::Schema::Type::unsignedLong';
$long = $pkg->new();
ok( $long );
ok( $long->instance(20) );
ok( $long->instance(20000) );
ok( ! $long->instance(-1) );
match( $long->error(), 'value is negative' );

# NOTE: unable to correctly validate unsignedLong values at full stretch.
# see notes above and in docs/nonconform

#------------------------------------------------------------------------
# unsignedInt

$pkg = 'XML::Schema::Type::unsignedInt';
$max = 4294967295;
$int = $pkg->new();
ok( $int );
ok( $int->instance(20) );
ok( $int->instance(20000) );
ok( $int->instance($max) );
ok( ! $int->instance(-1) );
match( $int->error(), 'value is negative' );
ok( ! $int->instance($max + 1) );
match( $int->error(), 
       'value is ' . ($max + 1) . " (required maxInclusive: $max)" );

#------------------------------------------------------------------------
# unsignedShort

$pkg = 'XML::Schema::Type::unsignedShort';
$max = 65535;
$int = $pkg->new();
ok( $int );
ok( $int->instance(20) );
ok( $int->instance(20000) );
ok( $int->instance($max) );
ok( ! $int->instance(-1) );
match( $int->error(), 'value is negative' );
ok( ! $int->instance($max + 1) );
match( $int->error(), 
       'value is ' . ($max + 1) . " (required maxInclusive: $max)" );

#------------------------------------------------------------------------
# unsignedByte

$pkg = 'XML::Schema::Type::unsignedByte';
$max = 255;
$byte = $pkg->new();
ok( $byte );
ok( $byte->instance(20) );
ok( $byte->instance($max) );
ok( ! $byte->instance(-1) );
match( $byte->error(), 'value is negative' );
ok( ! $byte->instance($max + 1) );
match( $byte->error(), 
       'value is ' . ($max + 1) . " (required maxInclusive: $max)" );

#------------------------------------------------------------------------
# positiveInteger

$pkg = 'XML::Schema::Type::positiveInteger';
$int = $pkg->new();
ok( $int );
match( $int->name(), 'positiveInteger' );

ok( ! $int->instance("foo") );
match( $int->error(), "value is not a decimal");

ok( $int->instance(200) );
ok( ! $int->instance(-200) );
match( $int->error(), "value is not positive");
ok( ! $int->instance(0) );
match( $int->error(), "value is not positive");
ok( ! $int->instance('') );
match( $int->error(), "value is empty");

#------------------------------------------------------------------------
# timeInstant

$pkg = 'XML::Schema::Type::timeInstant';
$time = $pkg->new();
ok( $time );

ok( $time->instance("2001-03-19T13:43:12.6") );
ok( $time->instance("2001-03-19T13:43:12Z") );
ok( $time->instance("2001-03-19T13:43:12-04:00") );
ok( $time->instance("2001-03-19T13:43:12+01:02") );

my $t = $time->instance("2001-03-19T13:43:12Z");
ok( $t );
match( $t->{ century }, '20' );
match( $t->{ year  }, '01' );
match( $t->{ month }, '03' );
match( $t->{ day }, '19' );
match( $t->{ hour }, '13' );
match( $t->{ minute }, '43' );
match( $t->{ second }, '12' );
ok( $t->{ UTC } );

$t = $time->instance("2001-03-19T13:43:12+01:02");
ok( $t );
match( $t->{ zone }->{ sign }, '+' );
match( $t->{ zone }->{ hour }, '01' );
match( $t->{ zone }->{ minute }, '02' );

#------------------------------------------------------------------------
# time

$pkg = 'XML::Schema::Type::time';
$time = $pkg->new();
ok( $time );

ok( $time->instance("13:43:12.6") );
ok( $time->instance("13:43:12Z") );
ok( $time->instance("13:43:12-04:00") );
ok( $time->instance("13:43:12+01:02") );

$t = $time->instance("13:43:12Z");
ok( $t );
match( $t->{ hour }, '13' );
match( $t->{ minute }, '43' );
match( $t->{ second }, '12' );
ok( $t->{ UTC } );

$t = $time->instance("13:43:12+01:02");
ok( $t );
match( $t->{ zone }->{ sign }, '+' );
match( $t->{ zone }->{ hour }, '01' );
match( $t->{ zone }->{ minute }, '02' );

#------------------------------------------------------------------------
# timePeriod 

$pkg = 'XML::Schema::Type::timePeriod';
$time = $pkg->new();
ok( ! $time );
match( $pkg->error(), 'duration not defined' );

#------------------------------------------------------------------------
# date

$pkg = 'XML::Schema::Type::date';
my $date = $pkg->new();
ok( $date, $pkg->error() );
ok( $date->instance('1993-10-11'), $date->error() );
ok( $date->instance('-1024-03-19'), $date->error() );
$d = $date->instance('2001-02-26');
ok( $d );
match( $d->{ day }, 26 );
match( $d->{ month }, '02' );
match( $d->{ year }, '01' );
match( $d->{ century }, '20' );
$d = $date->instance('-32001-02-26');
match( $d->{ century }, '320' );
match( $d->{ sign }, '-' );

ok( ! $date->instance('1993-10-110') );
match( $date->error(), 'value is not a valid date' );

#------------------------------------------------------------------------
# month

$pkg = 'XML::Schema::Type::month';
my $month = $pkg->new();
ok( $month, $pkg->error() );
ok( $month->instance('1993-10'), $date->error() );
ok( $month->instance('-1024-03'), $date->error() );

my $m = $month->instance('2001-02');
ok( $m );
match( $m->{ month }, '02' );
match( $m->{ year }, '01' );
match( $m->{ century }, '20' );
$m = $month->instance('-0010-02');
ok( $m, $month->error()  );
match( $m->{ century }, '00' );
match( $m->{ year }, '10' );
match( $m->{ month }, '02' );
match( $m->{ sign }, '-' );

ok( ! $month->instance('1993-10-110') );
match( $month->error(), 'value is not a valid month' );
ok( ! $month->instance('1993') );
match( $month->error(), 'value is not a valid month' );

#------------------------------------------------------------------------
# year

$pkg = 'XML::Schema::Type::year';
my $year = $pkg->new();
ok( $year, $pkg->error() );
ok( $year->instance('1993'), $date->error() );
ok( $year->instance('-2723'), $date->error() );
ok( $year->instance('35711'), $date->error() );

my $y = $year->instance('2001');
ok( $y );
match( $y->{ year }, '01' );
match( $y->{ century }, '20' );
$y = $year->instance('-0010');
ok( $y, $year->error() );
match( $y->{ century }, '00' );
match( $y->{ year }, '10' );
match( $y->{ sign }, '-' );

ok( ! $year->instance('1993-12') );
match( $year->error(), 'value is not a valid year' );
ok( ! $year->instance('199') );
match( $year->error(), 'value is not a valid year' );

#------------------------------------------------------------------------
# century

$pkg = 'XML::Schema::Type::century';
my $century = $pkg->new();
ok( $century, $pkg->error() );
ok( $century->instance('19'), $date->error() );
ok( $century->instance('-07'), $date->error() );
ok( $century->instance('35711'), $date->error() );

my $c = $century->instance('21');
ok( $c );
match( $c->{ century }, '21' );
$c = $century->instance('-10');
ok( $c, $year->error() );
match( $c->{ century }, '10' );
match( $c->{ sign }, '-' );

ok( ! $century->instance('1993-12') );
match( $century->error(), 'value is not a valid century' );
ok( ! $century->instance('6') );
match( $century->error(), 'value is not a valid century' );

#------------------------------------------------------------------------
# recurringDate

$pkg = 'XML::Schema::Type::recurringDate';
$date = $pkg->new();
ok( $date );
ok( $date->instance('--11-22'), $date->error() );
ok( $date->instance('--07-23'), $date->error() );

$d = $date->instance('--11-22');
ok( $d );
match( $d->{ month }, '11' );
match( $d->{ day }, '22' );

ok( ! $date->instance('1993-12') );
match( $date->error(), 'value is not a valid recurringDate' );
ok( ! $date->instance('6') );
match( $date->error(), 'value is not a valid recurringDate' );

#------------------------------------------------------------------------
# recurringDay

$pkg = 'XML::Schema::Type::recurringDay';
my $day = $pkg->new();
ok( $day );
ok( $day->instance('---22'), $date->error() );

$d = $day->instance('---22');
ok( $d );
match( $d->{ day }, '22' );

