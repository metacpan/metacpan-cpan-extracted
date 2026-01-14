#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use lib 'lib';

use WebService::Ollama::Async;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# Create async client with tools
my $ollama = WebService::Ollama::Async->new(
    base_url => 'http://localhost:11434',
    model    => 'llama3.2',  # Use a tool-capable model
    loop     => $loop,
);

# Register a weather tool
$ollama->register_tool(
    name        => 'get_weather',
    description => 'Get the current weather for a location',
    parameters  => {
        type       => 'object',
        properties => {
            location => {
                type        => 'string',
                description => 'City name',
            },
            units => {
                type        => 'string',
                enum        => ['celsius', 'fahrenheit'],
                description => 'Temperature units',
            },
        },
        required => ['location'],
    },
    handler => sub {
        my ($args) = @_;
        my $location = $args->{location};
        my $units = $args->{units} // 'fahrenheit';
        
        # Simulate API call
        print "[Tool] Getting weather for $location ($units)...\n";
        
        my $temp = $units eq 'celsius' ? 22 : 72;
        return {
            location    => $location,
            temperature => $temp,
            units       => $units,
            condition   => 'partly cloudy',
            humidity    => 65,
            wind_speed  => 12,
        };
    },
);

# Register a search tool
$ollama->register_tool(
    name        => 'search_web',
    description => 'Search the web for information',
    parameters  => {
        type       => 'object',
        properties => {
            query => {
                type        => 'string',
                description => 'Search query',
            },
        },
        required => ['query'],
    },
    handler => sub {
        my ($args) = @_;
        my $query = $args->{query};
        
        print "[Tool] Searching for: $query\n";
        
        # Fake search results
        return {
            query   => $query,
            results => [
                { title => "Result 1 for $query", url => "https://example.com/1" },
                { title => "Result 2 for $query", url => "https://example.com/2" },
            ],
        };
    },
);

print "=== Async Chat with Tools ===\n\n";

# The model will call tools as needed, and we handle the loop automatically
$ollama->chat_with_tools(
    messages => [
        { 
            role    => 'user', 
            content => 'What is the weather like in Tokyo? Please use celsius.',
        }
    ],
    max_iterations => 5,
)->then(sub {
    my ($response) = @_;
    print "\nFinal response:\n";
    print $response->message->{content}, "\n\n";
})->get;

# Another example with potential multi-tool usage
print "=== Multi-step query ===\n\n";

$ollama->chat_with_tools(
    messages => [
        { 
            role    => 'user', 
            content => 'Search for "best restaurants" and also tell me the weather in New York.',
        }
    ],
)->then(sub {
    my ($response) = @_;
    print "\nFinal response:\n";
    print $response->message->{content}, "\n";
})->get;

print "\nDone!\n";
