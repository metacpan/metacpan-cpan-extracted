#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Wordsmith::Claude::Blog');
use_ok('Wordsmith::Claude::Blog::Result');

subtest 'Blog styles' => sub {
    my @styles = Wordsmith::Claude::Blog->all_styles;
    ok(@styles > 0, 'has styles');

    for my $style (qw(technical tutorial announcement casual listicle)) {
        ok(Wordsmith::Claude::Blog->style_exists($style), "style '$style' exists");
        ok(Wordsmith::Claude::Blog->get_style($style), "get_style('$style') returns instruction");
        ok(Wordsmith::Claude::Blog->style_description($style), "style_description('$style') returns description");

        my $info = Wordsmith::Claude::Blog->style_info($style);
        ok($info, "style_info('$style') returns hashref");
        ok($info->{instruction}, "info has instruction");
        ok($info->{description}, "info has description");
    }

    ok(!Wordsmith::Claude::Blog->style_exists('nonexistent'), 'nonexistent style returns false');
    ok(!Wordsmith::Claude::Blog->get_style('nonexistent'), 'get_style for nonexistent returns undef');
};

subtest 'Blog tones' => sub {
    my @tones = Wordsmith::Claude::Blog->all_tones;
    ok(@tones > 0, 'has tones');

    for my $tone (qw(professional friendly enthusiastic thoughtful)) {
        ok(Wordsmith::Claude::Blog->tone_exists($tone), "tone '$tone' exists");
        ok(Wordsmith::Claude::Blog->get_tone($tone), "get_tone('$tone') returns instruction");
        ok(Wordsmith::Claude::Blog->tone_description($tone), "tone_description('$tone') returns description");
    }

    ok(!Wordsmith::Claude::Blog->tone_exists('nonexistent'), 'nonexistent tone returns false');
};

subtest 'Blog lengths' => sub {
    my @lengths = Wordsmith::Claude::Blog->all_lengths;
    ok(@lengths > 0, 'has lengths');

    for my $length (qw(short medium long)) {
        ok(Wordsmith::Claude::Blog->length_exists($length), "length '$length' exists");
        ok(Wordsmith::Claude::Blog->get_length($length), "get_length('$length') returns instruction");
        ok(Wordsmith::Claude::Blog->length_description($length), "length_description('$length') returns description");
    }

    ok(!Wordsmith::Claude::Blog->length_exists('nonexistent'), 'nonexistent length returns false');
};

subtest 'Blog::Result basic' => sub {
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test Topic',
        title => 'Test Title',
        text  => 'This is the blog content.',
    );

    is($result->topic, 'Test Topic', 'topic accessor');
    is($result->title, 'Test Title', 'title accessor');
    is($result->text, 'This is the blog content.', 'text accessor');
    ok($result->is_success, 'is_success without error');
    ok(!$result->is_error, 'is_error without error');
};

subtest 'Blog::Result with error' => sub {
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test',
        title => 'Test',
        text  => '',
        error => 'Something went wrong',
    );

    ok($result->is_error, 'is_error with error');
    ok(!$result->is_success, 'is_success with error');
    is($result->error, 'Something went wrong', 'error accessor');
};

subtest 'Blog::Result word_count' => sub {
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test',
        title => 'Test',
        text  => 'one two three four five',
    );

    is($result->word_count, 5, 'word_count is correct');
};

subtest 'Blog::Result reading_time' => sub {
    # ~200 words = 1 minute
    my $words = join(' ', ('word') x 200);
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test',
        title => 'Test',
        text  => $words,
    );

    is($result->reading_time, 1, 'reading_time for 200 words');

    # ~400 words = 2 minutes
    my $more_words = join(' ', ('word') x 400);
    my $result2 = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test',
        title => 'Test',
        text  => $more_words,
    );

    is($result2->reading_time, 2, 'reading_time for 400 words');
};

subtest 'Blog::Result as_markdown' => sub {
    my $text = "# Title\n\nContent here";
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test',
        title => 'Test',
        text  => $text,
    );

    is($result->as_markdown, $text, 'as_markdown returns text');
};

subtest 'Blog::Result as_html' => sub {
    my $text = "# Title\n\n**bold** text";
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic => 'Test',
        title => 'Test',
        text  => $text,
    );

    my $html = $result->as_html;
    like($html, qr/<h1>Title<\/h1>/, 'converts # to h1');
    like($html, qr/<strong>bold<\/strong>/, 'converts ** to strong');
};

subtest 'Blog::Result sections' => sub {
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic    => 'Test',
        title    => 'Test',
        text     => 'content',
        sections => [
            { heading => 'Intro', content => 'intro text' },
            { heading => 'Main', content => 'main text' },
        ],
    );

    is($result->section_count, 2, 'section_count');
    is($result->get_section(0)->{heading}, 'Intro', 'get_section(0)');
    is($result->get_section(1)->{heading}, 'Main', 'get_section(1)');
};

subtest 'Blog::Result to_hash' => sub {
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic  => 'Test Topic',
        title  => 'Test Title',
        text   => 'word word word',
        style  => 'technical',
        tone   => 'professional',
    );

    my $hash = $result->to_hash;
    is($hash->{topic}, 'Test Topic', 'hash has topic');
    is($hash->{title}, 'Test Title', 'hash has title');
    is($hash->{style}, 'technical', 'hash has style');
    is($hash->{tone}, 'professional', 'hash has tone');
    is($hash->{word_count}, 3, 'hash has word_count');
    ok($hash->{reading_time}, 'hash has reading_time');
};

subtest 'Blog::Result metadata' => sub {
    my $result = Wordsmith::Claude::Blog::Result->new(
        topic    => 'Test',
        title    => 'Test',
        text     => 'content',
        metadata => { word_count => 500, reading_time => 3 },
    );

    is($result->word_count, 500, 'word_count from metadata');
    is($result->reading_time, 3, 'reading_time from metadata');
};

done_testing();
