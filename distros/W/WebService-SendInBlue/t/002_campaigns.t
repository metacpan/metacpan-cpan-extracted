use Test::More tests => 3;
use Test::Exception;
use IO::Socket::INET;
use LWP::UserAgent;

require_ok( 'WebService::SendInBlue' );

SKIP: {
  skip "No API KEY", 2 unless $ENV{'SENDINBLUE_API_KEY'};

  my $a = WebService::SendInBlue->new('api_key'=> $ENV{'SENDINBLUE_API_KEY'});

  my $campaigns_list = $a->campaigns();
  ok($campaigns_list->is_success == 1, "Get campaigns list");
  
  my $file_url = $a->campaign_recipients_file_url($campaigns_list->data->{'campaign_records'}[-1]{'id'}, 'all');
  ok($file_url->{'code'} eq 'success', "Get file url");
}
