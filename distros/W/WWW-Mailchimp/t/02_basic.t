use Test::More;

BEGIN { use_ok('WWW::Mailchimp'); };

my $apikey = $ENV{MAILCHIMP_APIKEY} || 'bogus-us1';

my $mailchimp = WWW::Mailchimp->new( apikey => $apikey );
isa_ok($mailchimp, 'WWW::Mailchimp');
isa_ok($mailchimp->ua, 'LWP::UserAgent');
is($mailchimp->api_url, 'https://' . $mailchimp->datacenter . '.api.mailchimp.com/1.3/');

done_testing;
