######################################################################
# 03_parse.pl - mb::JSON::parse example
#
# Usage: perl eg/03_parse.pl
#
# parse() is an alias for decode().  Both names are interchangeable.
#
# Demonstrates:
#   - parse:  alias for decode() -- convert JSON text to Perl data
#   - decode: the canonical name for the same operation
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use mb::JSON;

# parse a simple object
my $h = mb::JSON::parse('{"name":"Alice","age":30}');
print "name: $h->{name}\n";    # Alice
print "age:  $h->{age}\n";     # 30

# parse a boolean
my $b = mb::JSON::parse('{"ok":true,"ng":false}');
print "ok: $b->{ok}\n";        # true
print "ng: $b->{ng}\n";        # false
print "ok is true\n" if $b->{ok};

# parse null
my $n = mb::JSON::parse('{"value":null}');
print "value is undef\n" unless defined $n->{value};

# parse an array
my $arr = mb::JSON::parse('[1,"two",true,null]');
for my $i (0 .. $#$arr) {
    my $v = defined $arr->[$i] ? $arr->[$i] : 'undef';
    print "arr[$i] = $v\n";
}

# parse() == decode() -- same result
my $a = mb::JSON::parse('{"x":1}');
my $b2 = mb::JSON::decode('{"x":1}');
print "parse eq decode: ";
print (($a->{x} == $b2->{x}) ? "YES\n" : "NO\n");
