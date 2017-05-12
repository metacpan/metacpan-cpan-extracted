use strict;
use warnings;
use Test::Most;
use Test::Fatal;
use Test::FailWarnings;
use Try::Tiny;
use Vero::API;

{

    package FakeUA::Success;
    sub new { bless {}, __PACKAGE__ }
    sub res { return shift }
    sub json { return {status => 200, message => "Success."} }
    sub post { my $s = shift; $s->{post} = [@_]; return $s; }
    sub success { return 1 }

    package FakeUA::Error;
    sub new { bless {}, __PACKAGE__ }
    sub post { my $s = shift; $s->{post} = [@_]; return $s; }
    sub success { return }
    sub error   { return ('to err is human.', 999) }
    sub res     { return shift }
    sub json    { return {'message' => 'damn humans.', 'status' => 400} }

    package My::VeroAPI;
    use parent 'Vero::API';
    sub _build_token { 'vero-api-pm-overriden-token' }
}

my $success_ua = FakeUA::Success->new;
my $error_ua   = FakeUA::Error->new;
my $token      = 'vero-api-pm-test-token';

subtest 'constructor' => sub {
    my $v = new_ok 'Vero::API', [token => $token];
    is $v->token, $token, 'created with correct token';
    my $agentid = try { $v->ua->transactor->name } || $v->ua->name;
    is $agentid, "Vero::API/$Vero::API::VERSION (Perl)", 'User agent correctly identifies itself';
    like exception { Vero::API->new }, qr/A token is required/, 'Constructor requires a token';
    new_ok 'Vero::API', [token => ''], 'but it can be empty';
    my $o = new_ok 'My::VeroAPI', [], 'or overriden';
    is $o->token, 'vero-api-pm-overriden-token', 'Takes correct token when overriding';
    my $oo = new_ok 'My::VeroAPI', [token => 'constructor-token'], 'can pass token argument when overriding';
    is $oo->token, 'constructor-token', 'and it is honored.';
};

subtest 'track_event' => sub {
    subtest 'successful request' => sub {
        my $v = Vero::API->new(
            ua    => $success_ua,
            token => $token
        );
        subtest 'with both id and email' => sub {
            ok $v->track_event(
                'test-running',
                id    => 'CID000000',
                email => 'fakeclient@example.com',
                hello => 'world'
              ),
              'returns true when request succeeds';
            my $post = $v->ua->{post};
            ok $post, 'we POSTed some data.';
            like $post->[0], qr/api.getvero.com/, 'correct url.';
            is $post->[1], 'json', 'sending data as json';
            cmp_deeply(
                $post->[2],
                superhashof({
                        identity => {
                            id    => 'CID000000',
                            email => 'fakeclient@example.com',
                        },
                        event_name => 'test-running',
                        data       => {hello => 'world'}}
                ),
                'contains expected data'
            );
        };
        subtest 'with only id' => sub {
            ok $v->track_event(
                'test-running',
                id    => 'CID000000',
                hello => 'world'
              ),
              'returns true when request succeeds';
            my $post = $v->ua->{post};
            cmp_deeply(
                $post->[2],
                superhashof({
                        identity   => {id    => 'CID000000',},
                        event_name => 'test-running',
                        data       => {hello => 'world'}}
                ),
                'contains expected data'
            );
        };
        subtest 'with only email' => sub {
            ok $v->track_event(
                'test-running',
                email => 'fakeclient@example.com',
                hello => 'world'
              ),
              'returns true when request succeeds';
            my $post = $v->ua->{post};
            cmp_deeply(
                $post->[2],
                superhashof({
                        identity   => {email => 'fakeclient@example.com',},
                        event_name => 'test-running',
                        data       => {hello => 'world'}}
                ),
                'contains expected data'
            );
        };
    };

    subtest 'failed request' => sub {
        my $v = Vero::API->new(
            ua    => $error_ua,
            token => $token
        );
        my $exception = exception {
            $v->track_event(
                'test-running',
                id    => 'CID000000',
                hello => 'world'
            );
        };
        like $exception, qr/Vero API returned error: code 999, error to err is human., data \{"/, 'Complain noisily when there is an error';
        like $exception, qr/"status":400/,                                                       'Complain noisily when there is an error';
        like $exception, qr/"message":"damn humans."/,                                           'Complain noisily when there is an error';
        like exception {
            $v->track_event('event_name', idont => 'haveid');
        }, qr/id or email is required/, 'Giving neither id nor email fails';
    };
};

subtest 'identify_user' => sub {
    subtest 'successful request' => sub {
        my $v = Vero::API->new(
            ua    => $success_ua,
            token => $token
        );
        subtest 'with both id and email' => sub {
            ok $v->identify_user(
                id    => 'CID000000',
                email => 'fakeclient@example.com',
                super => 'dupper'
              ),
              'returns true when request succeeds';
            my $post = $v->ua->{post};
            ok $post, 'we POSTed some data.';
            like $post->[0], qr/api.getvero.com/, 'correct url.';
            is $post->[1], 'json', 'sending data as json';
            cmp_deeply(
                $post->[2],
                superhashof({
                        id    => 'CID000000',
                        email => 'fakeclient@example.com',
                        data  => {super => 'dupper'}}
                ),
                'contains expected data'
            );
        };

        subtest 'with only id' => sub {
            ok $v->identify_user(
                id    => 'CID000000',
                super => 'dupper',
                uga   => 'buga',
              ),
              'returns true when request succeeds';
            my $post = $v->ua->{post};
            cmp_deeply(
                $post->[2],
                superhashof({
                        id   => 'CID000000',
                        data => {
                            super => 'dupper',
                            uga   => 'buga'
                        }}
                ),
                'contains expected data'
            );
        };

        subtest 'with only email' => sub {
            ok $v->identify_user(
                email => 'fakeclient@example.com',
                super => 'dupper',
              ),
              'returns true when request succeeds';
            my $post = $v->ua->{post};
            cmp_deeply(
                $post->[2],
                superhashof({
                        email => 'fakeclient@example.com',
                        data  => {super => 'dupper',}}
                ),
                'contains expected data'
            );
        };
    };

    subtest 'failed request' => sub {
        my $v = Vero::API->new(
            ua    => $error_ua,
            token => $token
        );
        my $exception = exception {
            $v->identify_user(
                id    => 'BADID000000',
                hello => 'world'
            );
        };
        like $exception, qr/Vero API returned error: code 999, error to err is human., data \{"/, 'Complain noisily when there is an error';
        like $exception, qr/"status":400/,                                                       'Complain noisily when there is an error';
        like $exception, qr/"message":"damn humans."/,                                           'Complain noisily when there is an error';

        like exception {
            $v->identify_user(idont => 'haveid');
        }, qr/id or email is required/, 'Giving neither id nor email fails';
    };
};

done_testing;
