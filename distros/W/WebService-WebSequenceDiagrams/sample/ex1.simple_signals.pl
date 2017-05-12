use strict;
use warnings;
use FindBin::libs;
use WebService::WebSequenceDiagrams;

# SEE BELOW
#
#   http://www.websequencediagrams.com/examples.html
#

my $wsd = WebService::WebSequenceDiagrams->new;

$wsd->signal(
    from => 'Alice',
    to   => 'Bob',
    text => 'Authentication Request',
);

$wsd->signal(
    from => 'Bob',
    to   => 'Alice',
    text => 'Authentication Response',
);

print "-" x 20, "\n";
print $wsd->message;

$wsd->draw( 
    style   => "rose",
    outfile => "out/ex1.png"
);

print "-" x 20, "\n";
print "generated to 'out/ex1.png'\n\n";
