#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Wordsmith::Claude::Blog::Reviewer::Interactive');

subtest 'Reviewer::Interactive creation with text' => sub {
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text => 'Test blog content',
    );

    isa_ok($interactive, 'Wordsmith::Claude::Blog::Reviewer::Interactive');
    is($interactive->text, 'Test blog content', 'text set');
    ok($interactive->loop, 'has default loop');
};

subtest 'Reviewer::Interactive creation with file' => sub {
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        file => '/tmp/test-blog.md',
    );

    is($interactive->file, '/tmp/test-blog.md', 'file set');
};

subtest 'Reviewer::Interactive creation with title' => sub {
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text  => 'Test content',
        title => 'My Test Blog',
    );

    is($interactive->title, 'My Test Blog', 'title set');
};

subtest 'Reviewer::Interactive has run method' => sub {
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text => 'Test',
    );

    can_ok($interactive, 'run');
};

subtest 'Reviewer::Interactive has internal methods' => sub {
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text => 'Test',
    );

    can_ok($interactive, '_load_input');
    can_ok($interactive, '_handle_paragraph');
    can_ok($interactive, '_get_user_decision');
    can_ok($interactive, '_get_revision_instructions');
    can_ok($interactive, '_manual_edit');
};

done_testing();
