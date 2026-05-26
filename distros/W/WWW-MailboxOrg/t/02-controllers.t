use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib 't/lib';

use WWW::MailboxOrg;
use WWW::MailboxOrg::MockIO;

# Produktiv-ENV abklemmen, damit die Tests deterministisch bleiben
delete @ENV{ grep { /^WWW_MAILBOXORG_/ } keys %ENV };

sub make_client {
  my $mock = WWW::MailboxOrg::MockIO->new;
  my $client = WWW::MailboxOrg->new(
    user     => 'test@example.com',
    password => 'secret',
    io       => $mock,
  );
  return ( $client, $mock );
}

# ── API::System ──────────────────────────────────────────────────────────────

subtest 'API::System' => sub {
  my ( $client, $mock ) = make_client();

  $client->system->hello;
  is( $mock->last_call->method, 'hello', 'hello' );

  $client->system->test;
  is( $mock->last_call->method, 'test', 'test' );

  $client->system->capabilities;
  is( $mock->last_call->method, 'capabilities', 'capabilities' );
};

# ── API::Account ─────────────────────────────────────────────────────────────

subtest 'API::Account' => sub {
  my ( $client, $mock ) = make_client();

  $client->account->list;
  is( $mock->last_call->method, 'account.list', 'list' );

  $client->account->get( account => 'user@example.com' );
  is( $mock->last_call->method,              'account.get',      'get' );
  is( $mock->last_call->params->{account},   'user@example.com', 'get account param' );

  $client->account->add(
    account  => 'user@example.com',
    password => 'secret',
    plan     => 'basic',
  );
  is( $mock->last_call->method,           'account.add', 'add' );
  is( $mock->last_call->params->{plan},   'basic',       'add plan param' );

  $client->account->del( account => 'user@example.com' );
  is( $mock->last_call->method, 'account.del', 'del' );

  $client->account->set( account => 'user@example.com', plan => 'profi' );
  is( $mock->last_call->method,          'account.set', 'set' );
  is( $mock->last_call->params->{plan},  'profi',       'set plan param' );

  dies_ok {
    $client->account->add( account => 'not-an-email', password => 'x', plan => 'basic' );
  } 'add rejects invalid email';

  dies_ok {
    $client->account->add( account => 'u@example.com', password => 'x', plan => 'invalid-plan' );
  } 'add rejects invalid plan';

  dies_ok {
    $client->account->get;
  } 'get requires account';
};

# ── API::Domain ──────────────────────────────────────────────────────────────

subtest 'API::Domain' => sub {
  my ( $client, $mock ) = make_client();

  $client->domain->list;
  is( $mock->last_call->method, 'domain.list', 'list' );

  $client->domain->get( domain => 'example.com' );
  is( $mock->last_call->method,             'domain.get',  'get' );
  is( $mock->last_call->params->{domain},   'example.com', 'get domain param' );

  $client->domain->add(
    account  => 'admin@example.com',
    domain   => 'example.com',
    password => 'secret',
  );
  is( $mock->last_call->method, 'domain.add', 'add' );

  $client->domain->del( account => 'admin@example.com', domain => 'example.com' );
  is( $mock->last_call->method, 'domain.del', 'del' );

  $client->domain->set( domain => 'example.com', memo => 'test' );
  is( $mock->last_call->method, 'domain.set', 'set' );

  dies_ok {
    $client->domain->get( domain => 'not a valid domain!!!' );
  } 'get rejects invalid domain';

  dies_ok {
    $client->domain->get;
  } 'get requires domain';
};

# ── API::Mail ────────────────────────────────────────────────────────────────

subtest 'API::Mail' => sub {
  my ( $client, $mock ) = make_client();

  $client->mail->find( query => 'from:sender@example.com' );
  is( $mock->last_call->method,            'mail.find',             'find' );
  is( $mock->last_call->params->{query},   'from:sender@example.com', 'find query param' );

  $client->mail->list( folder => 'INBOX', unseen_only => 1 );
  is( $mock->last_call->method,             'mail.list', 'list' );
  is( $mock->last_call->params->{folder},   'INBOX',     'list folder param' );
  ok( $mock->last_call->params->{unseen_only},            'list unseen_only param' );

  dies_ok { $client->mail->find } 'find requires query';
};

# ── API::Mailinglist ──────────────────────────────────────────────────────────

subtest 'API::Mailinglist' => sub {
  my ( $client, $mock ) = make_client();

  $client->mailinglist->list;
  is( $mock->last_call->method, 'mailinglist.list', 'list' );

  $client->mailinglist->add(
    account  => 'admin@example.com',
    list     => 'news@example.com',
    password => 'secret',
  );
  is( $mock->last_call->method, 'mailinglist.add', 'add' );

  $client->mailinglist->get( account => 'admin@example.com', list => 'news@example.com' );
  is( $mock->last_call->method, 'mailinglist.get', 'get' );

  $client->mailinglist->del( account => 'admin@example.com', list => 'news@example.com' );
  is( $mock->last_call->method, 'mailinglist.del', 'del' );

  $client->mailinglist->set( account => 'admin@example.com', list => 'news@example.com' );
  is( $mock->last_call->method, 'mailinglist.set', 'set' );

  $client->mailinglist->add_member(
    account => 'admin@example.com',
    list    => 'news@example.com',
    email   => 'member@example.com',
  );
  is( $mock->last_call->method, 'mailinglist.add_member', 'add_member' );

  $client->mailinglist->del_member(
    account => 'admin@example.com',
    list    => 'news@example.com',
    email   => 'member@example.com',
  );
  is( $mock->last_call->method, 'mailinglist.del_member', 'del_member' );

  $client->mailinglist->list_members(
    account => 'admin@example.com',
    list    => 'news@example.com',
  );
  is( $mock->last_call->method, 'mailinglist.list_members', 'list_members' );
};

# ── API::Blacklist ────────────────────────────────────────────────────────────

subtest 'API::Blacklist' => sub {
  my ( $client, $mock ) = make_client();

  $client->blacklist->list( account => 'admin@example.com' );
  is( $mock->last_call->method, 'blacklist.list', 'list' );

  $client->blacklist->add( account => 'admin@example.com', email => 'spam@example.com' );
  is( $mock->last_call->method,           'blacklist.add',    'add' );
  is( $mock->last_call->params->{email},  'spam@example.com', 'add email param' );

  $client->blacklist->del( account => 'admin@example.com', email => 'spam@example.com' );
  is( $mock->last_call->method, 'blacklist.del', 'del' );

  dies_ok { $client->blacklist->list } 'list requires account';
};

# ── API::Spamprotect ──────────────────────────────────────────────────────────

subtest 'API::Spamprotect' => sub {
  my ( $client, $mock ) = make_client();

  $client->spamprotect->status( account => 'user@example.com' );
  is( $mock->last_call->method, 'spamprotect.status', 'status' );

  $client->spamprotect->set( account => 'user@example.com', active => 1 );
  is( $mock->last_call->method,             'spamprotect.set', 'set' );
  is( $mock->last_call->params->{active},   1,                 'set active param' );

  dies_ok { $client->spamprotect->status } 'status requires account';
  dies_ok { $client->spamprotect->set( account => 'x@x.com' ) } 'set requires active';
};

# ── API::Videochat ────────────────────────────────────────────────────────────

subtest 'API::Videochat' => sub {
  my ( $client, $mock ) = make_client();

  $client->videochat->status( account => 'user@example.com' );
  is( $mock->last_call->method, 'videochat.status', 'status' );

  $client->videochat->create_room( account => 'user@example.com', name => 'My Room' );
  is( $mock->last_call->method,          'videochat.create_room', 'create_room' );
  is( $mock->last_call->params->{name},  'My Room',               'create_room name param' );

  $client->videochat->list_rooms( account => 'user@example.com' );
  is( $mock->last_call->method, 'videochat.list_rooms', 'list_rooms' );

  $client->videochat->delete_room( account => 'user@example.com', name => 'My Room' );
  is( $mock->last_call->method, 'videochat.delete_room', 'delete_room' );

  dies_ok { $client->videochat->status } 'status requires account';
  dies_ok { $client->videochat->create_room( account => 'x@x.com' ) } 'create_room requires name';
};

# ── API::Backup ───────────────────────────────────────────────────────────────

subtest 'API::Backup' => sub {
  my ( $client, $mock ) = make_client();

  $client->backup->list( account => 'user@example.com' );
  is( $mock->last_call->method, 'backup.list', 'list' );

  $client->backup->create( account => 'user@example.com' );
  is( $mock->last_call->method, 'backup.create', 'create' );

  $client->backup->restore( account => 'user@example.com', backup => 'bak-id' );
  is( $mock->last_call->method,            'backup.restore', 'restore' );
  is( $mock->last_call->params->{backup},  'bak-id',         'restore backup param' );

  $client->backup->delete( account => 'user@example.com', backup => 'bak-id' );
  is( $mock->last_call->method, 'backup.delete', 'delete' );

  dies_ok { $client->backup->list } 'list requires account';
  dies_ok { $client->backup->restore( account => 'x@x.com' ) } 'restore requires backup';
};

# ── API::Invoice ──────────────────────────────────────────────────────────────

subtest 'API::Invoice' => sub {
  my ( $client, $mock ) = make_client();

  $client->invoice->list;
  is( $mock->last_call->method, 'invoice.list', 'list' );

  $client->invoice->get( account => 'user@example.com', invoice => 'INV-001' );
  is( $mock->last_call->method,              'invoice.get', 'get' );
  is( $mock->last_call->params->{invoice},   'INV-001',     'get invoice param' );

  $client->invoice->download( account => 'user@example.com', invoice => 'INV-001' );
  is( $mock->last_call->method, 'invoice.download', 'download' );

  dies_ok { $client->invoice->get( account => 'x@x.com' ) } 'get requires invoice';
};

# ── API::Passwordreset ────────────────────────────────────────────────────────

subtest 'API::Passwordreset' => sub {
  my ( $client, $mock ) = make_client();

  $client->passwordreset->request( account => 'user@example.com' );
  is( $mock->last_call->method, 'passwordreset.request', 'request' );

  $client->passwordreset->set(
    account     => 'user@example.com',
    token       => 'reset-token',
    newpassword => 'newsecret',
  );
  is( $mock->last_call->method,           'passwordreset.set', 'set' );
  is( $mock->last_call->params->{token},  'reset-token',       'set token param' );

  dies_ok { $client->passwordreset->request } 'request requires account';
  dies_ok {
    $client->passwordreset->set( account => 'x@x.com', token => 'tok' );
  } 'set requires newpassword';
};

# ── API::Validate ─────────────────────────────────────────────────────────────

subtest 'API::Validate' => sub {
  my ( $client, $mock ) = make_client();

  $client->validate->email( email => 'user@example.com' );
  is( $mock->last_call->method,           'validate.email',   'email' );
  is( $mock->last_call->params->{email},  'user@example.com', 'email param' );

  dies_ok { $client->validate->email } 'email requires email param';
};

# ── API::Utils ────────────────────────────────────────────────────────────────

subtest 'API::Utils' => sub {
  my ( $client, $mock ) = make_client();

  $client->utils->parse_headers( headers => "From: x\r\nSubject: y" );
  is( $mock->last_call->method, 'utils.parse_headers', 'parse_headers' );

  $client->utils->parse_date( date => 'Mon, 01 Jan 2024 12:00:00 +0000' );
  is( $mock->last_call->method, 'utils.parse_date', 'parse_date' );

  $client->utils->generate_message_id;
  is( $mock->last_call->method, 'utils.generate_message_id', 'generate_message_id ohne param' );

  $client->utils->generate_message_id( account => 'user@example.com' );
  is( $mock->last_call->method,              'utils.generate_message_id', 'generate_message_id mit account' );
  is( $mock->last_call->params->{account},   'user@example.com',          'generate_message_id account param' );

  dies_ok { $client->utils->parse_headers } 'parse_headers requires headers';
  dies_ok { $client->utils->parse_date    } 'parse_date requires date';
};

# ── API::Base ─────────────────────────────────────────────────────────────────

subtest 'API::Base' => sub {
  my ( $client, $mock ) = make_client();

  $client->base->search( query => 'test query' );
  is( $mock->last_call->method,           'search',      'search' );
  is( $mock->last_call->params->{query},  'test query',  'search query param' );

  dies_ok { $client->base->search } 'search requires query';
};

done_testing;
