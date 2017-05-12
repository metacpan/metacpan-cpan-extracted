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
    from => "User",
    to   => "A",
    text => "DoWork"
);

$wsd->activate("A");

$wsd->signal(
    from => "A",
    to   => "B",
    text => "<<createRequest>>"
);

$wsd->activate("B");

$wsd->signal(
    from => "B",
    to   => "C",
    text => "DoWork"
);

$wsd->activate("C");

$wsd->signal(
    from => "C",
    to   => "B",
    text => "WorkDone"
);

$wsd->destroy("C");

$wsd->signal(
    from => "B",
    to   => "A",
    text => "RequestCreated"
);

$wsd->deactivate("B");

$wsd->signal(
    from => "A",
    to   => "User",
    text => "Done"
);

print "-" x 20, "\n";
print $wsd->message;

$wsd->draw(
    style   => 'modern-blue',
    outfile => "out/ex6.png"
);

print "-" x 20, "\n";
print "generated to 'out/ex6.png'\n\n";
