
require 5;
use strict;
use Test;

#sub XML::RSS::TimingBot::DEBUG(){10}
use XML::RSS::TimingBot;

BEGIN { plan tests => 53 }

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

my $url1 = "http://www.blackholio.int/whump/" . int(rand(1_000_000)) . "/things.rss";
print "# My magic URL: $url1\n";

new_ua();
$ua->feed_set_last_modified($url1, "Whump Zizzle");
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";
$ua->commit;
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";

new_ua();
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";

new_ua();
$ua->feed_set_next_update($url1, "1234567890");
ok $ua->feed_get_next_update($url1), "1234567890";
$ua->commit;
print "# Next thing should come from the clean cache:\n";
ok $ua->feed_get_next_update($url1), "1234567890";

new_ua();
ok $ua->feed_get_next_update($url1), "1234567890";
ok $ua->feed_get_next_update($url1), "1234567890";
ok $ua->feed_get_next_update($url1), "1234567890";

# And make sure it didn't kill the older value:
new_ua();
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";


print "# Make sure uncommitted values don't get saved\n";
new_ua();
$ua->feed_set_next_update($url1, "187187187");
ok $ua->feed_get_next_update($url1), "187187187";
new_ua();
ok $ua->feed_get_next_update($url1), "1234567890";


print "# Now let's do a collision\n";
my $url2 = "http://thing.thingy.thunk:89/aaaaaaaaaaaaaaaaa/zorchdat";
my $url3 = "http://thing.thingy.thunk:89/aaaaaaaaaaaaaaaaa/zorchbong";
new_ua();
$ua->feed_set_last_modified($url2, "Kraa Ponk");
$ua->feed_set_next_update($url2, "987");
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_next_update($url2), "987";
$ua->commit;
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_next_update($url2), "987";
ok $ua->feed_get_next_update($url2), "987";

new_ua();
$ua->feed_set_last_modified($url3, "Skeez");
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_next_update($url2), "987";
ok $ua->feed_get_next_update($url2), "987";
$ua->commit;
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_next_update($url2), "987";
ok $ua->feed_get_next_update($url2), "987";
print "# Trying a redundant commit\n";
$ua->commit;
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_next_update($url2), "987";
ok $ua->feed_get_next_update($url2), "987";




new_ua();
ok $ua->feed_get_next_update($url1), "1234567890";
ok $ua->feed_get_last_modified($url1), "Whump Zizzle";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_next_update($url2), "987";
ok $ua->feed_get_last_modified($url2), "Kraa Ponk";
ok $ua->feed_get_last_modified($url3), "Skeez";
ok $ua->feed_get_next_update($url2), "987";

print "# ~ Bye! ~ \n";
ok 1;

