use strict;
use warnings;

use Test::More;
use WWW::MailboxOrg;

# Live-Integrationstest gegen die echte API. Wird nur ausgeführt, wenn die
# TEST_WWW_MAILBOXORG_* Credentials gesetzt sind — sonst übersprungen.
my $user     = $ENV{TEST_WWW_MAILBOXORG_USER};
my $password = $ENV{TEST_WWW_MAILBOXORG_PASSWORD};
my $base_url = $ENV{TEST_WWW_MAILBOXORG_BASE_URL};

plan skip_all =>
  'Set TEST_WWW_MAILBOXORG_USER and TEST_WWW_MAILBOXORG_PASSWORD to run live API tests'
  unless $user && $password;

my $client = WWW::MailboxOrg->new(
  user     => $user,
  password => $password,
  ( $base_url ? ( base_url => $base_url ) : () ),
);

$client->login;
ok( $client->token, 'login lieferte einen Session-Token' );

my $hello = $client->system->hello;
ok( $hello, 'system->hello lieferte eine Antwort' );

$client->logout;
ok( !$client->token, 'logout löschte den Session-Token' );

done_testing;
