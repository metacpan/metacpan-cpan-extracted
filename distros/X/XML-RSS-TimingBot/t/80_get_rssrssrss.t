
require 5;
use strict;
use Test;

#sub XML::RSS::TimingBot::DEBUG(){5}
use XML::RSS::TimingBot;

BEGIN { plan tests => 15 }

print "# Using XML::RSS::TimingBot v$XML::RSS::TimingBot::VERSION\n";
ok 1;
print "# Hi, I'm ", __FILE__, " ...\n";

my $ua;

sub new_ua {
  print "# New ua... at ", join(' ', caller), "\n";
  $ua = XML::RSS::TimingBot->new;
  require File::Spec;
  $ua->{'_dbpath'} = File::Spec->curdir;
}

my $url = "http://interglacial.com/rss/rss.rss?test$^T";
{my $more = 100;
  sub another_url { return $url . ($more++); }
}

my $response;

new_ua();
$response = $ua->get( $url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '200';

$ua->commit;

new_ua();
$response = $ua->get( $url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '304';
ok $response->status_line, '/change until/';

$ua->commit;

new_ua();
$response = $ua->get( $url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '304';
ok $response->status_line, '/change until/';


new_ua();
$response = $ua->get( $url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '304';
ok $response->status_line, '/change until/';


$response = $ua->get( another_url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '200';

$response = $ua->get( another_url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '200';


new_ua();
$response = $ua->get( $url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '304';
ok $response->status_line, '/change until/';

$ua->commit;



print "# Now with time-travel...\n";
new_ua();
$ua->{'_now_hack'} = time() + 400 * 24 * 60 * 60; # more than a year from now
$response = $ua->get( $url );
print "# Got: ", $response->status_line, "\n";
ok $response->code, '304';
ok $response->status_line !~ m/change until/;


print "# ~ Bye! ~ \n";
ok 1;

