use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::URL;

my $port = shift;

my $url = Mojo::URL->new('http://127.0.0.1/foo');
$url->port($port);

my $ua = Mojo::UserAgent->new;
print $ua->get($url)->res->body;

exit 22;
