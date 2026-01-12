#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Wordsmith::Claude::Blog::Builder');

subtest 'Builder creation' => sub {
    my $builder = Wordsmith::Claude::Blog::Builder->new(
        topic => 'Test Topic',
    );

    isa_ok($builder, 'Wordsmith::Claude::Blog::Builder');
    is($builder->topic, 'Test Topic', 'topic set');
    is($builder->style, 'technical', 'default style');
    is($builder->tone, 'professional', 'default tone');
    is($builder->size, 'medium', 'default size');
};

subtest 'Builder requires topic' => sub {
    throws_ok {
        Wordsmith::Claude::Blog::Builder->new();
    } qr/topic/, 'dies without topic';
};

subtest 'Builder with callbacks' => sub {
    my $research_called = 0;
    my $outline_called = 0;
    my $title_called = 0;
    my $section_called = 0;

    my $builder = Wordsmith::Claude::Blog::Builder->new(
        topic => 'Test',
        on_research => sub { $research_called++; return 1; },
        on_outline  => sub { $outline_called++; return $_[0]->[0]; },
        on_title    => sub { $title_called++; return $_[0]->[0]; },
        on_section  => sub { $section_called++; return { action => 'approve' }; },
    );

    ok($builder->has_on_research, 'has on_research callback');
    ok($builder->has_on_outline, 'has on_outline callback');
    ok($builder->has_on_title, 'has on_title callback');
    ok($builder->has_on_section, 'has on_section callback');
};

subtest 'Builder _parse_outline' => sub {
    my $builder = Wordsmith::Claude::Blog::Builder->new(
        topic => 'Test',
    );

    my @sections = $builder->_parse_outline("- Introduction\n- Main Content\n- Conclusion");
    is_deeply(\@sections, ['Introduction', 'Main Content', 'Conclusion'], 'parses dash outline');

    @sections = $builder->_parse_outline("* First\n* Second\n* Third");
    is_deeply(\@sections, ['First', 'Second', 'Third'], 'parses asterisk outline');

    @sections = $builder->_parse_outline("1. One\n2. Two\n3. Three");
    is_deeply(\@sections, ['One', 'Two', 'Three'], 'parses numbered outline');

    @sections = $builder->_parse_outline("");
    ok(@sections >= 2, 'fallback for empty outline');
};

subtest 'Builder _assemble_blog' => sub {
    my $builder = Wordsmith::Claude::Blog::Builder->new(
        topic => 'Test',
    );

    my $sections = [
        { heading => 'Intro', content => 'Introduction text' },
        { heading => 'Body', content => 'Body text' },
    ];

    my $blog = $builder->_assemble_blog('My Title', $sections);

    like($blog, qr/^# My Title/, 'has title');
    like($blog, qr/## Intro/, 'has first section heading');
    like($blog, qr/Introduction text/, 'has first section content');
    like($blog, qr/## Body/, 'has second section heading');
    like($blog, qr/Body text/, 'has second section content');
};

done_testing();
