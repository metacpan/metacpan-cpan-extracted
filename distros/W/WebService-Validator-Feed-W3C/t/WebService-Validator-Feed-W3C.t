# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-Validator-CSS-W3C.t'

#########################

use lib qw(../lib);
use Test;
BEGIN { plan tests => 10 }
use WebService::Validator::Feed::W3C;
# Test new
my $val = WebService::Validator::Feed::W3C->new;
ok(ref($val), 'WebService::Validator::Feed::W3C',
  "The object should be a WebService::Validator::Feed::W3C but isn't");

# Test a simple validate succeeds in the hitting the server
{
  ok($val->validate(uri => 'http://www.w3.org/2003/05/Software/Overview.rss'));
}

# Test that a valid feed send through "string" is regarded as valid
{
  my $content = <<'VALID';
<rss version="2.0">
<channel>
<title>Valid link</title>
<description>valid item link (http)</description>
<link>http://purl.org/rss/2.0/</link>
<item>
<title>Valid link</title>
<link>http://purl.org/rss/2.0/#item</link>
</item>
</channel>
</rss>
VALID

  ok($val->validate(string => $content));
  ok($val->is_valid);
  ok(scalar $val->errors, undef, "No errors were returned");
  ok(ref $val->warnings, 'HASH', "Warnings were returned");
}

# Test that an invalid feed send through "string" is regarded as invalid
{
  sleep(1); # Be nice to the validator
 
  my $content = <<'INVALID';
  <rss version="2.0">
  <channel>
  <title>Invalid link</title>
  <description>item link must be full URL, including protocol</description>
  <link>http://purl.org/rss/2.0/</link>
  <item>
  <title>Invalid link</title>
  <link>purl.org/rss/2.0/#item</link>
  </item>
  </channel>
  </rss>
INVALID
  
  ok($val->validate(string => $content));
  
  ok(!$val->is_valid);
  ok(scalar $val->errors > 0);
  ok(scalar $val->warnings > 0);
}
