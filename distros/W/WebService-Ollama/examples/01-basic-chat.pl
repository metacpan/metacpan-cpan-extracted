#!/usr/bin/env perl
#
# Basic chat example using WebService::Ollama
#

use strict;
use warnings;
use lib 'lib';

use WebService::Ollama;

my $ollama = WebService::Ollama->new(
    base_url => 'http://localhost:11434',
    model    => 'llama3.2',
);

# Simple chat
my $response = $ollama->chat(
    messages => [
        { role => 'user', content => 'What is the capital of France?' }
    ],
);

print "Response: ", $response->message->{content}, "\n";
