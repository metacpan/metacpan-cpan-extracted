######################################################################
# 02_encode.pl - Encode Perl data structures to JSON text
#
# Usage: perl eg/02_encode.pl
#
# Demonstrates:
#   - encode:    convert Perl data to JSON text
#   - stringify: alias for encode() -- both names are interchangeable
#   - true/false via mb::JSON::true and mb::JSON::false
#   - undef becomes null
#   - Hash keys are sorted alphabetically
#   - UTF-8 multibyte strings kept as-is
#   - Numbers vs strings
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

# --- encode: object with boolean and null ---
my $json = mb::JSON::encode({
    name    => 'Alice',
    age     => 30,
    active  => mb::JSON::true,
    deleted => mb::JSON::false,
    memo    => undef,
});
print "$json\n";
# -> {"active":true,"age":30,"deleted":false,"memo":null,"name":"Alice"}

# --- stringify: alias for encode() -- identical result ---
my $json2 = mb::JSON::stringify({
    name    => 'Alice',
    age     => 30,
    active  => mb::JSON::true,
    deleted => mb::JSON::false,
    memo    => undef,
});
print "$json2\n";
# -> {"active":true,"age":30,"deleted":false,"memo":null,"name":"Alice"}

# --- Array ---
print mb::JSON::encode([1, 'two', mb::JSON::true, undef]), "\n";
# -> [1,"two",true,null]

# --- UTF-8 multibyte keys and values ---
my $mb_json = mb::JSON::encode({
    "\xe5\x90\x8d\xe5\x89\x8d" => "\xe7\x94\xb0\xe4\xb8\xad",  # namae (name) => Tanaka in UTF-8
    "\xe5\xb9\xb4\xe9\xbd\xa2" => 30,                            # nenrei (age) => 30
});
print "$mb_json\n";

# --- Plain 1 is a number, not boolean ---
print mb::JSON::encode({ count => 1, flag => mb::JSON::true }), "\n";
# -> {"count":1,"flag":true}
