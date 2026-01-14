use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('WebService::Ollama::Response');
}

# Test basic Response construction
subtest 'response construction' => sub {
    my $response = WebService::Ollama::Response->new(
        done           => 1,
        model          => 'llama3.2',
        done_reason    => 'stop',
        total_duration => 1234567890,
        eval_count     => 42,
        eval_duration  => 9876543,
    );

    ok($response->done, 'done is set');
    is($response->model, 'llama3.2', 'model is set');
    is($response->done_reason, 'stop', 'done_reason is set');
    is($response->total_duration, 1234567890, 'total_duration is set');
    is($response->eval_count, 42, 'eval_count is set');
    is($response->eval_duration, 9876543, 'eval_duration is set');
};

# Test message attribute
subtest 'response with message' => sub {
    my $response = WebService::Ollama::Response->new(
        done    => 1,
        message => {
            role    => 'assistant',
            content => 'Hello, world!',
        },
    );

    is(ref($response->message), 'HASH', 'message is a hash');
    is($response->message->{role}, 'assistant', 'message role');
    is($response->message->{content}, 'Hello, world!', 'message content');
};

# Test response attribute (for completions)
subtest 'response with response text' => sub {
    my $response = WebService::Ollama::Response->new(
        done     => 1,
        response => 'This is a completion response.',
    );

    is($response->response, 'This is a completion response.', 'response text');
};

# Test embeddings attribute
subtest 'response with embeddings' => sub {
    my $embeddings = [[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]];
    my $response = WebService::Ollama::Response->new(
        embeddings => $embeddings,
    );

    is(ref($response->embeddings), 'ARRAY', 'embeddings is array');
    is(scalar @{$response->embeddings}, 2, 'two embedding vectors');
    is($response->embeddings->[0][0], 0.1, 'first embedding value');
};

# Test models attribute (for list models)
subtest 'response with models list' => sub {
    my $models = [
        { name => 'llama3.2', size => 1234567890 },
        { name => 'mistral', size => 9876543210 },
    ];
    my $response = WebService::Ollama::Response->new(
        models => $models,
    );

    is(ref($response->models), 'ARRAY', 'models is array');
    is(scalar @{$response->models}, 2, 'two models');
    is($response->models->[0]{name}, 'llama3.2', 'first model name');
};

# Test version attribute
subtest 'response with version' => sub {
    my $response = WebService::Ollama::Response->new(
        version => '0.1.23',
    );

    is($response->version, '0.1.23', 'version is set');
};

# Test pull/download progress attributes
subtest 'response with download progress' => sub {
    my $response = WebService::Ollama::Response->new(
        status    => 'downloading',
        digest    => 'sha256:abc123',
        total     => 1000000,
        completed => 500000,
    );

    is($response->status, 'downloading', 'status is set');
    is($response->digest, 'sha256:abc123', 'digest is set');
    is($response->total, 1000000, 'total is set');
    is($response->completed, 500000, 'completed is set');
};

# Test context attribute (for continuation)
subtest 'response with context' => sub {
    my $context = [1, 2, 3, 4, 5];
    my $response = WebService::Ollama::Response->new(
        done    => 1,
        context => $context,
    );

    is(ref($response->context), 'ARRAY', 'context is array');
    is(scalar @{$response->context}, 5, 'context has 5 elements');
};

# Test multiple tool_calls
subtest 'multiple tool_calls' => sub {
    my $response = WebService::Ollama::Response->new(
        done        => 1,
        done_reason => 'tool_calls',
        message     => {
            role       => 'assistant',
            content    => '',
            tool_calls => [
                {
                    id       => 'call_1',
                    function => {
                        name      => 'get_weather',
                        arguments => '{"location":"Paris"}',
                    },
                },
                {
                    id       => 'call_2',
                    function => {
                        name      => 'get_time',
                        arguments => '{"timezone":"UTC"}',
                    },
                },
            ],
        },
    );

    ok($response->has_tool_calls, 'has_tool_calls is true');
    my $calls = $response->extract_tool_calls;
    is(scalar @$calls, 2, 'two tool calls');
    is($calls->[0]{function}{name}, 'get_weather', 'first tool name');
    is($calls->[1]{function}{name}, 'get_time', 'second tool name');
};

# Test edge cases for tool_calls
subtest 'tool_calls edge cases' => sub {
    # undefined message
    my $r1 = WebService::Ollama::Response->new(done => 1);
    ok(!$r1->has_tool_calls, 'no tool_calls when message undefined');
    is(ref($r1->extract_tool_calls), 'ARRAY', 'extract returns array');
    is(scalar @{$r1->extract_tool_calls}, 0, 'empty array');

    # message without tool_calls key
    my $r2 = WebService::Ollama::Response->new(
        message => { role => 'assistant', content => 'hi' }
    );
    ok(!$r2->has_tool_calls, 'no tool_calls when key missing');

    # message with empty tool_calls array
    my $r3 = WebService::Ollama::Response->new(
        message => { role => 'assistant', tool_calls => [] }
    );
    ok(!$r3->has_tool_calls, 'no tool_calls when array empty');
};

# Test all attributes can be undefined
subtest 'undefined attributes' => sub {
    my $response = WebService::Ollama::Response->new();

    ok(!defined $response->done, 'done can be undefined');
    ok(!defined $response->model, 'model can be undefined');
    ok(!defined $response->message, 'message can be undefined');
    ok(!defined $response->response, 'response can be undefined');
    ok(!defined $response->embeddings, 'embeddings can be undefined');
};

done_testing;
