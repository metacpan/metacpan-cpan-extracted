use strict;
use warnings;

# Perl Webhook test client
#  Greg Kennedy 2019
use Test::More tests => 3;

use WebService::Discord::Webhook;

#####################

# There is not much that can be tested without an Internet connection,
#  still, there is at least a regex in the constructor

## CONSTRUCTOR
# Create webhook client object

# the URL is the example from Discord's documentation
my $webhook;
ok(
  $webhook = WebService::Discord::Webhook->new(
'https://discordapp.com/api/webhooks/223704706495545344/3d89bb7572e0fb30d8128367b3b1b44fecd1726de135cbe28a41f8b2f777c372ba2939e72279b94526ff5d1bd4358d65cf11/'
  ),
  "Create webhook object"
);

is( $webhook->{id}, '223704706495545344', 'Parsed id OK' );
is(
  $webhook->{token},
'3d89bb7572e0fb30d8128367b3b1b44fecd1726de135cbe28a41f8b2f777c372ba2939e72279b94526ff5d1bd4358d65cf11',
  'Parsed token OK'
);

