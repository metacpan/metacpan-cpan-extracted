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

print "$client\n";

if($client->fastserver)
{
  print "fast server\n";
}
else
{
  print "slow server\n";
}
