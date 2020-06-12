use strict;
use warnings;

# Perl Webhook test client
#  Greg Kennedy 2019
use Test::More tests => 11;

use WebService::Discord::Webhook;

#####################

# NOTE: There is not much that can be tested without an Internet connection.
#  This file will exercise the constructor regex, and some parameter
#  validation fo the methods.
# For testing using a "live" Webhook, see file xt/webhook-extra.t

my $webhook;

## CONSTRUCTOR
# Create webhook client object
#  the URL is the example from Discord's documentation

# various wrong ways to create the object
eval { WebService::Discord::Webhook->new() };
like($@, qr/^PARAMETER ERROR:/, "Empty constructor");

eval { WebService::Discord::Webhook->new('https://discord.com/') };
like($@, qr/^PARAMETER ERROR:/, "Bad URL");

eval { WebService::Discord::Webhook->new(url => 'https://discord.com/', id => '223704706495545344') };
like($@, qr/^PARAMETER ERROR:/, "Mixed URL and ID");

# try the old URL format
ok(
  WebService::Discord::Webhook->new(
'https://discordapp.com/api/webhooks/223704706495545344/3d89bb7572e0fb30d8128367b3b1b44fecd1726de135cbe28a41f8b2f777c372ba2939e72279b94526ff5d1bd4358d65cf11/'
  ),
  "Create webhook object (old URL)"
);

# New URL format.
ok(
  $webhook = WebService::Discord::Webhook->new(
url => 'https://discord.com/api/webhooks/223704706495545344/3d89bb7572e0fb30d8128367b3b1b44fecd1726de135cbe28a41f8b2f777c372ba2939e72279b94526ff5d1bd4358d65cf11/'
  ),
  "Create webhook object"
);

# check correct parsing of ID and token
is( $webhook->{id}, '223704706495545344', 'Parsed id OK' );
is(
  $webhook->{token},
'3d89bb7572e0fb30d8128367b3b1b44fecd1726de135cbe28a41f8b2f777c372ba2939e72279b94526ff5d1bd4358d65cf11',
  'Parsed token OK'
);

## METHODS
# try some bad methods to see if we validated parameters.
#eval { $webhook->get() };
#like($@, qr/^HTTP ERROR:/, "get() with bad URL");

eval { $webhook->modify( password => 'password' ) };
like($@, qr/^PARAMETER ERROR:/, "modify() with no useful parameters");
eval { $webhook->modify( avatar => 'webhook.t' ) };
like($@, qr/^PARAMETER ERROR:/, "modify() with invalid image");
#eval { $webhook->modify( name => 'Webhook' ) };
#like($@, qr/^HTTP ERROR:/, "modify() with bad URL");

#eval { $webhook->destroy() };
#like($@, qr/^HTTP ERROR:/, "destroy() with bad URL");

eval { $webhook->execute( tts => 1 ) };
like($@, qr/^PARAMETER ERROR:/, "execute() with no useful parameters");
eval { $webhook->execute( file => 'webhook.t', embed => {} ) };
like($@, qr/^PARAMETER ERROR:/, "execute() with invalid mixed parameters");
#eval { $webhook->execute( content => 'content' ) };
#like($@, qr/^HTTP ERROR:/, "execute() with bad URL");

#eval { $webhook->execute_slack( '{"text":"text"}' ) };
#like($@, qr/^HTTP ERROR:/, "execute_slack() with bad URL");

#eval{ $webhook->execute_github( event => 'event', json => '{}' ) };
#like($@, qr/^HTTP ERROR:/, "execute_github() with bad URL");
