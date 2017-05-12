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
    from => "Alice",
    to   => "Bob",
    text => "Authentication Request",
);

$wsd->alt( text => "successful case" );

$wsd->signal(
    from => "Bob",
    to   => "Alice",
    text => "Authentication Accepted",
);

$wsd->else( text => "some kind of failure", );

$wsd->signal(
    from => "Bob",
    to   => "Alice",
    text => "Authentication Failure",
);

$wsd->opt();

$wsd->loop( text => "1000 times", );

$wsd->signal(
    from => "Alice",
    to   => "Bob",
    text => "DNS Attack",
);

$wsd->end;

$wsd->end;

$wsd->else( text => "Another type of failure", );

$wsd->signal(
    from => "Bob",
    to   => "Alice",
    text => "Please repeat"
);

$wsd->end;

print "-" x 20, "\n";
print $wsd->message;

$wsd->draw( 
    style   => 'default',
    outfile => 'out/ex4.png'
);

print "-" x 20, "\n";
print "generated to 'out/ex4.png'\n\n";
