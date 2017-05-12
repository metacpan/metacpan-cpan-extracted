use strict;
use warnings;
use FindBin::libs;
use WebService::WebSequenceDiagrams;

# SEE BELOW
#
#   http://www.websequencediagrams.com/examples.html
#

my $wsd = WebService::WebSequenceDiagrams->new;

$wsd->signal_to_self(
    itself => 'Alice',
    text =>
      'This is a signal to self.\nIt also demonstrates \nmultiline \ntext.',
);

print "-" x 20, "\n";
print $wsd->message;

$wsd->draw(
    style   => 'default',
    outfile => "out/ex3.png"
);

print "-" x 20, "\n";
print "generated to 'out/ex3.png'\n\n";
