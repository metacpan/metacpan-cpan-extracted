use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('WebService::Ollama', 'ollama');
    use_ok('WebService::Ollama::Async', 'ollama');
}

# Test sync functional API
subtest 'sync functional API' => sub {
    # Configure with hashref
    my $instance = WebService::Ollama::ollama({
        base_url => 'http://localhost:11434',
        model    => 'test-model',
    });
    
    isa_ok($instance, 'WebService::Ollama', 'Returns Ollama instance');
    is($instance->model, 'test-model', 'Model set correctly');
    is($instance->base_url, 'http://localhost:11434', 'Base URL set correctly');
};

# Test async functional API
subtest 'async functional API' => sub {
    my $instance = WebService::Ollama::Async::ollama({
        base_url => 'http://localhost:11434',
        model    => 'async-test-model',
    });
    
    isa_ok($instance, 'WebService::Ollama::Async', 'Returns Async instance');
    is($instance->model, 'async-test-model', 'Model set correctly');
};

# Test export
subtest 'export' => sub {
    can_ok('main', 'ollama');
};

done_testing();
