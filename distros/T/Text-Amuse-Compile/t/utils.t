#!perl

use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 7;

use Text::Amuse::Compile::Utils qw/read_file
                                   write_file
                                   append_file/;
use File::Spec;

my $string = "èò";
my $tmpfile = File::Spec->catfile(qw/t test.txt/);

write_file($tmpfile, $string);

is ((-s $tmpfile), 4, "$tmpfile has 4 bytes");

my $cmp = read_file($tmpfile);
is $string, $cmp, "String ok";
is length($cmp), 2, "String has 2 chars";

append_file($tmpfile, $string, $string);
is ((-s $tmpfile), 12, "$tmpfile has 12 bytes");
write_file($tmpfile, $string, $string);
is ((-s $tmpfile), 8, "$tmpfile has 8 bytes");
$cmp = read_file($tmpfile);
is length($cmp), 4, "String has 4 chars";
is $cmp, $string . $string, "String looks OK";

unlink $tmpfile or die $!;

