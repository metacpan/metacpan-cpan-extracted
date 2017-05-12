#!/usr/bin/perl

####################################################################
# Description of what this test does:
# Checks to see if _match does the right thing
####################################################################

use strict;
use warnings;

# useful diagnostic modules that's good to have loaded
use Data::Dumper;
use Devel::Peek;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

###################################
# user editable parts

use Test::Exception;

# start the tests
use Test::More tests => 8;

use Test::Log::Log4perl;

ok(Test::Log::Log4perl::_matches("foo", "foo"), "foo foo");
ok(!Test::Log::Log4perl::_matches("foo", "bar"), "foo bar");

ok(Test::Log::Log4perl::_matches("foo", qr/foo/), "foo qr/foo/");
ok(!Test::Log::Log4perl::_matches("foo", qr/bar/), "foo qr/bar/");

dies_ok { Test::Log::Log4perl::_matches("foo", {}) } "hash";
dies_ok { Test::Log::Log4perl::_matches("foo", bless({}, "bar"))} "object";

package Wibble;
use overload '""' => "as_string", fallback => 1;
sub as_string { "foo" };

package main;

ok(Test::Log::Log4perl::_matches("foo", bless({}, "Wibble")), "foo foo object");
ok(!Test::Log::Log4perl::_matches("bar", bless({}, "Wibble")), "bar foo object ");