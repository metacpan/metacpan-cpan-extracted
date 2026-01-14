#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use lib 'lib';

use WebService::Ollama;

# Create client
my $ollama = WebService::Ollama->new(
    base_url => 'http://localhost:11434',
    model    => 'llama3.2',  # Use a tool-capable model
);

# Register tools
$ollama->register_tool(
    name        => 'get_weather',
    description => 'Get the current weather for a location',
    parameters  => {
        type       => 'object',
        properties => {
            location => {
                type        => 'string',
                description => 'City name, e.g. "Seattle, WA"',
            },
        },
        required => ['location'],
    },
    handler => sub {
        my ($args) = @_;
        my $location = $args->{location};
        # Fake weather data
        return {
            location    => $location,
            temperature => 72,
            condition   => 'sunny',
            humidity    => 45,
        };
    },
);

$ollama->register_tool(
    name        => 'calculate',
    description => 'Perform arithmetic calculations',
    parameters  => {
        type       => 'object',
        properties => {
            expression => {
                type        => 'string',
                description => 'Math expression to evaluate, e.g. "2 + 2"',
            },
        },
        required => ['expression'],
    },
    handler => sub {
        my ($args) = @_;
        my $expr = $args->{expression};
        # Safe eval for simple math
        my $result = eval $expr;
        return { expression => $expr, result => $result // 'Error' };
    },
);

# Chat with tools - the model will automatically call tools and get results
print "Asking about weather...\n\n";

my $response = $ollama->chat_with_tools(
    messages => [
        { role => 'user', content => 'What is the weather like in Seattle?' }
    ],
);

print "Response: ", $response->message->{content}, "\n\n";

# Another example with calculation
print "Asking for a calculation...\n\n";

$response = $ollama->chat_with_tools(
    messages => [
        { role => 'user', content => 'What is 42 * 17?' }
    ],
);

print "Response: ", $response->message->{content}, "\n";
