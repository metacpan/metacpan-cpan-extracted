package WebService::Cmis::Test::Client;
use base qw(WebService::Cmis::Test);
use Test::More;

use strict;
use warnings;

use Error qw(:try);
use WebService::Cmis::ClientException ();

my $connection = $ENV{CMIS_CONNECTION} || $WebService::Cmis{DefaultConnection};
diag("connection = '$connection' ... set the enviromnent variable CMIS_CONNECTION to a different to test against a different backend");


sub test_login : Test(1) {
  my $this = shift;

  my $client = $this->getClient;
  my $ticket = $client->login;

  ok(defined $ticket);
}

sub test_logout : Test(1) {
  my $this = shift;

  my $client = $this->getClient;
  my $ticket = $client->login;

  ok(defined $ticket);

  $client->logout;
  $this->{client} = undef;

  # SMELL: how can we test we are logged out?
}


sub test_reuse_ticket : Test(2) {
  my $this = shift;
    
  my $client1 = $this->getClient;
  my $ticket1 = $client1->login;

  SKIP: {
    skip "no ticket authentication", 2 unless $ticket1;

    note("ticket1=$ticket1");

    my $client2 = $this->getClient();
    my $ticket2 = $client2->login(ticket=>$ticket1);
    note("ticket2=$ticket2");

    ok($ticket2);

    is($ticket1, $ticket2);
  }
}

sub test_cant_reuse_after_logout : Test(1) {
  my $this = shift;

  my $client = $this->getClient;

  $client->logout;
  $this->{client} = undef;

  my $error = 0;
  try {
    $client->getRepositories;
  } catch WebService::Cmis::ClientException with {
    $error = 1;
    note("it is okay to get a ".shift);
  };

  ok($error, "we should not be able to use the client after having logged out");
}

sub test_Client_getRepositories : Test(3) {
  my $this = shift;

  my $client = $this->getClient;
  my $repositories = $client->getRepositories;

  my $nrRepos = scalar(keys %$repositories);
  note("found $nrRepos repository(ies)");
  ok(scalar($nrRepos) > 0) or diag("can't find at least one repository");

  my ($repo) = (values %$repositories);
  my $info = $repo->getRepositoryInfo;

  note("available info: ".join(", ", keys %$info));

  # SMELL: what's the absolute minimum?
  foreach my $key (qw(repositoryName repositoryId)) {
    note("$key=$info->{$key}");
    ok(defined $info->{$key});
  }
}

sub test_Client_getDefaultRepository : Test(2) {
  my $this = shift;

  my $repo = $this->getRepository;

  ok(defined $repo) or diag("can't find default repository");
  isa_ok($repo, "WebService::Cmis::Repository");
}

1;
