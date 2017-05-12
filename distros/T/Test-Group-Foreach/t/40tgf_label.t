# Testing the tgf_label function

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;
use Test::Group;
use Test::Group::Foreach qw(next_test_foreach tgf_label);

my @data = (
    0, 1, 
    [empty => ''],
    'foo',
    [ ab => "aabb",
      ac => "aacc",
      ad => "aadd",
    ],
);

my %data2label;

next_test_foreach my $d, 'd', @data;
test tgf_label => sub {
    lives_ok { $data2label{$d} = tgf_label $d } "got label for [$d]";
};

is $data2label{0},      0,       "0 label";
is $data2label{1},      1,       "1 label";
is $data2label{''},     'empty', "empty label";
is $data2label{'foo'},  'foo',   "foo label";
is $data2label{'aabb'}, 'ab',    "ab label";
is $data2label{'aacc'}, 'ac',    "ac label";
is $data2label{'aadd'}, 'ad',    "ad label";

next_test_foreach my $q, 'q', 1, 2, 3;

dies_ok { tgf_label $q } "tgf_label outside group dies";

my $z;
test "tgf_label wrong variable" => sub {
    dies_ok { tgf_label $z } "wrong var";
};

next_test_foreach my $foo, 'foo', 1, 2, 3;
test passingtest => sub { ok 1, "this passes" };
test "tgf_label old variable" => sub {
    dies_ok { tgf_label $foo } "old variable not valid in later test group";
};

next_test_foreach $z, '', 1, 2, 3;
test empty_varname => sub {
    is tgf_label($z), "$z", "$z correct label";
};

next_test_foreach $z, undef, 1, 2, 3;
test undef_varname => sub {
    is tgf_label($z), "$z", "$z correct label";
};

