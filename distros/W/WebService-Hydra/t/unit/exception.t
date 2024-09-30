use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockModule;
use Object::Pad;
use Log::Any::Test;
use Log::Any        qw($log);
use JSON::MaybeUTF8 qw(decode_json_text);

BEGIN {
    use_ok 'WebService::Hydra::Exception';
}

# Test WebService::Hydra::Exception itself
throws_ok { WebService::Hydra::Exception->new } qr/WebService::Hydra::Exception is a base class and cannot be instantiated directly/,
    "WebService::Hydra::Exception cannot be instantiated directly";

throws_ok { WebService::Hydra::Exception->throw(message => 'test') } qr/WebService::Hydra::Exception is a base class and cannot be thrown directly/,
    "WebService::Hydra::Exception cannot be thrown directly";

# define a subclass
class Test::Exception :isa(WebService::Hydra::Exception) {
};

subtest 'throw' => sub {
    my $e = Test::Exception->new(
        message  => 'this is a test exception',
        category => 'test'
    );
    throws_ok { $e->throw } $e, "throw from an obj throws exception";
    throws_ok { Test::Exception->throw } 'Test::Exception', "throw from a class throws exception";
};

subtest 'log' => sub {
    my $e = Test::Exception->new(
        message  => 'this is a test exception',
        category => 'test'
    );
    $log->clear;
    $e->log;
    $log->contains_ok(qr/this is a test exception/, "log contains exception message");
    $log->clear;
};

subtest 'as_string' => sub {
    my $e = Test::Exception->new(
        message  => 'this is a test exception',
        category => 'test'
    );
    is $e->as_string, "Test::Exception(Category=test, Message=this is a test exception)", "as_string returns message";
    $e = Test::Exception->new(
        message => 'this is a test exception',
        details => ["details 1", "details 2", {context_key => 'context value'}]);
    is $e->as_string, 'Test::Exception(Message=this is a test exception, Details=["details 1","details 2",{"context_key":"context value"}])',
        "details will be encoded as json";
};

subtest 'as_json' => sub {
    my $e = Test::Exception->new(
        message  => 'this is a test exception',
        category => 'test'
    );
    is_deeply decode_json_text($e->as_json),
        {
        Exception => 'Test::Exception',
        Details   => [],
        Message   => 'this is a test exception',
        Category  => 'test',
        },
        "as_string returns message";
    $e = Test::Exception->new(
        message => 'this is a test exception',
        details => ["details 1", "details 2", {context_key => 'context value'}]);
    is_deeply decode_json_text($e->as_json),
        {
        Exception => 'Test::Exception',
        Details   => ["details 1", "details 2", {"context_key" => "context value"}],
        Message   => 'this is a test exception',
        Category  => '',
        },
        , "details will be encoded as json";
};
done_testing();
