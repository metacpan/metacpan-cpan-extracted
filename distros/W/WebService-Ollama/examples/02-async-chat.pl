#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';

use WebService::Ollama::Async;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Create async client
my $ollama = WebService::Ollama::Async->new(
    base_url => 'http://localhost:11434',
    model    => 'llama3.2',
    loop     => $loop,
);

# Simple async chat
print "Simple async chat...\n\n";

$ollama->chat(
    messages => [
        { role => 'user', content => 'Say hello in 3 different languages.' }
    ],
)->then(sub {
    my ($response) = @_;
    print "Response: ", $response->message->{content}, "\n\n";
})->get;

# Multiple concurrent requests
print "Running 3 queries concurrently...\n\n";

my @prompts = (
    'What is the capital of France?',
    'What is 2 + 2?',
    'Name a color.',
);

my @futures = map {
    my $prompt = $_;
    $ollama->chat(
        messages => [{ role => 'user', content => $prompt }],
    )->then(sub {
        my ($response) = @_;
        return { prompt => $prompt, answer => $response->message->{content} };
    });
} @prompts;

# Wait for all to complete
require Future;
Future->needs_all(@futures)->then(sub {
    my @results = @_;
    for my $r (@results) {
        print "Q: $r->{prompt}\n";
        print "A: $r->{answer}\n\n";
    }
})->get;

print "Done!\n";
