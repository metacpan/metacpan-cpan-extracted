#!perl -T

use strict;
use warnings;
use Test::More tests => 9;
use WWW::Netflix::API;
$|=1;

my $netflix = WWW::Netflix::API->new({
  user_id => 'T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-',
});
my $base_url = $netflix->{base_url};

sub test_url {
  my $netflix = shift;
  my $url = shift;
  my $sugar = shift;
  my $params = shift || '';
  my ($rest, $submit) = $netflix->rest2sugar($url);
  is( $rest, '$netflix->REST->'.$sugar, "[$sugar] sugar" );
  is( $submit, sprintf('$netflix->Get(%s)',$params), "[$sugar] submit" );
  eval "$rest";
  my ($base) = split '\?', $url;
  is( $netflix->url, $base, "[$sugar] reverse matches" );
}

test_url($netflix, 'http://' . $base_url . '/users/T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-/queues/instant',
	'Users->Queues->Instant' );

test_url($netflix, 'http://' . $base_url . '/users/T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-/queues/disc?feed_token=T1u.tZSbY9311F5W0C5eVQXaJ49.KBapZdwjuCiUBzhoJ_.lTGnmES6JfOZbrxsFzf&oauth_consumer_key=v9s778n692e9qvd83wfj9t8c&output=atom&sort=date_added',
	'Users->Queues->Disc',
	q{'feed_token' => 'T1u.tZSbY9311F5W0C5eVQXaJ49.KBapZdwjuCiUBzhoJ_.lTGnmES6JfOZbrxsFzf', 'oauth_consumer_key' => 'v9s778n692e9qvd83wfj9t8c', 'output' => 'atom', 'sort' => 'date_added'},
);

test_url($netflix, 'http://' . $base_url . '/catalog/titles/movies/18704531',
	q{Catalog->Titles->Movies('18704531')} );

