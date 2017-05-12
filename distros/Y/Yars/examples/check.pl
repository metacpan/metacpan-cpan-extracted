use strict;
use warnings;
use 5.010;
use Yars::Client;
use Mojo::URL;

my $y = Yars::Client->new;

$y->upload(__FILE__) or die "unable to upload myself!";
my $location = Mojo::URL->new($y->res->headers->header('location'));
my $md5 = ((split /\//, $location->path)[2]);

$y->check($md5, __FILE__) or die $y->errorstring;

print $y->tx->req->to_string, $y->tx->res->to_string;
