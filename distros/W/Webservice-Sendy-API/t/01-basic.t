use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile tempdir/;

my ($fh, $configfile) = tempfile();

use_ok "Webservice::Sendy::API";

my $config = <<EOF;
[defaults]
api_key=notrealkey
base_url=https://someurl.tld/sendy
brand_id=1
list_id=somelistid

[campaign]
from_name=name of sender of email
from_email=from address\@tld
reply_to=reply to address\@tld
EOF

# write fake config to temp file
print $fh $config;

# flush to file, close handle
close $fh;

# create client instance using temp config file
my $sendy = Webservice::Sendy::API->new(config => $configfile);

my @can = qw/new form_data create_campaign subscribe unsubscribe delete_subscriber get_subscription_status get_active_subscriber_count get_brands get_lists/;

can_ok $sendy, @can;

is $sendy->config->defaults->api_key, "notrealkey", "temp api key is, as expected";

my $rand = rand;

my $body = {
  api_key => "notrealkey",
  foo     => "bar",
  rand    => $rand,
}; 

is_deeply $sendy->form_data(rand => $rand, foo => "bar"), $body, "form body construction works";

done_testing;
