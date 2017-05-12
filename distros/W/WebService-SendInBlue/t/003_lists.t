use Test::More tests => 3;
use Test::Exception;
use IO::Socket::INET;
use LWP::UserAgent;
use Data::Dumper;

require_ok( 'WebService::SendInBlue' );

SKIP: {
  skip "No API KEY", 2 unless $ENV{'SENDINBLUE_API_KEY'};

  my $a = WebService::SendInBlue->new('api_key'=> $ENV{'SENDINBLUE_API_KEY'});

  my $lists = $a->lists();

  ok($lists->{'code'} eq 'success', "Successful response");

  if (scalar($lists->{'data'}) == 0) {
    skip "No lists to get users", 1;
  }
  else {
    my $list_id = $lists->{'data'}[0]{'id'};
    my $users = $a->lists_users(lists_ids=>[$list_id], page=>1, page_limit=>500);
    ok($users->{'code'} eq 'success', "Successful response");
  }
}
