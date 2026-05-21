use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('WWW::MailboxOrg');
    use_ok('WWW::MailboxOrg::Role::HTTP');
    use_ok('WWW::MailboxOrg::Role::IO');
    use_ok('WWW::MailboxOrg::JSONRPCRequest');
    use_ok('WWW::MailboxOrg::JSONRPCResponse');
    use_ok('WWW::MailboxOrg::LWPIO');
    use_ok('WWW::MailboxOrg::Types');
    use_ok('WWW::MailboxOrg::API::Base');
    use_ok('WWW::MailboxOrg::API::Account');
    use_ok('WWW::MailboxOrg::API::Domain');
    use_ok('WWW::MailboxOrg::API::Mail');
    use_ok('WWW::MailboxOrg::API::Mailinglist');
    use_ok('WWW::MailboxOrg::API::Blacklist');
    use_ok('WWW::MailboxOrg::API::Spamprotect');
    use_ok('WWW::MailboxOrg::API::Videochat');
    use_ok('WWW::MailboxOrg::API::Backup');
    use_ok('WWW::MailboxOrg::API::Invoice');
    use_ok('WWW::MailboxOrg::API::Passwordreset');
    use_ok('WWW::MailboxOrg::API::Validate');
    use_ok('WWW::MailboxOrg::API::Utils');
    use_ok('WWW::MailboxOrg::API::System');
    use_ok('WWW::MailboxOrg::Entity::Account');
    use_ok('WWW::MailboxOrg::Entity::Domain');
}

subtest 'WWW::MailboxOrg::JSONRPCRequest' => sub {
    my $req = WWW::MailboxOrg::JSONRPCRequest->new(
        method  => 'test.method',
        params  => { foo => 'bar' },
        id      => 1,
        url     => 'https://api.mailbox.org/v1',
        headers => { 'HPLS-AUTH' => 'session123' },
    );
    ok($req->has_id, 'has id');
    is($req->method, 'test.method');
    is($req->params->{foo}, 'bar');

    my $hash = $req->to_hash;
    is($hash->{jsonrpc}, '2.0');
    is($hash->{method}, 'test.method');
    is($hash->{id}, 1);
};

subtest 'WWW::MailboxOrg::JSONRPCResponse' => sub {
    my $res = WWW::MailboxOrg::JSONRPCResponse->new(
        result => { data => 'value' },
        id     => 1,
    );
    ok($res->has_result);
    ok($res->is_success);
    ok(!$res->has_error);

    my $err_res = WWW::MailboxOrg::JSONRPCResponse->new(
        error => { code => -32600, message => 'Invalid request' },
        id    => 1,
    );
    ok($err_res->has_error);
    ok(!$err_res->is_success);
};

subtest 'WWW::MailboxOrg::Types' => sub {
    use WWW::MailboxOrg::Types qw(EmailAddress DomainName);

    lives_ok {
        my $check = EmailAddress->check('test@example.com');
    };

    lives_ok {
        my $check = DomainName->check('example.com');
    };
};

subtest 'WWW::MailboxOrg::API::Base requires client' => sub {
    eval {
        my $controller = WWW::MailboxOrg::API::Base->new;
    };
    ok($@, 'dies without client');
};

done_testing;