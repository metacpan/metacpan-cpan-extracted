use strict;
use warnings;
use Test::More;

use WebService::Ollama::Async;
use WebService::Ollama::UA::Async;
use IO::Async::Loop;

# Test async module loading
subtest 'async module loads' => sub {
    my $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
        model    => 'llama3.2',
    );
    
    ok($ollama, 'Async client created');
    isa_ok($ollama, 'WebService::Ollama::Async');
};

# Test that async methods exist
subtest 'async methods exist' => sub {
    my $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
    );

    can_ok($ollama, 'chat');
    can_ok($ollama, 'completion');
    can_ok($ollama, 'embed');
    can_ok($ollama, 'chat_with_tools');
    can_ok($ollama, 'register_tool');
    can_ok($ollama, 'version');
};

# Test async validation (without actual HTTP calls)
subtest 'async validation returns Future' => sub {
    my $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
    );

    # Test missing model
    my $f1 = $ollama->chat(messages => [{ role => 'user', content => 'hi' }]);
    isa_ok($f1, 'Future', 'chat returns Future');
    ok($f1->is_failed, 'chat fails without model');

    # Test missing messages
    $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
        model    => 'llama3.2',
    );
    my $f2 = $ollama->chat();
    ok($f2->is_failed, 'chat fails without messages');

    # Test missing prompt for completion
    my $f3 = $ollama->completion();
    ok($f3->is_failed, 'completion fails without prompt');
};

# Test loop injection
subtest 'loop injection' => sub {
    my $loop = IO::Async::Loop->new;
    my $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
        loop     => $loop,
    );

    ok($ollama->has_loop, 'has_loop returns true');
    is($ollama->loop, $loop, 'Loop preserved');
};

# Test tool registration in async client
subtest 'async tool registration' => sub {
    my $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
        model    => 'llama3.2',
    );

    $ollama->register_tool(
        name    => 'test_tool',
        handler => sub { 'result' },
    );

    ok(exists $ollama->tools->{test_tool}, 'Tool registered in async client');
    
    my $formatted = $ollama->_format_tools_for_api;
    is($formatted->[0]{function}{name}, 'test_tool', 'Tool formatted correctly');
};

done_testing;
