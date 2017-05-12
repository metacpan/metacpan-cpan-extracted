use strict;
use warnings;
use Test::More tests => 3;

# the order is important
use WWW::Hashbang::Pastebin;
use Dancer::Plugin::DBIC;
use Dancer::Test;

schema->deploy;
my $data = do 't/etc/schema.pl';
schema->populate(@{ $data->{fixture_sets}->{basic} });

my $rand = rand()*10000 % 9999;
route_exists            [GET => "/$rand"], "route /$rand exists";
response_status_is      [GET => "/$rand"], 404, '404 for nonexistent paste';
response_content_is     [GET => "/$rand"], qq{No such paste as '$rand'};
