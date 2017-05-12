
require 5;
use strict;
use Test;

sub XML::RSS::TimingBotDBI::DEBUG(){10}
use XML::RSS::TimingBotDBI;
use XML::RSS::TimingBot;
use DBI;

BEGIN { plan tests => 57 }

print "# Using XML::RSS::TimingBotDBI v$XML::RSS::TimingBotDBI::VERSION\n";
print "# Using XML::RSS::TimingBot v$XML::RSS::TimingBot::VERSION\n";
print "# Using DBI v$DBI::VERSION\n";
ok 1;
print "# Hi, I'm ", __FILE__, " ...\n";

my $dbh = DBI->connect(
  # Fill in the following:

  'dbi:ODBC:driver={MySQL};Server=localhost;database=torgox;',
  'aoeaoe', 'sntsnt',

  #{ AutoCommit => 0 }
 ) || die "Can't connect: $DBI::errstr\nAborting";
print "# OK, got a dbi connection, pinging...\n";
ok $dbh->ping or die "Couldn't ping";

my $table = "testrsua";
print "# My test table will be called \"$table\"\n";

ok $dbh->do("drop table if exists $table");
ok $dbh->ping or die "Couldn't ping";

my $ua;
sub new_ua {
  print "# New ua... at ", join(' ', caller), "\n";
  $ua = XML::RSS::TimingBotDBI->new;
  require File::Spec;
  $ua->{'_dbpath'} = File::Spec->curdir;
  $ua->rssagent_dbh($dbh);
  $ua->rssagent_table($table);
}

my $rand = sprintf "%06x", int(rand(0x1000000));
print "# Randomness nugget: \"$rand\"\n";

my $url1 = "http://www.blackholio.int/whump/$rand/things.rss";
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


my $url2 = "http://thing.thingy.thunk:89/$rand/zorchdat";
my $url3 = "http://thing.thingy.thunk:89/$rand/zorchbong";

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


ok $dbh->do("drop table $table");

print "# ~ Bye! ~ \n";
ok 1;

