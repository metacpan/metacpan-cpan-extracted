use strict;
use warnings;
use FindBin::libs;
use WebService::WebSequenceDiagrams;

# SEE BELOW
#
#   http://www.websequencediagrams.com/examples.html
#

my $wsd = WebService::WebSequenceDiagrams->new;

$wsd->participant( name => "Alice" );

$wsd->participant( name => "Bob" );

$wsd->note(
    position => "left_of",
    name     => "Alice",
    text     => "This is displayed\nleft of Alice"
);

$wsd->note(
    position => "right_of",
    name     => "Alice",
    text     => "This is displayed right of Alice."
);

$wsd->note(
    position => "over",
    name     => "Alice",
    text     => "This is displayed over Alice."
);

$wsd->note(
    position => "over",
    name     => [ "Alice", "Bob" ],
    text     => "This is displayed over Bob and Alice."
);

print "-" x 20, "\n";
print $wsd->message;

$wsd->draw(
    style   => 'roundgreen',
    outfile => "out/ex5.png"
);

print "-" x 20, "\n";
print "generated to 'out/ex5.png'\n\n";
