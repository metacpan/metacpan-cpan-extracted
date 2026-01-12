#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'utf8';  # Suppress wide character warnings when capturing to scalar
use Test::More;

use_ok('Claude::Agent::CLI');

subtest 'CLI exports' => sub {
    # Test that functions are exported correctly
    use Claude::Agent::CLI qw(
        with_spinner start_spinner stop_spinner
        header divider status
        prompt ask_yn menu select_option choose_from choose_multiple
        clear_line move_up
    );

    can_ok('main', 'with_spinner');
    can_ok('main', 'start_spinner');
    can_ok('main', 'stop_spinner');
    can_ok('main', 'header');
    can_ok('main', 'divider');
    can_ok('main', 'status');
    can_ok('main', 'prompt');
    can_ok('main', 'ask_yn');
    can_ok('main', 'menu');
    can_ok('main', 'select_option');
    can_ok('main', 'choose_from');
    can_ok('main', 'choose_multiple');
    can_ok('main', 'clear_line');
    can_ok('main', 'move_up');
};

subtest 'Export tags' => sub {
    my %tags = %Claude::Agent::CLI::EXPORT_TAGS;

    ok(exists $tags{all}, 'has :all tag');
    ok(exists $tags{spinner}, 'has :spinner tag');
    ok(exists $tags{prompt}, 'has :prompt tag');
    ok(exists $tags{display}, 'has :display tag');
    ok(exists $tags{term}, 'has :term tag');

    # Verify tag contents
    ok(grep { $_ eq 'with_spinner' } @{$tags{spinner}}, ':spinner includes with_spinner');
    ok(grep { $_ eq 'header' } @{$tags{display}}, ':display includes header');
    ok(grep { $_ eq 'prompt' } @{$tags{prompt}}, ':prompt includes prompt');
    ok(grep { $_ eq 'clear_line' } @{$tags{term}}, ':term includes clear_line');
};

subtest 'header output' => sub {
    # Capture output
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        Claude::Agent::CLI::header("Test Header");
    }

    like($output, qr/Test Header/, 'header contains text');
    like($output, qr/=+/, 'header has border');
};

subtest 'divider output' => sub {
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        Claude::Agent::CLI::divider();
    }

    like($output, qr/-{60}/, 'default divider is 60 dashes');

    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        Claude::Agent::CLI::divider('*', 20);
    }

    like($output, qr/\*{20}/, 'custom divider works');
};

subtest 'status output' => sub {
    for my $type (qw(success error warning info)) {
        my $output = '';
        {
            local *STDOUT;
            open STDOUT, '>', \$output;
            Claude::Agent::CLI::status($type, "Test message");
        }

        like($output, qr/Test message/, "status $type contains message");
    }
};

subtest 'terminal control' => sub {
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        Claude::Agent::CLI::clear_line();
    }

    like($output, qr/\r\033\[K/, 'clear_line outputs escape sequence');

    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        Claude::Agent::CLI::move_up(3);
    }

    like($output, qr/\033\[3A/, 'move_up outputs escape sequence');
};

done_testing();
