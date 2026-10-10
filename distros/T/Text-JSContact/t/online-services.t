#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

# An OnlineService survives a round trip through vCard: IMPP is written with
# the RFC 9554 SERVICE-TYPE and USERNAME parameters, and read back from them.
for my $case (
  [ 'service and user'      => { service => 'Mastodon', user => 'alice' } ],
  [ 'service and uri'       => { service => 'XMPP', uri => 'xmpp:alice@example.com' } ],
  [ 'service, uri and user' => { service => 'XMPP', uri => 'xmpp:alice@example.com', user => 'alice' } ],
) {
  my ($desc, $svc) = @$case;
  my $card = {
    '@type'        => 'Card',
    version        => '1.0',
    uid            => 'urn:uuid:5b6e9cba-0000-4000-8000-000000000001',
    name           => { full => 'Alice' },
    onlineServices => { s1 => { '@type' => 'OnlineService', %$svc } },
  };

  my $back = vcard_to_jscontact(jscontact_to_vcard($card));
  is_deeply($back->{onlineServices}{s1}, { '@type' => 'OnlineService', %$svc }, $desc)
    or diag explain $back->{onlineServices};
}

done_testing;
