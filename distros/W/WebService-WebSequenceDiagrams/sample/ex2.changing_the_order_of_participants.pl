use strict;
use warnings;
use FindBin::libs;
use WebService::WebSequenceDiagrams;

# SEE BELOW
#
#   http://www.websequencediagrams.com/examples.html
#

my $wsd = WebService::WebSequenceDiagrams->new;

$wsd->participant( name => 'Bob' );

$wsd->participant( name => 'Alice' );

$wsd->participant(
    name => 'I have a really\nlong name',
    as   => 'L'
);

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

$wsd->signal(
    from => 'Bob',
    to   => 'L',
    text => 'Log transaction',
);

print "-" x 20, "\n";
print $wsd->message;

$wsd->draw(
    style   => "omegapple",
    outfile => "out/ex2.png"
);

print "-" x 20, "\n";
print "generated to 'out/ex2.png'\n\n";