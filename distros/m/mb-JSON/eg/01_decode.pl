######################################################################
# 01_decode.pl - Decode JSON text to Perl data structures
#
# Usage: perl eg/01_decode.pl
#
# Demonstrates:
#   - decode: convert JSON text to Perl data
#   - parse:  alias for decode() -- both names are interchangeable
#   - Handling objects, arrays, strings, numbers, null
#   - true/false as mb::JSON::Boolean objects
#   - UTF-8 multibyte strings
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

# --- decode: simple object ---
my $data = mb::JSON::decode('{"name":"Alice","age":30,"active":true}');
print "name:   $data->{name}\n";      # Alice
print "age:    $data->{age}\n";       # 30
print "active: $data->{active}\n";    # true (stringifies)
print "active is true\n" if $data->{active};

# --- parse: alias for decode() -- identical result ---
my $data2 = mb::JSON::parse('{"name":"Alice","age":30,"active":true}');
print "name:   $data2->{name}\n";     # Alice
print "age:    $data2->{age}\n";      # 30
print "active: $data2->{active}\n";   # true (stringifies)

# --- null becomes undef ---
my $d3 = mb::JSON::decode('{"value":null}');
print "value is undef\n" unless defined $d3->{value};

# --- Array ---
my $arr = mb::JSON::decode('[1,"two",true,null]');
for my $i (0 .. $#$arr) {
    my $v = defined $arr->[$i] ? $arr->[$i] : 'undef';
    print "arr[$i] = $v\n";
}

# --- UTF-8 multibyte ---
my $mb = mb::JSON::decode("{\"greeting\":\"\xe3\x81\x93\xe3\x82\x93\xe3\x81\xab\xe3\x81\xa1\xe3\x81\xaf\"}");
print "greeting: $mb->{greeting}\n";  # Konnichiwa in UTF-8
