BEGIN { print "1..1\n"; }

# Test for deeply nested elements to exercise st_serial_stack reallocation.
# This catches off-by-one errors in the stack growth check (GH #39).

use XML::Parser;

my $depth = 600;

my $xml = '';
for my $i (1 .. $depth) {
    $xml .= "<e$i>";
}
for my $i (reverse 1 .. $depth) {
    $xml .= "</e$i>";
}

my $p = XML::Parser->new;
eval { $p->parse($xml) };

print "not " if $@;
print "ok 1\n";
