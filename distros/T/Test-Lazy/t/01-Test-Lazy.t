#!perl

use strict;
use warnings;

use Test::More (0 ? (tests => 1) : 'no_plan');
use lib (qw/lib/);
use vars qw/$c $d/;
use Test::Deep;

use Test::Lazy qw/check try template/;
use constant TEST_EXAMPLES => $ENV{TEST_EXAMPLES};

# POD {{{
TEST_EXAMPLES and do {
	check([qw/a b/] => is => [qw/a b c/]);
    try("2 + 2" => '==' => 5);
    try('qw/a/' => is => ['a']);
    try('[qw/a/]' => is => ['a']);
    try(sub { 1 } => is => 0);
    my $rsc = 1;
    try(sub { $rsc } => is => 0);
    try(sub { $rsc } => is => 0);
	try('2 + 2' => '==' => 5, "Math is hard: %?");
    Test::Lazy->singleton->cmp_scalar->{is_xyzzy} = sub {
        Test::More::cmp_ok($_[0] => eq => "xyzzy", $_[2]);
    };
	check("xyzy" => "is_xyzzy");
};
# }}}
# check {{{
Test::Lazy::check(1 => ok => undef);
Test::Lazy::check(0 => not_ok => undef);
Test::Lazy::check(1 => is => 1);
Test::Lazy::check(0 => isnt => 1);
Test::Lazy::check(a => like => qr/[a-zA-Z]/);
Test::Lazy::check(0 => unlike => qr/a-zA-Z]/);
Test::Lazy::check(1 => '>' => 0);
Test::Lazy::check(0 => '<' => 1);
Test::Lazy::check(0 => '<=' => 0);
Test::Lazy::check(0 => '<=' => 1);
Test::Lazy::check(0 => '>=' => 0);
Test::Lazy::check(1 => '>=' => 0);
Test::Lazy::check(0 => lt => 1);
Test::Lazy::check(a => gt => 0);
Test::Lazy::check(0 => le => 1);
Test::Lazy::check(1 => le => 1);
Test::Lazy::check(a => ge => 0);
Test::Lazy::check(0 => ge => 0);
Test::Lazy::check(0 => '==' => 0);
Test::Lazy::check(0 => '!=' => 1);
Test::Lazy::check(a => eq => 'a');
Test::Lazy::check(a => ne => 'b');
# }}}
# try {{{
Test::Lazy::try(1 => ok => undef);
Test::Lazy::try(0 => not_ok => undef);
Test::Lazy::try(1 => is => 1);
Test::Lazy::try(0 => isnt => 1);
Test::Lazy::try('qw/a/' => like => qr/[a-zA-Z]/);
Test::Lazy::try(0 => unlike => qr/a-zA-Z]/);
Test::Lazy::try(1 => '>' => 0);
Test::Lazy::try(0 => '<' => 1);
Test::Lazy::try(0 => '<=' => 0);
Test::Lazy::try(0 => '<=' => 1);
Test::Lazy::try(0 => '>=' => 0);
Test::Lazy::try(1 => '>=' => 0);
Test::Lazy::try(0 => lt => 1);
Test::Lazy::try('qw/a/' => gt => 0);
Test::Lazy::try(0 => le => 1);
Test::Lazy::try(1 => le => 1);
Test::Lazy::try('qw/a/' => ge => 0);
Test::Lazy::try(0 => ge => 0);
Test::Lazy::try(0 => '==' => 0);
Test::Lazy::try(0 => '!=' => 1);
Test::Lazy::try('qw/a/' => eq => 'a');
Test::Lazy::try('qw/a/' => ne => 'b');
# }}} 

my $template = template(\<<_END_);
qw/1/
qw/a/
qw/apple/
qw/2/
qw/0/
# Let's test this one too.
qw/-1/

 # And this!
map { \$_ => \$_ * 2 } qw/0 1 2 3 4/
_END_

$template->test("defined(%?)" => ok => undef);
$template->test("length(%?) >= 1" => ok => undef);
$template->test("length(%?)" => '>=' => 1);
$template->test("length(%?)" => '<' => 12);
$template->test([
	[ is => 1 ],
	[ is => 'a' ],
	[ is => 'apple' ],
	[ is => 2 ],
	[ is => 0 ],
	[ is => -1 ],
	[ is => { 0 => 0, 1 => 2, 2 => 4, 3 => 6, 4 => 8 } ],
]);

$template = Test::Lazy::Template->new([ 
	[ "qw/1/" ],
	[ "qw/a/" ],
	[ "qw/apple/" ],
	[ "qw/2/" ],
	[ "qw/0/" ],
	[ "qw/-1/" ],
	[ "map { \$_ => \$_ * 2 } qw/0 1 2 3 4/" ],
]);

$template->test("defined(%?)" => ok => undef);
$template->test("length(%?) >= 1" => ok => undef);
$template->test("length(%?)" => '>=' => 1);
$template->test("length(%?)" => '<' => 12);
$template->test([
	[ is => 1 ],
	[ is => 'a' ],
	[ is => 'apple' ],
	[ is => 2 ],
	[ is => 0 ],
	[ is => -1 ],
	[ is => { 0 => 0, 1 => 2, 2 => 4, 3 => 6, 4 => 8 } ],
]);

