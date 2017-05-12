#!perl -T

use Test::More;
use WWW::VieDeMerde;

BEGIN { my $plan = 0; }
plan tests => $plan;

BEGIN { $plan += 3; }
my @xml = <DATA>;
my $xml = join("\n", @xml);

my $fml = WWW::VieDeMerde->new();
my $code = $fml->_errors($xml);
my @errors = @{$fml->errors()};
is($code, 1, 'Good error code');
is($errors[0], 'Invalid API key', 'First error found');
is($errors[1], 'Variable language is missing', 'Second error found');

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<root><active_key>readonly</active_key><code>0</code><pubdate>2009-08-30T15:21:49+02:00</pubdate><language/><errors><error>Invalid API key</error><error>Variable language is missing</error></errors></root>
