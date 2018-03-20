use strict;
use warnings;

use FindBin;
use Test::LWP::UserAgent;
use Test::More;

use lib "$FindBin::Bin/../lib/";

my $mock = Test::LWP::UserAgent->new(network_fallback => 0);

my @http_headers = (
    'Content-Type'          => 'text/json',
    'X-Ratelimit-Limit'     => 42,
    'X-Ratelimit-Remaining' => 42,
    'X-Ratelimit-Reset'     => 42
);

# Mocking mapping begin
$mock->map_response(
    qr{/v2/contacts},
    HTTP::Response->new(
        '200', 'OK', \@http_headers,
        '{
  "contacts": [
    {
      "iden": "iden_asmithee",
      "name": "Alan Smithee",
      "created": 1399011660.4298899,
      "modified": 1399011660.42976,
      "email": "alan.smithee@domain.com",
      "email_normalized": "alan.smithee@domain.com",
      "active": true
    },
    {
      "iden": "iden_johndoe",
      "name": "John Doe",
      "created": 1399011660.4298899,
      "modified": 1399011660.42976,
      "email": "john.doe@domain.com",
      "email_normalized": "john.doe@domain.com",
      "active": true
    }
  ]
    }'
    )
);

$mock->map_response(
    qr{/v2/devices},
    HTTP::Response->new(
        '200', 'OK', \@http_headers,
        '{
  "devices": [
    {
      "iden": "iden_nexus5",
      "push_token": "push_token_nexus5",
      "app_version": 74,
      "fingerprint": "fingerprint",
      "active": true,
      "nickname": "Google Nexus 5",
      "manufacturer": "Google",
      "type": "android",
      "created": 1394748080.0139201,
      "modified": 1399008037.8487799,
      "model": "NEXUS5",
      "pushable": true
    },
    {
      "iden": "iden_nexus6",
      "push_token": "push_token_nexus6",
      "app_version": 74,
      "fingerprint": "fingerprint",
      "active": true,
      "nickname": "Google Nexus 6",
      "manufacturer": "Google",
      "type": "android",
      "created": 1394748080.0139201,
      "modified": 1399008037.8487799,
      "model": "NEXUS6",
      "pushable": true
    }
  ]
}'
    )
);

# Mocking mapping begin

use WWW::PushBullet;

my $pb = WWW::PushBullet->new(
    {
        ua     => $mock,
        apikey => '123456',
        debug  => 1
    }
);

my $contacts = $pb->contacts();

ok(
    $contacts->[0]->{name} eq 'Alan Smithee'
        && $contacts->[1]->{name} eq 'John Doe',
    '$pb->contacts()'
  );

my $devices = $pb->devices();

ok(
    $devices->[0]->{nickname} eq 'Google Nexus 5'
        && $devices->[1]->{nickname} eq 'Google Nexus 6',
    '$pb->contacts()'
  );

done_testing(2);

=head1 AUTHOR

Sebastien Thebert <www-pushbullet@onetool.pm>

=cut
