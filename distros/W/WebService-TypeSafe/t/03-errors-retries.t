use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json);
use lib 'lib';
use WebService::TypeSafe qw(noul retry_policy);

my ($attempts, @delays) = (0);
my $client = WebService::TypeSafe->new(
    api_key => 'test-key',
    retry => retry_policy(max_retries => 1, backoff_jitter => 0),
    sleeper => sub { push @delays, $_[0] },
    http => sub {
        $attempts++;
        return { success => 0, status => 429, headers => {'retry-after-ms' => 25}, content => '{}' }
            if $attempts == 1;
        return { success => 1, status => 200, headers => {}, content => encode_json({
            model => 'jev-test', answers => { ok => { type => 'noul', noul => 1 } },
            usage => { input_tokens => 1, output_tokens => 1 },
        }) };
    },
);
my $result = $client->system_one(state => 'x', questions => { ok => noul(instructions => 'ok?') });
is($attempts, 2, 'retried once');
is($delays[0], 0.025, 'honored retry-after-ms');

my $bad = WebService::TypeSafe->new(
    api_key => 'test-key', retry => retry_policy(max_retries => 0),
    http => sub { return { success => 0, status => 401,
        headers => {'x-typesafe-request-id' => 'req_1'}, content => '{"error":"bad key"}' } },
);
eval { $bad->system_one(state => 'x', questions => { ok => noul(instructions => 'ok?') }) };
isa_ok($@, 'WebService::TypeSafe::AuthenticationError');
is($@->status, 401);
is($@->request_id, 'req_1');
is($@->body->{error}, 'bad key');

my $budgeted = WebService::TypeSafe->new(
    api_key => 'test-key', sleeper => sub {},
    retry => retry_policy(max_retries => 2, timeout => 0.01, backoff_initial => 1),
    http => sub { return { success => 0, status => 529, headers => {}, content => '{}' } },
);
eval { $budgeted->system_one(state => 'x', questions => { ok => noul(instructions => 'ok?') }) };
isa_ok($@, 'WebService::TypeSafe::InternalServerError', 'retry budget preserves last API error');
is($@->status, 529);

my $timeout_client = WebService::TypeSafe->new(
    api_key => 'test-key', retry => retry_policy(max_retries => 0),
    http => sub { return { success => 0, status => 599, headers => {}, content => 'Timed out' } },
);
eval { $timeout_client->system_one(state => 'x', questions => { ok => noul(instructions => 'ok?') }) };
isa_ok($@, 'WebService::TypeSafe::TimeoutError', 'HTTP::Tiny timeout is classified');
is($@->timeout, 60);

done_testing;
