#!/usr/bin/perl

# Basic tests on interpolating against object references

use 5.008;
use strict;
use warnings;

use File::stat ();

use Test::More;

use YASF;

plan tests => 6;

my @raw      = stat $0;
my $obj      = File::stat::stat($0);
my $truth    = "@raw";
my $template = join q{ }, map { "{$_}" } qw(dev ino mode nlink uid gid rdev size
                                            atime mtime ctime blksize blocks);

my $str = YASF->new($template);

is($str % $obj, $truth, 'Basic % interpolation');
is($str->format($obj), $truth, 'Basic format() substitution');

$str->bind($obj);
is($str->format, $truth, 'format() substitution with bindings');
is($str, $truth, 'Direct stringification');

my @raw2   = stat $INC{'YASF.pm'};
my $obj2   = File::stat::stat($INC{'YASF.pm'});
my $truth2 = "@raw2";

is($str % $obj2, $truth2, 'Basic %, with override data');
is($str->format($obj2), $truth2, 'Basic format() with overrides');

exit;
