#!perl -T

use strict;
use warnings;

use Test::More 0.62;

use WebService::Google::Language;

use constant REFERER => 'http://example.com/';

my %args = (
  key  => 'your-api-key',
  src  => 'en',
  dest => 'de',
);

plan tests => 2 + keys %args;

my $service = eval { WebService::Google::Language->new(REFERER) };

isa_ok $service, 'WebService::Google::Language'
  or BAIL_OUT q{Can't create a WebService::Google::Language object};

eval { WebService::Google::Language->new };
ok $@, 'Construction failed as expected due to missing mandatory parameter';

$service = WebService::Google::Language->new(REFERER, %args);

for (sort keys %args) {
  is $service->{$_}, $args{$_}, "'$_' set";
}
