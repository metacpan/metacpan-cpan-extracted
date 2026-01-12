package Wordsmith::Claude::Blog::Reviewer::Interactive;

use 5.020;
use strict;
use warnings;
use utf8;

use Claude::Agent::CLI qw(
    with_spinner
    header divider status
    prompt ask_yn menu
);
use Wordsmith::Claude::Blog::Reviewer;
use Wordsmith::Claude::Blog::Result;
use Wordsmith::Claude::Options;
use Future::AsyncAwait;
use IO::Async::Loop;
use Types::Standard qw(Str);

use Marlin
    'file?'       => Str,
    'text?'       => Str,
    'title?'      => Str,
    'options?'    => sub { Wordsmith::Claude::Options->new() },
    'loop?'       => sub { IO::Async::Loop->new };

=head1 NAME

Wordsmith::Claude::Blog::Reviewer::Interactive - Interactive terminal UI for blog reviewing

=head1 SYNOPSIS

    use Wordsmith::Claude::Blog::Reviewer::Interactive;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    # Review from file
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        file => 'my-blog.md',
        loop => $loop,
    );

    # Or review text directly
    my $interactive = Wordsmith::Claude::Blog::Reviewer::Interactive->new(
        text  => $blog_text,
        title => 'My Blog Post',
        loop  => $loop,
    );

    my $result = $interactive->run->get;

    if ($result->is_success) {
        print $result->text;
    }

=head1 DESCRIPTION

Provides an interactive terminal UI for the Blog::Reviewer, featuring:

=over 4

=item * Colored headers and status messages

=item * Paragraph-by-paragraph display with AI analysis

=item * Interactive menu for approve/revise/edit/skip actions

=item * Multiple revision options (grammar, clarity, conciseness, etc.)

=item * Manual editing with external editor support

=item * Live progress saving to file

=back

=cut

async sub run {
    my ($self) = @_;

    header("Interactive Blog Reviewer");

    # Load text from file or use provided text
    my ($text, $source_file, $title) = $self->_load_input();

    unless ($text) {
        status('error', "No text to review. Provide 'file' or 'text' parameter.");
        return Wordsmith::Claude::Blog::Result->new(
            topic    => 'Error',
            title    => '',
            text     => '',
            metadata => { error => 'No input provided' },
        );
    }

    status('info', "Reviewing: " . ($title // 'Untitled'));
    status('info', "Source: " . ($source_file // 'memory'));
    print "\n";

    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text        => $text,
        title       => $title,
        source_file => $source_file,
        options     => $self->options,
        loop        => $self->loop,

        on_paragraph => sub {
            my ($para, $analysis, $num, $total) = @_;
            return $self->_handle_paragraph($para, $analysis, $num, $total);
        },

        on_progress => sub {
            my ($current, $total) = @_;
            status('info', "Progress: $current/$total paragraphs");
        },

        on_complete => sub {
            my ($final_text) = @_;
            print "\n";
            header("Review Complete!");
            status('success', "Blog review finished");
        },
    );

    return await $reviewer->review;
}

sub _load_input {
    my ($self) = @_;

    my $text;
    my $source_file;
    my $title = $self->title;

    if ($self->file) {
        $source_file = $self->file;
        if (open my $fh, '<:encoding(UTF-8)', $source_file) {
            $text = do { local $/; <$fh> };
            close $fh;

            # Extract title from first markdown heading if not provided
            if (!$title && $text =~ /^#\s+(.+)$/m) {
                $title = $1;
            }
        } else {
            status('error', "Cannot open file: $source_file");
            return (undef, undef, undef);
        }
    } elsif ($self->text) {
        $text = $self->text;
    }

    return ($text, $source_file, $title);
}

sub _handle_paragraph {
    my ($self, $para, $analysis, $num, $total) = @_;

    # Display paragraph
    header("Paragraph $num of $total");

    my $is_code = ($para =~ /^```/);
    if ($is_code) {
        print "--- CODE BLOCK ---\n";
    }
    print $para, "\n\n";
    divider();

    # Display analysis
    print "AI Analysis:\n";
    print $analysis, "\n\n";
    divider();

    # Get user decision
    return $self->_get_user_decision($para, $is_code);
}

sub _get_user_decision {
    my ($self, $para, $is_code) = @_;

    my $choice = menu("Action", [
        { key => 'a', label => 'Approve this paragraph' },
        { key => 'r', label => 'Revise with AI' },
        { key => 'e', label => 'Edit manually' },
        { key => 's', label => 'Skip/delete paragraph' },
    ]);

    if ($choice eq 'a') {
        status('success', "Paragraph approved");
        return { action => 'approve' };
    }
    elsif ($choice eq 'r') {
        return $self->_get_revision_instructions($is_code);
    }
    elsif ($choice eq 'e') {
        return $self->_manual_edit($para);
    }
    elsif ($choice eq 's') {
        if (ask_yn("Are you sure you want to delete this paragraph?", 'n')) {
            status('warning', "Paragraph deleted");
            return { action => 'skip' };
        }
        # User changed mind, recurse
        return $self->_get_user_decision($para, $is_code);
    }

    # Default to approve
    return { action => 'approve' };
}

sub _get_revision_instructions {
    my ($self, $is_code) = @_;

    my @options;
    if ($is_code) {
        @options = (
            { key => '1', label => 'Fix syntax errors' },
            { key => '2', label => 'Improve readability' },
            { key => '3', label => 'Add comments' },
            { key => '4', label => 'Optimize performance' },
            { key => '5', label => 'Follow best practices' },
            { key => '6', label => 'Custom instructions' },
        );
    } else {
        @options = (
            { key => '1', label => 'Fix grammar and spelling' },
            { key => '2', label => 'Improve clarity' },
            { key => '3', label => 'Make more concise' },
            { key => '4', label => 'Expand with more detail' },
            { key => '5', label => 'Adjust tone' },
            { key => '6', label => 'Custom instructions' },
        );
    }

    my $rev_choice = menu("Revision type", \@options);

    my %instructions;
    if ($is_code) {
        %instructions = (
            '1' => 'Fix any syntax errors or typos in this code',
            '2' => 'Improve the readability and structure of this code',
            '3' => 'Add helpful comments to explain the code',
            '4' => 'Optimize this code for better performance',
            '5' => 'Refactor to follow best practices and idioms',
        );
    } else {
        %instructions = (
            '1' => 'Fix any grammar, spelling, or punctuation errors',
            '2' => 'Rewrite for improved clarity and flow',
            '3' => 'Make this more concise while preserving meaning',
            '4' => 'Expand this with more detail and examples',
            '5' => 'Adjust the tone to be more professional/casual',
        );
    }

    my $instruction;
    if ($rev_choice eq '6') {
        $instruction = prompt("Enter your revision instructions:");
    } else {
        $instruction = $instructions{$rev_choice} // 'Improve this paragraph';
    }

    status('info', "Revising: $instruction");
    return { action => 'revise', instructions => $instruction };
}

sub _manual_edit {
    my ($self, $para) = @_;

    # Try to use external editor
    my $editor = $ENV{EDITOR} || $ENV{VISUAL} || 'vim';
    my $tmpfile = "/tmp/blog-review-$$.txt";

    # Write current paragraph to temp file
    if (open my $tmp, '>:encoding(UTF-8)', $tmpfile) {
        print $tmp $para;
        close $tmp;

        status('info', "Opening editor: $editor");

        # Open editor
        system($editor, $tmpfile);

        # Read back edited content
        if (-f $tmpfile && open my $in, '<:encoding(UTF-8)', $tmpfile) {
            my $edited = do { local $/; <$in> };
            close $in;
            $edited =~ s/^\s+|\s+$//g;
            unlink $tmpfile;

            if ($edited ne $para) {
                status('success', "Paragraph edited");
                return { action => 'replace', content => $edited };
            } else {
                status('info', "No changes made");
                return { action => 'approve' };
            }
        }
        unlink $tmpfile if -f $tmpfile;
    }

    status('warning', "Edit failed, keeping original");
    return { action => 'approve' };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
