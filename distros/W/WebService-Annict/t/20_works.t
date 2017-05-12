use strict;
use Test::More 0.98;
use LWP::UserAgent;
use HTTP::Headers;
use WebService::Annict::Works;

my $access_token = $ENV{ANNICT_ACCESS_TOKEN};

my $ua = LWP::UserAgent->new(
  agent => "Perl5 WebService::Annict::Works",
  default_headers => HTTP::Headers->new(
    "Content-Type" => "application/json",
    Accept         => "application/json",
    Authorization  => "Bearer $access_token",
  ),
);

my $works = WebService::Annict::Works->new($ua);
isa_ok $works, "WebService::Annict::Works";
isa_ok $works->{ua}, "LWP::UserAgent";

# tests for actual API request
if ($access_token) {
  my $response = $works->get( filter_title => 'shirobako' );
  is $response->code, 200, '$works->get fetch item successfully';
}

done_testing;
