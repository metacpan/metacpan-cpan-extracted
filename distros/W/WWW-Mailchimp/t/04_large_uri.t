use strict;
use warnings;
use Test::More;
use Test::Fatal qw(lives_ok);

BEGIN {
  plan skip_all => '$ENV{MAILCHIMP_APIKEY} not set, skipping live tests' unless defined $ENV{MAILCHIMP_APIKEY};

  plan tests => 3;
  use_ok('WWW::Mailchimp');
}

my $apikey = $ENV{MAILCHIMP_APIKEY};
my $mailchimp = WWW::Mailchimp->new( apikey => $apikey );

# get a list id
my $lists = $mailchimp->lists;
my $list_id = $lists->{data}->[0]->{id};

# really large html body
my $html = '<html><body>' . ( '<p>hello world<p>' x 400 ) . '</body></html>';

# create an html campaign
my $campaignCreate = '';

lives_ok {
  my $result = $mailchimp->campaignCreate(
    type    => 'regular',
    options => {
      list_id       => $list_id,
      subject       => 'WWW::Mailchimp 04_large_uri.t',
      from_email    => 'elemmakil@gondolin.gov',
      from_name     => 'Elemmakil',
      inline_css    => 1,
      generate_text => 1,
    },
    content => { html => $html },
  );
  $campaignCreate = $result;
} 'no malformed JSON string';

like($campaignCreate, qr/\w+/, 'returns campaign_id');

# cleanup
my $campaigns = $mailchimp->campaigns(filters => {list_id => $list_id});
for my $cc ( @{ $campaigns->{data} } ) {
    if ( $cc->{subject} && $cc->{subject} =~ /WWW::Mailchimp 04_large_uri/ ) {
        diag("* cleaning up $cc->{subject}\n");
        $mailchimp->campaignDelete(cid => $cc->{id});
    }
}

done_testing;
