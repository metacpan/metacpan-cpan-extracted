######################################################################
# 04_stringify.pl - mb::JSON::stringify example
#
# Usage: perl eg/04_stringify.pl
#
# stringify() is an alias for encode().  Both names are interchangeable.
#
# Demonstrates:
#   - stringify: alias for encode() -- convert Perl data to JSON text
#   - encode:    the canonical name for the same operation
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

# stringify a simple hash
my $json = mb::JSON::stringify({ name => 'Alice', age => 30 });
print "$json\n";
# -> {"age":30,"name":"Alice"}

# stringify booleans
print mb::JSON::stringify(mb::JSON::true),  "\n";   # true
print mb::JSON::stringify(mb::JSON::false), "\n";   # false

# stringify null
print mb::JSON::stringify(undef), "\n";              # null

# stringify an array
print mb::JSON::stringify([1, 'two', undef, mb::JSON::true]), "\n";
# -> [1,"two",null,true]

# UTF-8 multibyte string (kept as-is, not \uXXXX)
my $ja = "\xe7\x94\xb0\xe4\xb8\xad";   # U+7530 U+4E2D (Tanaka in kanji)
print mb::JSON::stringify({ name => $ja, age => 30 }), "\n";

# nested structure
print mb::JSON::stringify({
    user   => { name => 'Alice', active => mb::JSON::true },
    scores => [100, 98, 95],
}), "\n";
# -> {"scores":[100,98,95],"user":{"active":true,"name":"Alice"}}

# stringify() == encode() -- same result
my $data = { x => 1, y => 2 };
print "stringify eq encode: ";
print (mb::JSON::stringify($data) eq mb::JSON::encode($data) ? "YES\n" : "NO\n");
