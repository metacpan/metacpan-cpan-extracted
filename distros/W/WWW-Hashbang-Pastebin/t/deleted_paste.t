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

route_exists            [GET => '/c'], 'route /c exists';
response_status_is      [GET => '/c'], 410, '410 for deleted paste';
response_content_is     [GET => '/c'], q{No such paste as 'c'};
