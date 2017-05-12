use Test::More tests => 2;
use Test::Exception;
use IO::Socket::INET;
use LWP::UserAgent;
use Data::Dumper;

require_ok( 'WebService::SendInBlue' );

SKIP: {
  skip "No API KEY", 1 unless $ENV{'SENDINBLUE_API_KEY'};

  my $a = WebService::SendInBlue->new('api_key'=> $ENV{'SENDINBLUE_API_KEY'});

  my $processes = $a->processes();

  ok($processes->{'code'} eq 'success', "Successful response");
}
