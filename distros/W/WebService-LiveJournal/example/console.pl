use strict;
use warnings;
use WebService::LiveJournal;

my $client = WebService::LiveJournal->new(
  server => 'www.livejournal.com',
  username => do {
    print "user: ";
    my $user = <STDIN>;
    chomp $user;
    $user;
  },
  password => do {
    print "pass: ";
    my $pass = <STDIN>;
    chomp $pass;
    $pass;
  },
);

while(1)
{
  print "> ";
  my $command = <STDIN>;
  unless(defined $command)
  {
    print "\n";
    last;
  }
  chomp $command;
  $client->batch_console_commands(
    [ split /\s+/, $command ],
    sub {
      foreach my $line (@_)
      {
        my($type, $text) = @$line;
        printf "%8s : %s\n", $type, $text;
      }
    }
  );
}
