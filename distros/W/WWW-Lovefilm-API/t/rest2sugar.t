#!perl -T

use strict;
use warnings;
use Test::More tests => 18;
use WWW::Lovefilm::API;
$|=1;


sub test_url {
  my $lovefilm = shift;
  my $url = shift;
  my $sugar = shift;
  my $params = shift || '';
  my ($rest, $submit) = $lovefilm->rest2sugar($url);
  is( $rest, '$lovefilm->REST->'.$sugar, "[$sugar] sugar" )
      or diag("$rest ne " . '$lovefilm->REST->'.$sugar);
  is( $submit, sprintf('$lovefilm->Get(%s)',$params), "[$sugar] submit" );
  eval "$rest";
  my ($base) = split '\?', $url;
  is( $lovefilm->url, $base, "[$sugar] reverse matches" ) or diag("privateapi = " . $lovefilm->privateapi);
}

foreach my $privateapi (0,1) {
    my $baseurl  = $privateapi ? 'http://api.lovefilm.com' : 'http://openapi.lovefilm.com';
    my $lovefilm = WWW::Lovefilm::API->new({
      user_id    => 'T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-',
      privateapi => $privateapi,
    });

    # these URLs may have no link to the URLs specified by teh API itself, it is just testing URL creation
    test_url($lovefilm, "${baseurl}/catalog/title/18704531",
            q{Catalog->Title('18704531')} );

    test_url($lovefilm, "${baseurl}/users/T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-/queues/instant",
            'Users->Queues->Instant' );

    test_url($lovefilm, "${baseurl}/users/T1tareQFowlmc8aiTEXBcQ5aed9h_Z8zdmSX1SnrKoOCA-/queues/disc?feed_token=T1u.tZSbY9311F5W0C5eVQXaJ49.KBapZdwjuCiUBzhoJ_.lTGnmES6JfOZbrxsFzf&oauth_consumer_key=v9s778n692e9qvd83wfj9t8c&output=atom&sort=date_added",
            'Users->Queues->Disc',
            q{'feed_token' => 'T1u.tZSbY9311F5W0C5eVQXaJ49.KBapZdwjuCiUBzhoJ_.lTGnmES6JfOZbrxsFzf', 'oauth_consumer_key' => 'v9s778n692e9qvd83wfj9t8c', 'output' => 'atom', 'sort' => 'date_added'},
    );

}
