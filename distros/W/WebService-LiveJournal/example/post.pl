use strict;
use warnings;
use WebService::LiveJournal;

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

print "subject: ";
my $subject = <STDIN>;
chomp $subject;

print "content: (^D or EOF when done)\n";
my @lines = <STDIN>;
chomp @lines;

my $event = $client->create(
  subject => $subject,
  event => join("\n", @lines),
);

$event->update;

print "posted $event with $client\n";
print "itemid = ", $event->itemid, "\n";
print "url    = ", $event->url, "\n";
print "anum   = ", $event->anum, "\n";
