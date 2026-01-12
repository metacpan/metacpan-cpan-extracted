#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Wordsmith::Claude::Blog::Interactive');

subtest 'Interactive creation with defaults' => sub {
    my $interactive = Wordsmith::Claude::Blog::Interactive->new(
        topic => 'Test Topic',
    );

    isa_ok($interactive, 'Wordsmith::Claude::Blog::Interactive');
    is($interactive->topic, 'Test Topic', 'topic set');
    is($interactive->style, 'technical', 'default style');
    is($interactive->tone, 'professional', 'default tone');
    is($interactive->size, 'medium', 'default size');
    ok($interactive->options, 'has options');
    ok($interactive->loop, 'has loop');
};

subtest 'Interactive creation with custom values' => sub {
    my $interactive = Wordsmith::Claude::Blog::Interactive->new(
        topic => 'Custom Topic',
        style => 'casual',
        tone  => 'friendly',
        size  => 'short',
    );

    is($interactive->topic, 'Custom Topic', 'custom topic');
    is($interactive->style, 'casual', 'custom style');
    is($interactive->tone, 'friendly', 'custom tone');
    is($interactive->size, 'short', 'custom size');
};

subtest 'Interactive requires topic' => sub {
    throws_ok {
        Wordsmith::Claude::Blog::Interactive->new();
    } qr/topic/, 'dies without topic';
};

subtest 'Interactive has run method' => sub {
    my $interactive = Wordsmith::Claude::Blog::Interactive->new(
        topic => 'Test',
    );

    can_ok($interactive, 'run');
};

done_testing();
