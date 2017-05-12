use strict;
use warnings;
use WebService::LiveJournal;

print "WARNING WARNING WARNING\n";
print "this will remove all entries in your LiveJournal account\n";
print "this probably cannot be undone\n";
print "WARNING WARNING WARNING\n";

print "user: ";
my $user = <STDIN>;
chomp $user;
print "pass: ";
my $password = <STDIN>;
chomp $password;

my $client = WebService::LiveJournal->new(
  server => 'www.livejournal.com',
  username => $user,
  password => $password,
);

print "$client\n";

my $count = 0;
while(1)
{
  my $event_list = $client->get_events('lastn', howmany => 50);
  last unless @{ $event_list } > 0;
  foreach my $event (@{ $event_list })
  {
    print "rm: ", $event->subject, "\n";
    $event->delete;
    $count++;
  }
}

print "$count entries deleted\n";
