#!perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Text::Tree::Indented qw/ generate_tree /;

my %tests = (
    root => ['Root'],
    multiroot => ['Alpha', 'Beta', 'Gamma'],
    onelevel => ['Fruit', ['Apples', 'Oranges']],
    ladder => ['One', ['Two', ['Three', ['Four']]]],
    complex => ['ABC',[ 'DEF',[ 'GHI','JKL', ],'MNO',['PQR',['STU']],'VWX',]],
);

my %expected;

binmode(\*STDOUT,'utf8');
binmode(\*STDERR,'utf8');
parse_expected_results();
run_tests();
run_misc_additional_tests();
done_testing();

sub run_tests
{
    foreach my $testname (keys %tests) {
        my $data = $tests{$testname};
        foreach my $style (qw/ classic boxrule norule /) {
            my $tree = generate_tree($data, { style => $style });
            is($tree, $expected{"$testname/style=$style"},
               "check tree '$testname' with style '$style'");
        }
    }
}

sub run_misc_additional_tests
{

    my $tree = generate_tree($tests{onelevel});
    is($tree, $expected{"onelevel/style=boxrule"},
       "check tree 'onelevel' with no options ref");

    $tree = generate_tree($tests{onelevel}, {});
    is($tree, $expected{"onelevel/style=boxrule"},
       "check tree 'onelevel' with style in options ref");

}

sub parse_expected_results
{
    my $inblock = 0;
    my $key;
    local $_;

    while (<DATA>) {
        if (/\S/ && not $inblock) {
            chomp($key = $_);
            $expected{$key} = '';
            $inblock = 1;
            next;
        }
        if (/^\s*$/) {
            $key = undef;
            $inblock = 0;
            next;
        }
        $expected{$key} .= $_;
    }
}

__DATA__

root/style=classic
Root

root/style=boxrule
Root

root/style=norule
Root

multiroot/style=classic
Alpha
Beta
Gamma

multiroot/style=boxrule
Alpha
Beta
Gamma

multiroot/style=norule
Alpha
Beta
Gamma

onelevel/style=classic
Fruit
  +-Apples
  +-Oranges

onelevel/style=norule
Fruit
    Apples
    Oranges

onelevel/style=boxrule
Fruit
  ├─Apples
  └─Oranges

ladder/style=boxrule
One
  └─Two
      └─Three
          └─Four

ladder/style=classic
One
  +-Two
      +-Three
          +-Four

ladder/style=norule
One
    Two
        Three
            Four

complex/style=boxrule
ABC
  ├─DEF
  │   ├─GHI
  │   └─JKL
  ├─MNO
  │   └─PQR
  │       └─STU
  └─VWX

complex/style=classic
ABC
  +-DEF
  |   +-GHI
  |   +-JKL
  +-MNO
  |   +-PQR
  |       +-STU
  +-VWX

complex/style=norule
ABC
    DEF
        GHI
        JKL
    MNO
        PQR
            STU
    VWX

