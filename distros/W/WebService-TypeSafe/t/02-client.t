use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json decode_json);
use lib 'lib';
use WebService::TypeSafe qw(choice noul retry_policy);

my @requests;
my $transport = sub {
    my ($method, $url, $request) = @_;
    push @requests, [$method, $url, $request];
    return {
        success => 1, status => 200, headers => {},
        content => encode_json({
            model => 'jev-1.13.0',
            answers => {
                urgent => { type => 'noul', noul => 0.93 },
                team => { type => 'choice', choice => 'billing', confidence => 0.8,
                          probabilities => { billing => 0.9, other => 0.1 } },
            },
            usage => { input_tokens => 10, output_tokens => 4 },
        }),
    };
};

my $client = WebService::TypeSafe->new(api_key => 'test-key', http => $transport);
my $result = $client->system_one(
    state => 'Please fix my invoice now',
    questions => {
        urgent => noul(instructions => 'Urgent?'),
        team => choice(instructions => 'Team?', criteria => { billing => undef, other => undef }),
    },
);
is($result->answers->{urgent}->noul, 0.93, 'answer accessor');
is($result->nouls->{urgent}->noul, 0.93, 'typed answer collection');
is($result->choices->{team}->choice, 'billing', 'choice accessor');
is($result->usage->input_tokens, 10, 'usage object');
is($requests[0][0], 'POST');
like($requests[0][1], qr{/v1/systemone$});
is(decode_json($requests[0][2]{content})->{model}, 'jev-latest');
is($requests[0][2]{headers}{authorization}, 'Bearer test-key');

done_testing;
