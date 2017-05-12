use strict;
use warnings;
use Test::More;

# the order is important
use WWW::Hashbang::Pastebin;
use Dancer::Plugin::DBIC;
use Dancer::Test;

schema->deploy;
my $data = do 't/etc/schema.pl';
schema->populate(@{ $data->{fixture_sets}->{basic} });

my @invalid_ids = (')', '.b');
plan tests => 3*@invalid_ids;

foreach my $ID (@invalid_ids) {
    route_exists            [GET => "/$ID"], "route /$ID exists";
    response_status_is      [GET => "/$ID"], 400, '400 for invalid paste ID';
    response_content_is     [GET => "/$ID"], qq{'$ID' is not a valid paste ID};
}
