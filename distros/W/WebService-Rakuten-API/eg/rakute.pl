use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WebService::Rakuten::API;
use Data::Dumper;

my $rakuten = WebService::Rakuten::API->new(
  appid => '1094713744828153190',
);

my $items = $rakuten->books({keyword=>'遊戯王',format => 'json'});;

print Dumper $items;


