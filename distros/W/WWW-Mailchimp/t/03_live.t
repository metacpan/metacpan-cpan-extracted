use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => '$ENV{MAILCHIMP_APIKEY} not set, skipping live tests' unless defined $ENV{MAILCHIMP_APIKEY}; 

  plan tests => 6;
  use_ok('WWW::Mailchimp');
}

my $apikey = $ENV{MAILCHIMP_APIKEY};
my $mailchimp = WWW::Mailchimp->new( apikey => $apikey );
isa_ok($mailchimp, 'WWW::Mailchimp');
isa_ok($mailchimp->ua, 'LWP::UserAgent');
is($mailchimp->api_url, 'https://' . $mailchimp->datacenter . '.api.mailchimp.com/1.3/');

my %info1 = qw(EMAIL foo@foobar.com EMAIL_TYPE text);
my %info2 = qw(EMAIL baz@quux.com EMAIL_TYPE text);
my @batch = ( \%info1, \%info2 );

my $lists = $mailchimp->lists;
my $list_id = $lists->{data}->[0]->{id};

my $listBatchSubscribe_expected = { add_count => 2, error_count => 0, errors => [], update_count => 0 };
my $listBatchSubscribe = $mailchimp->listBatchSubscribe( id => $list_id, batch => \@batch, double_optin => 0, send_welcome => 0, update_existing => 1 );
is_deeply( $listBatchSubscribe, $listBatchSubscribe_expected, 'listBatchSubscribe succeeded' );

my $listBatchUnsubscribe_expected = { success_count => 2, error_count => 0, errors => [] };
my $listBatchUnsubscribe = $mailchimp->listBatchUnsubscribe( id => $list_id, emails => [ 'foo@foobar.com', 'baz@quux.com' ], delete_member => 1, send_goodbye => 0, send_notify => 0 );
is_deeply( $listBatchUnsubscribe, $listBatchUnsubscribe_expected, 'listBatchUnsubscribe succeeded' );

done_testing;
