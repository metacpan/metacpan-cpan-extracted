package Wordsmith::Claude::Blog::Reviewer;

use 5.020;
use strict;
use warnings;
use utf8;

use Claude::Agent qw(session);
use Claude::Agent::Options;
use Wordsmith::Claude::Options;
use Wordsmith::Claude::Blog::Result;
use Future::AsyncAwait;
use IO::Async::Loop;
use Scalar::Util qw(blessed);
use Types::Standard qw(Str CodeRef);

use Marlin
    'text!'           => Str,
    'title?'          => Str,
    'source_file?'    => Str,
    'options?'        => sub { Wordsmith::Claude::Options->new() },
    'loop?'           => sub { IO::Async::Loop->new },
    # Callbacks
    'on_paragraph?'   => CodeRef,
    'on_progress?'    => CodeRef,
    'on_complete?'    => CodeRef,
    # Internal
    '_client==.';

=head1 NAME

Wordsmith::Claude::Blog::Reviewer - AI-powered blog paragraph reviewer

=head1 SYNOPSIS

    use Wordsmith::Claude::Blog::Reviewer;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    my $reviewer = Wordsmith::Claude::Blog::Reviewer->new(
        text        => $blog_text,
        title       => 'My Blog Post',
        source_file => 'blog.md',  # For live progress saving
        loop        => $loop,

        on_paragraph => sub {
            my ($para, $analysis, $num, $total) = @_;
            print "Paragraph $num/$total\n";
            print "Analysis: $analysis\n";
            # Return decision hashref
            return { action => 'approve' };
        },

        on_progress => sub {
            my ($current, $total) = @_;
            print "Progress: $current/$total\n";
        },
    );

    my $result = $reviewer->review->get;
    print $result->text;

=head1 DESCRIPTION

Reviews blog posts paragraph by paragraph, providing AI analysis of content
validity and grammar quality. Supports:

=over 4

=item * Paragraph-by-paragraph review with AI analysis

=item * Code block detection with specialized analysis

=item * Multiple revision options (grammar, clarity, conciseness, etc.)

=item * Live file updates for progress saving

=item * Callback-based workflow for UI integration

=back

=head1 CALLBACKS

=head2 on_paragraph

    on_paragraph => sub {
        my ($paragraph, $analysis, $num, $total) = @_;
        # Return a decision hashref
        return { action => 'approve' };
        # Or: { action => 'revise', instructions => '...' }
        # Or: { action => 'replace', content => '...' }
        # Or: { action => 'skip' }
    }

Called for each paragraph with the AI analysis. Must return a decision hashref.

=head2 on_progress

    on_progress => sub {
        my ($current, $total) = @_;
    }

Called after each paragraph is processed.

=head2 on_complete

    on_complete => sub {
        my ($final_text) = @_;
    }

Called when review is complete.

=cut

async sub review {
    my ($self) = @_;

    my @paragraphs = $self->_parse_paragraphs($self->text);
    my @reviewed;
    my @pending = @paragraphs;

    for my $i (0 .. $#paragraphs) {
        my $para = $paragraphs[$i];
        shift @pending;

        my $is_code = ($para =~ /^```/);

        # Analyze paragraph
        my $analysis = await $self->_analyze($para, $is_code, \@reviewed);

        # Get user decision via callback or default
        my $decision;
        if ($self->has_on_paragraph) {
            $decision = $self->on_paragraph->($para, $analysis, $i+1, scalar(@paragraphs));
        } else {
            $decision = { action => 'approve' };
        }

        # Validate decision
        $decision //= { action => 'approve' };
        $decision = { action => 'approve' } unless ref($decision) eq 'HASH';
        $decision->{action} //= 'approve';

        # Process decision
        if ($decision->{action} eq 'approve') {
            push @reviewed, $para;
        }
        elsif ($decision->{action} eq 'revise') {
            my $revised = await $self->_revise($para, $decision->{instructions} // '');
            push @reviewed, $revised;
        }
        elsif ($decision->{action} eq 'replace') {
            push @reviewed, $decision->{content} // $para;
        }
        elsif ($decision->{action} eq 'skip') {
            # Don't add to reviewed
        }
        else {
            # Unknown action, default to approve
            push @reviewed, $para;
        }

        # Progress callback
        $self->on_progress->($i+1, scalar(@paragraphs)) if $self->has_on_progress;

        # Save progress if source file specified
        $self->_save_progress(\@reviewed, \@pending) if $self->source_file;
    }

    # Cleanup session
    $self->_cleanup_session();

    # Assemble final text
    my $final_text = $self->_assemble(\@reviewed);

    # Complete callback
    $self->on_complete->($final_text) if $self->has_on_complete;

    return Wordsmith::Claude::Blog::Result->new(
        topic    => $self->title // 'Reviewed Blog',
        title    => $self->title // '',
        text     => $final_text,
        metadata => {
            paragraph_count => scalar(@reviewed),
            original_count  => scalar(@paragraphs),
        },
    );
}

sub _parse_paragraphs {
    my ($self, $text) = @_;

    my @paragraphs;
    my @lines = split /\n/, $text;
    my $current_para = '';
    my $in_code_block = 0;

    for my $line (@lines) {
        # Track code block state
        if ($line =~ /^```/) {
            $in_code_block = !$in_code_block;
            $current_para .= "$line\n";
            next;
        }

        if ($in_code_block) {
            # Inside code block - keep accumulating
            $current_para .= "$line\n";
        }
        elsif ($line =~ /^\s*$/) {
            # Empty line outside code block - paragraph break
            if ($current_para =~ /\S/) {
                $current_para =~ s/^\s+|\s+$//g;
                push @paragraphs, $current_para;
                $current_para = '';
            }
        }
        else {
            # Regular content line
            $current_para .= "$line\n";
        }
    }

    # Don't forget the last paragraph
    if ($current_para =~ /\S/) {
        $current_para =~ s/^\s+|\s+$//g;
        push @paragraphs, $current_para;
    }

    return @paragraphs;
}

async sub _analyze {
    my ($self, $paragraph, $is_code, $previous) = @_;

    my $context = '';
    if ($self->title) {
        $context .= "Blog title: " . $self->title . "\n";
    }
    if (@$previous) {
        $context .= "Previous paragraphs reviewed:\n";
        my $count = 0;
        for my $p (@$previous) {
            $count++;
            my $preview = substr($p, 0, 100);
            $preview .= '...' if length($p) > 100;
            $context .= "  $count. $preview\n";
        }
    }

    my $prompt;
    if ($is_code) {
        $prompt = <<"END";
Analyze this code block from a blog post for correctness and quality.

$context

CODE BLOCK TO ANALYZE:
"""
$paragraph
"""

Provide a brief analysis covering:
1. SYNTAX: Any syntax errors or typos in the code?
2. CORRECTNESS: Does the code look functionally correct?
3. BEST PRACTICES: Any obvious improvements or anti-patterns?
4. CLARITY: Is the code readable and well-structured?
5. SUGGESTIONS: 1-2 specific improvements (if any needed)

Keep the analysis concise (5-8 lines). If the code looks good, say so briefly.
END
    }
    else {
        $prompt = <<"END";
Analyze this blog paragraph for content validity and grammar quality.

$context

PARAGRAPH TO ANALYZE:
"""
$paragraph
"""

Provide a brief analysis covering:
1. CONTENT: Is the information accurate and relevant? Any factual concerns?
2. GRAMMAR: Any spelling, grammar, or punctuation issues?
3. CLARITY: Is it clear and easy to understand?
4. FLOW: Does it connect well with the overall blog context?
5. SUGGESTIONS: 1-2 specific improvements (if any needed)

Keep the analysis concise (5-8 lines). If the paragraph is good, say so briefly.
END
    }

    return await $self->_query($prompt, !$self->_client);
}

async sub _revise {
    my ($self, $paragraph, $instructions) = @_;

    my $prompt = <<"END";
Revise this paragraph according to the instructions.

INSTRUCTIONS: $instructions

ORIGINAL PARAGRAPH:
"""
$paragraph
"""

Output ONLY the revised paragraph. No explanations, no commentary, no quotes around it.
Apply the requested changes while maintaining the paragraph's core message.
END

    return await $self->_query($prompt);
}

sub _save_progress {
    my ($self, $reviewed, $pending) = @_;

    return unless $self->source_file;

    my $content = '';
    $content = "# " . $self->title . "\n\n" if $self->title;
    $content .= join("\n\n", @$reviewed);

    # Add remaining unreviewed paragraphs
    if (@$pending) {
        $content .= "\n\n" if @$reviewed;
        $content .= join("\n\n", @$pending);
    }

    if (open my $fh, '>:encoding(UTF-8)', $self->source_file) {
        print $fh $content;
        close $fh;
    }
}

sub _assemble {
    my ($self, $paragraphs) = @_;

    my $text = '';
    $text = "# " . $self->title . "\n\n" if $self->title;
    $text .= join("\n\n", @$paragraphs);

    return $text;
}

sub _init_session {
    my ($self) = @_;

    return if $self->_client;

    my $claude_opts = Claude::Agent::Options->new(
        permission_mode => $self->options->permission_mode // 'bypassPermissions',
        $self->options->has_model ? (model => $self->options->model) : (),
    );

    $self->_client(session(
        options => $claude_opts,
        loop    => $self->loop,
    ));
}

sub _cleanup_session {
    my ($self) = @_;
    if ($self->_client) {
        $self->_client->disconnect;
        $self->_client(undef);
    }
}

async sub _query {
    my ($self, $prompt, $is_first) = @_;

    $self->_init_session();

    my $client = $self->_client;

    if ($is_first || !$client->is_connected) {
        $client->connect($prompt);
    } else {
        $client->send($prompt);
    }

    my $result_text;
    while (my $msg = await $client->receive_async) {
        if (blessed($msg) && $msg->isa('Claude::Agent::Message::Result')) {
            $result_text = $msg->result;
            last;
        }
    }

    return $result_text // '';
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
