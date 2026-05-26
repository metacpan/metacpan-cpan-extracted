use strict;
use warnings;

use Test::More;

use WWW::MailboxOrg::Entity::Account;
use WWW::MailboxOrg::Entity::Domain;

# ── Entity::Account ───────────────────────────────────────────────────────────

subtest 'Entity::Account vollständig' => sub {
  my $account = WWW::MailboxOrg::Entity::Account->new(
    client    => undef,
    account   => 'user@example.com',
    plan      => 'basic',
    confirmed => 1,
    is_active => 1,
    is_locked => 0,
  );

  is( $account->account, 'user@example.com', 'account' );
  is( $account->plan,    'basic',            'plan' );
  ok( $account->has_plan,      'has_plan' );
  ok( $account->confirmed,     'confirmed' );
  ok( $account->has_confirmed, 'has_confirmed' );
  ok( $account->is_active,     'is_active' );
  ok( $account->has_is_active, 'has_is_active' );
  ok( !$account->is_locked,    'is_locked false' );
  ok( $account->has_is_locked, 'has_is_locked auch bei false gesetzt' );
};

subtest 'Entity::Account data()' => sub {
  my $account = WWW::MailboxOrg::Entity::Account->new(
    client    => undef,
    account   => 'user@example.com',
    plan      => 'profi',
    confirmed => 1,
    is_active => 1,
    is_locked => 0,
  );

  my $data = $account->data;
  is( ref $data,        'HASH',             'data ist HashRef' );
  is( $data->{account}, 'user@example.com', 'data account' );
  is( $data->{plan},    'profi',            'data plan' );
  ok( $data->{confirmed},                   'data confirmed' );
  ok( $data->{is_active},                   'data is_active' );
  ok( !$data->{is_locked},                  'data is_locked false' );
};

subtest 'Entity::Account ohne optionale Felder' => sub {
  my $account = WWW::MailboxOrg::Entity::Account->new(
    client  => undef,
    account => 'min@example.com',
  );

  is( $account->account, 'min@example.com', 'account gesetzt' );
  ok( !$account->has_plan,      'kein plan' );
  ok( !$account->has_confirmed, 'kein confirmed' );
  ok( !$account->has_is_active, 'kein is_active' );
  ok( !$account->has_is_locked, 'kein is_locked' );
};

# ── Entity::Domain ────────────────────────────────────────────────────────────

subtest 'Entity::Domain vollständig' => sub {
  my $domain = WWW::MailboxOrg::Entity::Domain->new(
    client     => undef,
    domain     => 'example.com',
    context_id => 'ctx-123',
    is_active  => 1,
  );

  is( $domain->domain,     'example.com', 'domain' );
  is( $domain->context_id, 'ctx-123',     'context_id' );
  ok( $domain->has_context_id, 'has_context_id' );
  ok( $domain->is_active,      'is_active' );
  ok( $domain->has_is_active,  'has_is_active' );
};

subtest 'Entity::Domain data()' => sub {
  my $domain = WWW::MailboxOrg::Entity::Domain->new(
    client     => undef,
    domain     => 'example.com',
    context_id => 'ctx-456',
    is_active  => 1,
  );

  my $data = $domain->data;
  is( ref $data,           'HASH',        'data ist HashRef' );
  is( $data->{domain},     'example.com', 'data domain' );
  is( $data->{context_id}, 'ctx-456',     'data context_id' );
  ok( $data->{is_active},                 'data is_active' );
};

subtest 'Entity::Domain ohne optionale Felder' => sub {
  my $domain = WWW::MailboxOrg::Entity::Domain->new(
    client => undef,
    domain => 'minimal.com',
  );

  is( $domain->domain, 'minimal.com', 'domain gesetzt' );
  ok( !$domain->has_context_id, 'kein context_id' );
  ok( !$domain->has_is_active,  'kein is_active' );
};

done_testing;
