use strict;
use warnings;

use Test::More;
use lib 't/lib';

use WWW::MailboxOrg;
use WWW::MailboxOrg::MockIO;

# Sauberer Ausgangszustand: alle Produktiv-ENV entfernen, dann gezielt
# einzelne WWW_MAILBOXORG_* per local setzen, um den Fallback zu prüfen.
delete @ENV{ grep { /^WWW_MAILBOXORG_/ } keys %ENV };

subtest 'user/password aus ENV' => sub {
  local $ENV{WWW_MAILBOXORG_USER}     = 'env-user@example.com';
  local $ENV{WWW_MAILBOXORG_PASSWORD} = 'env-secret';

  my $client = WWW::MailboxOrg->new( io => WWW::MailboxOrg::MockIO->new );
  is( $client->user,     'env-user@example.com', 'user aus WWW_MAILBOXORG_USER' );
  is( $client->password, 'env-secret',           'password aus WWW_MAILBOXORG_PASSWORD' );
};

subtest 'base_url aus ENV' => sub {
  local $ENV{WWW_MAILBOXORG_USER}     = 'env-user@example.com';
  local $ENV{WWW_MAILBOXORG_PASSWORD} = 'env-secret';
  local $ENV{WWW_MAILBOXORG_BASE_URL} = 'https://api.example.test/v1';

  my $client = WWW::MailboxOrg->new( io => WWW::MailboxOrg::MockIO->new );
  is( $client->base_url, 'https://api.example.test/v1', 'base_url aus WWW_MAILBOXORG_BASE_URL' );
};

subtest 'token aus ENV' => sub {
  local $ENV{WWW_MAILBOXORG_USER}     = 'env-user@example.com';
  local $ENV{WWW_MAILBOXORG_PASSWORD} = 'env-secret';
  local $ENV{WWW_MAILBOXORG_TOKEN}    = 'env-session-token';

  my $client = WWW::MailboxOrg->new( io => WWW::MailboxOrg::MockIO->new );
  is( $client->token, 'env-session-token', 'token aus WWW_MAILBOXORG_TOKEN' );
};

subtest 'explizite Argumente schlagen ENV' => sub {
  local $ENV{WWW_MAILBOXORG_USER}     = 'env-user@example.com';
  local $ENV{WWW_MAILBOXORG_PASSWORD} = 'env-secret';
  local $ENV{WWW_MAILBOXORG_BASE_URL} = 'https://api.example.test/v1';
  local $ENV{WWW_MAILBOXORG_TOKEN}    = 'env-session-token';

  my $client = WWW::MailboxOrg->new(
    user     => 'arg-user@example.com',
    password => 'arg-secret',
    base_url => 'https://api.arg.test/v1',
    token    => 'arg-token',
    io       => WWW::MailboxOrg::MockIO->new,
  );
  is( $client->user,     'arg-user@example.com',    'Argument user gewinnt' );
  is( $client->password, 'arg-secret',              'Argument password gewinnt' );
  is( $client->base_url, 'https://api.arg.test/v1', 'Argument base_url gewinnt' );
  is( $client->token,    'arg-token',               'Argument token gewinnt' );
};

subtest 'base_url Default ohne ENV' => sub {
  my $client = WWW::MailboxOrg->new(
    user     => 'arg-user@example.com',
    password => 'arg-secret',
    io       => WWW::MailboxOrg::MockIO->new,
  );
  is( $client->base_url, 'https://api.mailbox.org/v1', 'Default base_url ohne ENV' );
};

done_testing;
