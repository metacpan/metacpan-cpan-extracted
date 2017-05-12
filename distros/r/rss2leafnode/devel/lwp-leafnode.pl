use strict;
use warnings;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $resp = $ua->head('news://localhost/comp.lang.perl.misc');
my $server = $resp->header('Server');
print $server,"\n";
