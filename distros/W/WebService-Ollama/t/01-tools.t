use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('WebService::Ollama');
    use_ok('WebService::Ollama::Response');
}

# Test tool registration
subtest 'tool registration' => sub {
    my $ollama = WebService::Ollama->new(
        base_url => 'http://localhost:11434',
        model    => 'llama3.2',
    );

    # Register a simple tool
    $ollama->register_tool(
        name        => 'get_weather',
        description => 'Get current weather for a location',
        parameters  => {
            type       => 'object',
            properties => {
                location => {
                    type        => 'string',
                    description => 'City name',
                },
            },
            required => ['location'],
        },
        handler => sub {
            my ($args) = @_;
            return { temperature => 72, condition => 'sunny', location => $args->{location} };
        },
    );

    ok(exists $ollama->tools->{get_weather}, 'Tool registered');
    is($ollama->tools->{get_weather}{name}, 'get_weather', 'Tool name correct');
    is(ref($ollama->tools->{get_weather}{handler}), 'CODE', 'Handler is coderef');

    # Test the handler directly
    my $result = $ollama->tools->{get_weather}{handler}->({ location => 'Seattle' });
    is($result->{temperature}, 72, 'Handler returns correct data');
    is($result->{location}, 'Seattle', 'Handler receives args');
};

# Test tool formatting for API
subtest 'tool formatting' => sub {
    my $ollama = WebService::Ollama->new(
        base_url => 'http://localhost:11434',
    );

    $ollama->register_tool(
        name        => 'calculate',
        description => 'Do math',
        parameters  => {
            type       => 'object',
            properties => {
                expression => { type => 'string' },
            },
        },
        handler => sub { eval $_[0]->{expression} },
    );

    my $formatted = $ollama->_format_tools_for_api;
    
    is(ref($formatted), 'ARRAY', 'Returns array');
    is(scalar @$formatted, 1, 'One tool formatted');
    is($formatted->[0]{type}, 'function', 'Type is function');
    is($formatted->[0]{function}{name}, 'calculate', 'Name preserved');
    is($formatted->[0]{function}{description}, 'Do math', 'Description preserved');
};

# Test Response tool_calls extraction
subtest 'response tool_calls' => sub {
    my $response = WebService::Ollama::Response->new(
        done        => 1,
        done_reason => 'tool_calls',
        message     => {
            role       => 'assistant',
            content    => '',
            tool_calls => [
                {
                    id       => 'call_123',
                    function => {
                        name      => 'get_weather',
                        arguments => '{"location":"Paris"}',
                    },
                },
            ],
        },
    );

    ok($response->has_tool_calls, 'has_tool_calls returns true');
    
    my $calls = $response->extract_tool_calls;
    is(ref($calls), 'ARRAY', 'extract_tool_calls returns array');
    is(scalar @$calls, 1, 'One tool call');
    is($calls->[0]{function}{name}, 'get_weather', 'Tool name extracted');
};

# Test Response without tool_calls
subtest 'response without tool_calls' => sub {
    my $response = WebService::Ollama::Response->new(
        done    => 1,
        message => {
            role    => 'assistant',
            content => 'Hello!',
        },
    );

    ok(!$response->has_tool_calls, 'has_tool_calls returns false for empty');
    
    my $calls = $response->extract_tool_calls;
    is(ref($calls), 'ARRAY', 'Returns array');
    is(scalar @$calls, 0, 'Empty array for no tool calls');
};

# Test multiple tools registration
subtest 'multiple tools' => sub {
    my $ollama = WebService::Ollama->new(
        base_url => 'http://localhost:11434',
    );

    $ollama->register_tool(
        name    => 'tool1',
        handler => sub { 'result1' },
    );

    $ollama->register_tool(
        name    => 'tool2', 
        handler => sub { 'result2' },
    );

    is(scalar keys %{$ollama->tools}, 2, 'Two tools registered');
    
    my $formatted = $ollama->_format_tools_for_api;
    is(scalar @$formatted, 2, 'Two tools formatted');
};

# Test fallback parsing of tool calls from content
subtest 'fallback tool call parsing' => sub {
    # Test with "arguments" key
    my $response1 = WebService::Ollama::Response->new(
        done    => 1,
        message => {
            role    => 'assistant',
            content => 'I will read the file: {"name": "read_file", "arguments": {"path": "test.txt"}}',
        },
    );

    ok($response1->has_tool_calls, 'Detects tool call in content with arguments');
    my $calls1 = $response1->extract_tool_calls;
    is(scalar @$calls1, 1, 'One tool call extracted');
    is($calls1->[0]{function}{name}, 'read_file', 'Tool name extracted');
    is($calls1->[0]{function}{arguments}{path}, 'test.txt', 'Arguments parsed');

    # Test with "parameters" key (some models use this)
    my $response2 = WebService::Ollama::Response->new(
        done    => 1,
        message => {
            role    => 'assistant',
            content => '{"name": "search_files", "parameters": {"pattern": "TODO"}}',
        },
    );

    ok($response2->has_tool_calls, 'Detects tool call with parameters key');
    my $calls2 = $response2->extract_tool_calls;
    is($calls2->[0]{function}{name}, 'search_files', 'Tool name from parameters format');
};

done_testing;
