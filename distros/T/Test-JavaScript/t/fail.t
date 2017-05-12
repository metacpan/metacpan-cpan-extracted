#!/usr/bin/perl

use strict;
use warnings;

use Test::JavaScript qw(no_plan);
Test::JavaScript::no_ending(1);

use lib "t/lib";
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();
local $ENV{HARNESS_ACTIVE} = 0;

require Test::Builder;
my $TB = Test::Builder->create;
$TB->plan(tests => 21);

sub main::err_ok ($) {
    my($expect) = @_;
    my $got = $err->read;
    my ($comment) = split "\n", $got;
    return $TB->is_eq( $got, $expect, $got );
}

sub main::out_ok ($) {
    my($expect) = @_;
    my $got = $out->read;
    my ($comment) = split "\n", $got;
    return $TB->is_eq( $got, $expect, $comment );
}

my @temp;
END { unlink @temp or die "Couldn't unlink @temp\n"; };

my $test = 1;

sub pass {
    my ($f,@args) = @_;
    my $comment = $args[-1];
    $f->(@args);
    out_ok(<<EOT);
ok $test - $comment
EOT
    print $err->read;
    $test++;
}

sub fail {
    my ($f,@args) = @_;
    my $comment = $args[-1];
    $f->(@args);
    out_ok(<<EOT);
not ok $test - $comment
EOT
    print $err->read;
    $test++;
}

sub tempfile {
    my $data = shift || die "data required";
    my $fn = "tempfile-$$-".@temp;
    push @temp, $fn;
    open my $fh, ">$fn" or die "Couldn't write to $fn";
    print $fh $data;
    close $fh or die "Couldn't write to $fn";
    return $fn;
}

sub comment {
    my $cmd = shift;
    my ($rv) = split("\n", $cmd);
    return $rv;
}

##########
# use_ok #
##########

my $valid = tempfile(<<EOT);
Test = function () {
    return this;
}

Test.prototype = new Object;

Test.prototype.test = function (arg) {
    return "arg=" + arg;
}
EOT
pass(\&js_eval_ok, $valid, "use $valid;");

my $invalid = tempfile(<<EOT); 
Bogus = function () {
    return monkey;
}

Bogus.prototype = ;
EOT
pass(\&js_eval_ok, $valid, "use $valid;");

##########
#   ok   #
##########

# Positive ok tests

my @passing = (
    "var i = 2", "var i = 2",
    <<EOT,
    var array = new Array("hello","hi","howdy");
    for (var i = 0; i < array.length; i++) {
	var j = i;
    }
EOT
    <<EOT
    var string = "This is my string";
    string.split(" ");
EOT
);
pass(\&js_ok, $_, comment($_)) for @passing;

# Negative ok tests

my @failing = (
    "var 3 = 3;",
    "var array = ['one','two',noexist];",
);
fail(\&js_ok, $_, comment($_)) for @failing;

##########
#   is   #
##########

pass(\&js_ok, "var hw = 'Hello World'", "set hw to Hello World");

pass(\&js_is, "hw", "Hello World", "hw is 'Hello World'");

pass(\&js_ok, "var parts = hw.split(' ')", "split hw");

pass(\&js_is, "parts[0]", "Hello", "parts[0] is 'Hello'");
pass(\&js_is, "parts[1]", "World", "parts[1] is 'World'");
fail(\&js_is, "parts[2]", "Anything", "parts[2] is 'Anything'");

pass(\&js_ok, "var commad = parts.join(',')", "join with a comma");
fail(\&js_is, "commad", "Hello;World", "commad = Hello;World");
fail(\&js_is, "commad", "Hello.World", "commad = Hello.World");
pass(\&js_is, "commad", "Hello,World", "commad = Hello,World");

pass(\&js_isnt, "commad", "Hello;World", "commad = Hello;World");
pass(\&js_isnt, "commad", "Hello.World", "commad = Hello.World");
fail(\&js_isnt, "commad", "Hello,World", "commad = Hello,World");
