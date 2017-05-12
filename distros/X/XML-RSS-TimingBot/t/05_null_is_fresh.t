require 5;
use strict;
use Test;

#sub XML::RSS::TimingBot::DEBUG(){3}
use XML::RSS::TimingBot;

BEGIN { plan tests => 10 }

print "# Using XML::RSS::TimingBot v$XML::RSS::TimingBot::VERSION\n";
ok 1;
print "# Hi, I'm ", __FILE__, "\n";

my $ua = XML::RSS::TimingBot->new;

use HTTP::Request;
my $now = time();
my $not_until = $now + 1234;
my $null = $ua->_rss_agent_null_response(
  HTTP::Request->new('GET', 'http://blackholio.int'),
  $not_until
);

my $out = $null->as_string;
$out =~ s/^/# /mg;
print "# Nully <<\n$out# >>\n#\n";

# Verify that we faked out all the cachy things nicely

ok $null;  #sanity
ok ! $null->is_error;
ok $null->request;
ok $null->expires;
ok $null->date;
ok $null->is_fresh;
my $lifetime = $null->freshness_lifetime;
print "# Freshness lifetime: $lifetime\n";
ok $lifetime > 1230;
ok $lifetime < 1240;

print "# ~ Bye! ~ \n";
ok 1;

