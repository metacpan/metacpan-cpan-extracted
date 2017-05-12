# $Id: 30tie.t 567 2006-06-01 18:38:57Z nicolaw $

chdir('t') if -d 't';

use strict;
use Test::More tests => 3;
use lib qw(./lib ../lib);
use Tie::TinyURL qw();

my %url;
tie %url, 'Tie::TinyURL', 'timeout' => 60;

my $tinyurl = "http://tinyurl.com/6";
my $url = "http://www.mapquest.com/maps/map.adp?ovi=1&mqmap.x=300&mqmap.y=75&mapdata=%252bKZmeiIh6N%252bIgpXRP3bylMaN0O4z8OOUkZWYe7NRH6ldDN96YFTIUmSH3Q6OzE5XVqcuc5zb%252fY5wy1MZwTnT2pu%252bNMjOjsHjvNlygTRMzqazPStrN%252f1YzA0oWEWLwkHdhVHeG9sG6cMrfXNJKHY6fML4o6Nb0SeQm75ET9jAjKelrmqBCNta%252bsKC9n8jslz%252fo188N4g3BvAJYuzx8J8r%252f1fPFWkPYg%252bT9Su5KoQ9YpNSj%252bmo0h0aEK%252bofj3f6vCP";

ok($url{$tinyurl} eq $url,"Lookup http://tinyurl.com/6");
my $shortbbc = $url{"http://www.bbc.co.uk"};
ok($shortbbc =~ /^http:\/\/tinyurl\.com\/[a-zA-Z0-9]+$/,"Reduce http://www.bbc.co.uk");
ok($url{$shortbbc} eq "http://www.bbc.co.uk","Lookup $shortbbc (http://www.bbc.co.uk)");

1;

