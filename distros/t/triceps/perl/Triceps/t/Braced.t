#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The test for Table.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Triceps.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use ExtUtils::testlib;

use Test;
BEGIN { plan tests => 61 };
use Triceps;
use Triceps::Braced qw(:all);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# splitting the braced lines

my @res;
my ($s1, $s2, $v);

####
# basic parsing, all kinds of whitespace
$s1 = $s2 = 'a
{
b
}            c' . "\t" . '{{  d  }}   ';
@res = &raw_split_braced($s1);
ok(join(",", @res), "a,{
b
},c,{{  d  }}");
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), "a,
b
,c,{  d  }");
ok($s2, '');

####
# escaped "{" in braces
$s1 = $s2 = 'a {b} c {\{d}';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},c,{\{d}');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c,\{d');
ok($s2, '');

####
# escaped "}" in braces
$s1 = $s2 = 'a {b} c {d\}}';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},c,{d\}}');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c,d\}');
ok($s2, '');

####
# escaped "}" at top level
$s1 = $s2 = 'a {b} c {d}\}e';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},c,{d},\}e');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c,d,\}e');
ok($s2, '');

####
# escaped "}" at top level
$s1 = $s2 = 'a {b} c {d}\{e';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},c,{d},\{e');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c,d,\{e');
ok($s2, '');

####
# empty line
$s1 = $s2 = '';
@res = &raw_split_braced($s1);
ok($#res, -1);
ok($s1, '');

@res = &split_braced($s2);
ok($#res, -1);
ok($s2, '');

####
# whitespace only
$s1 = $s2 = '   ';
@res = &raw_split_braced($s1);
ok($#res, -1);
ok($s1, '');

@res = &split_braced($s2);
ok($#res, -1);
ok($s2, '');

####
# an incomplete line with extra "{"
$s1 = $s2 = 'a {b} c {{d}';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},c');
ok($s1, '{{d}');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c');
ok($s2, '{{d}');

####
# an incomplete line with extra "}"
$s1 = $s2 = 'a {b} c} {d}';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},c');
ok($s1, '} {d}');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c');
ok($s2, '} {d}');

####
# escaped space
$s1 = $s2 = 'a b\ c';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,b\ c');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b\ c');
ok($s2, '');

####
# escaped space in nested lists
$s1 = $s2 = 'a {b}\ c';
@res = &raw_split_braced($s1);
ok(join(",", @res), 'a,{b},\ c');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,\ c');
ok($s2, '');

####
# quotes have no special effect
$s1 = $s2 = '"a b c"';
@res = &raw_split_braced($s1);
ok(join(",", @res), '"a,b,c"');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), '"a,b,c"');
ok($s2, '');

####
# no whitespace
$s1 = $s2 = '{a}{b}{c}';
@res = &raw_split_braced($s1);
ok(join(",", @res), '{a},{b},{c}');
ok($s1, '');

@res = &split_braced($s2);
ok(join(",", @res), 'a,b,c');
ok($s2, '');

#########################
# unquote
$s1 = &bunescape("\"\\\\+\\n \$zz \\\\ \\\\\ \"\\'\\{");
ok($s1, "\"\\+\n \$zz \\ \\ \"'{");

@res = &bunescape_all("a\\{", "{b}", "\\t");
ok(join(",", @res), "a{,{b},\t");

@res = &bunescape_all();
ok($#res, -1);

#########################
# split and unquote

####
# success
$s2 = 'a {b} c {d}\}e';
$v = &split_braced_final($s2);
ok(join(",", @$v), 'a,b,c,d,}e');
ok($s2, '');

####
# failure
$s2 = 'a {b} c {d}}e';
$v = &split_braced_final($s2);
ok(join(",", @$v), 'a,b,c,d');
ok($s2, '}e');

####
# undef
$s2 = undef;
$v = &split_braced_final($s2);
ok(!defined $v);
