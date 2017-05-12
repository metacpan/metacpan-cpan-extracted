#!/usr/bin/perl

#
# Unit test for Text::EscapeDelimiters
# $Id: escape_delim.t,v 1.3 2005/03/20 23:11:02 aldenj20 Exp $
#
# -t : trace
# -T : deep trace
#

use strict;
use Test::More;
use Getopt::Std;

#Move into the t directory
chdir($1) if($0 =~ /(.*)\/(.*)/);
unshift @INC, "./lib", "../lib";

use vars qw($opt_t $opt_T);
getopts('tT');

plan tests => 17;

#Compiles
unshift @INC, "../lib";
require_ok('Text::EscapeDelimiters');
ok($Text::EscapeDelimiters::VERSION =~ /^\d\.\d{3}$/, "Version - $Text::EscapeDelimiters::VERSION");

#Tracing
if($opt_t || $opt_T) {
	*TRACE = sub {
		print join(",", @_)."\n";
	};
	
	*DUMP = sub {
		use Data::Dumper;
		print Dumper(\@_);
	}
}
if($opt_T) {
	*Text::EscapeDelimiters::TRACE = *TRACE;
	*Text::EscapeDelimiters::DUMP = *DUMP;	
}

#Ctor
my $obj = new Text::EscapeDelimiters();
isa_ok($obj, 'Text::EscapeDelimiters');

#Test data
my @records = (
	["one" => "xyz"],
	["two:two:" => "a;b;c;"],
	["three;point;zero" => ":d;e:f;"],
);

#Use default escaping
my $stringified = join(";", map {
	join(":", map {$obj->escape($_, [":", ";"])} @$_)
} @records);

TRACE($stringified);

my @lines = $obj->split($stringified, ";");
DUMP(@lines);
is_deeply(\@lines, [
  'one:xyz',
  'two\:two\::a\;b\;c\;',
  'three\;point\;zero:\:d\;e\:f\;'
], "first-level split");

my @new = map {
	[ map {$obj->unescape($_)} $obj->split($_, ":") ]
} @lines; 

DUMP(@new);
is_deeply(\@records, \@new, "original data structure restored");

my $regex = $obj->regex(";");
my @first_2_lines = ();
while($stringified =~ /(.*?)$regex/g) {
	push @first_2_lines, $1 if($1);
}
is_deeply(\@first_2_lines, [@lines[0..1]], "regex method");

#Use custom escape chars
$obj = new Text::EscapeDelimiters({EscapeSequence => 'ESC'});
$stringified = join(";", map {
	join(":", map {$obj->escape($_, [":", ";"])} @$_)
} @records);
TRACE($stringified);
is($stringified, "one:xyz;twoESC:twoESC::aESC;bESC;cESC;;threeESC;pointESC;zero:ESC:dESC;eESC:fESC;", "custom escape character");
@new = map {
	[ map {$obj->unescape($_)} $obj->split($_, ":") ]
} $obj->split($stringified, ";"); 
is_deeply(\@records, \@new, "original data structure restored");

#Split on multiple delimiters at once
$obj = new Text::EscapeDelimiters();
my $string = "a\\:b=c:e=f:g\\=h=i";
is_deeply([$obj->split($string, [":","="])],["a\\:b","c","e","f","g\\=h","i"], "split on multiple");

#Null escape sequence
$obj = new Text::EscapeDelimiters({EscapeSequence => ""});
$string = "a:b";
is($obj->escape($string, [":"]), $string, "null escape sequence - escape");
is($obj->unescape($string, [":"]), $string, "null escape sequence - unescape");
is($obj->regex(undef), qr//, "regex with null delimiters and null esc seq");

#Null delimiters
$obj = new Text::EscapeDelimiters();
is($obj->escape($string, undef), $string, "escape with null delimiters");
is($obj->escape($string, [undef, ""]), $string, "escape with more null delimiters");
is($obj->regex(undef), qr/(?<!\\)/, "regex with null delimiters");

#Input validation
eval {$obj->escape($string, {1=>2})};
ok(defined($@), "escape with invalid delimiter");
eval {$obj->regex({1=>2})};
ok(defined($@), "regex with invalid delimiter");


#Tracing stubs
BEGIN {$^W = 0}
sub TRACE{}
sub DUMP{}
