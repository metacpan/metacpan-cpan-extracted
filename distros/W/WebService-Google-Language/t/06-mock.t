#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

use WebService::Google::Language;

use constant REFERER => 'http://example.com/';



#
#  define classes for mock objects
#

package JSON::Mock;
use base 'JSON';

sub decode { die "mocked JSON error\n" }

package LWP::UserAgent::Mock;
use base 'LWP::UserAgent';

use HTTP::Response ();

sub get { HTTP::Response->new(503, 'mocked HTTP error') }

sub post { HTTP::Response->new(200) }



#
#  the tests
#

package main;

my $service = WebService::Google::Language->new(
  REFERER,
  key  => 'your-api-key',
  json => JSON::Mock->new,
  ua   => LWP::UserAgent::Mock->new,
);

eval { $service->translate('Hallo Welt') };
like   $@, qr'^An HTTP error occured', 'mock HTTP error';

like   $@, qr'\bkey=your-api-key\b', 'API key';

eval { $service->translate('Hallo Welt' . ' ' x 1963 . '!') };
like   $@, qr/^Couldn't parse response/, 'URL max length (translate) / mock JSON error';

eval { $service->translate('Hallo Welt' . ' ' x 4990 . '!') };
like   $@, qr'^Google does not allow', 'text max length';

eval { $service->detect('Hallo Welt' . ' ' x 1981 . '!') };
like   $@, qr'length of.* URL.* exceeds.* maximum', 'URL max length (detect)';
