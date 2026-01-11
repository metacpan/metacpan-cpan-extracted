package Wordsmith::Claude;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(rewrite question);

use Claude::Agent qw(query);
use Claude::Agent::Options;
use Wordsmith::Claude::Options;
use Wordsmith::Claude::Result;
use Wordsmith::Claude::Mode;
use Future::AsyncAwait;
use IO::Async::Loop;
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

=head1 NAME

Wordsmith::Claude - AI-powered text rewriting with style

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Wordsmith::Claude qw(rewrite question);
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    # Simple mode-based rewriting
    my $result = rewrite(
        text => "The quantum entanglement phenomenon demonstrates non-local correlations",
        mode => 'eli5',
        loop => $loop,
    )->get;

    print $result->text;
    # "It's like having two magic coins that always match, even far apart!"

    # Different tones
    my $formal = rewrite(text => $casual_message, mode => 'formal', loop => $loop)->get;
    my $casual = rewrite(text => $business_email, mode => 'casual', loop => $loop)->get;

    # Fun styles
    my $pirate = rewrite(text => $boring, mode => 'pirate', loop => $loop)->get;
    my $shakespeare = rewrite(text => $modern, mode => 'shakespeare', loop => $loop)->get;

    # Custom instructions
    my $custom = rewrite(
        text => $text,
        instruction => "Rewrite as a nature documentary narrator",
        loop => $loop,
    )->get;

    # Multiple variations
    my $result = rewrite(
        text => $text,
        mode => 'casual',
        variations => 3,
        loop => $loop,
    )->get;

    print $_->text for $result->all_variations;

    # Ask questions about text
    my $answer = question(
        text     => $essay,
        question => "What is the main argument?",
        loop     => $loop,
    )->get;

    print $answer->text;

    # Ask general questions (no context)
    my $answer = question(
        question => "What is the capital of France?",
        loop     => $loop,
    )->get;

    # Parallel requests (non-blocking)
    my $f1 = rewrite(text => $text1, mode => 'eli5', loop => $loop);
    my $f2 = rewrite(text => $text2, mode => 'formal', loop => $loop);
    my $f3 = question(question => "What is 2+2?", loop => $loop);

    # Wait for all to complete
    use Future;
    my @results = Future->needs_all($f1, $f2, $f3)->get;

=head1 DESCRIPTION

Wordsmith::Claude is an AI-powered text rewriting tool built on the Claude Agent SDK.
It can transform text into different styles, tones, and complexity levels.

=head1 BUILT-IN MODES

=head2 Complexity

=over 4

=item * C<eli5> - Explain Like I'm 5 (very simple)

=item * C<eli10> - Explain Like I'm 10 (simple but more detail)

=item * C<technical> - Add technical precision and jargon

=back

=head2 Tone

=over 4

=item * C<formal> - Professional, business-appropriate

=item * C<casual> - Relaxed, conversational

=item * C<friendly> - Warm and approachable

=item * C<professional> - Polished and authoritative

=back

=head2 Length/Format

=over 4

=item * C<concise> - Trim to essentials

=item * C<expand> - Add detail and explanation

=item * C<bullets> - Convert to bullet points

=item * C<summarize> - Brief summary

=back

=head2 Fun Styles

=over 4

=item * C<pirate> - Arr, talk like a pirate!

=item * C<shakespeare> - Forsooth, in the Bard's tongue

=item * C<yoda> - Speak like Yoda, you will

=item * C<corporate> - Synergize the paradigm shift

=item * C<valley> - Like, totally rewrite it

=back

=head2 Utility

=over 4

=item * C<proofread> - Fix grammar and spelling

=back

=head1 EXPORTED FUNCTIONS

=head2 rewrite

    my $result = rewrite(
        text        => $input_text,       # Required
        mode        => 'eli5',            # Built-in mode (optional)
        instruction => 'custom prompt',   # Custom instruction (optional)
        variations  => 3,                 # Number of variations (default 1)
        options     => $options_obj,      # Wordsmith::Claude::Options (optional)
        loop        => $loop,             # IO::Async::Loop (optional)
    )->get;

Rewrite text using a mode or custom instruction. Returns a Future that resolves
to a L<Wordsmith::Claude::Result> object.

Either C<mode> or C<instruction> must be provided.

=cut

async sub rewrite {
    my (%args) = @_;

    my $text = $args{text} // die "rewrite() requires 'text' argument";
    my $mode = $args{mode};
    my $instruction = $args{instruction};
    my $variations = $args{variations} // 1;
    my $options = $args{options} // Wordsmith::Claude::Options->new();
    my $loop = $args{loop} // IO::Async::Loop->new;

    unless ($mode || $instruction) {
        die "rewrite() requires either 'mode' or 'instruction' argument";
    }

    # Build the prompt
    my $prompt = _build_prompt($text, $mode, $instruction, $variations);

    # Build Claude options
    my $claude_opts = Claude::Agent::Options->new(
        permission_mode => 'bypassPermissions',
        $options->has_model ? (model => $options->model) : (),
    );

    # Run query
    my $iter = query(
        prompt  => $prompt,
        options => $claude_opts,
        loop    => $loop,
    );

    # Collect result
    my $result_text;
    while (my $msg = await $iter->next_async) {
        if (blessed($msg) && $msg->isa('Claude::Agent::Message::Result')) {
            $result_text = $msg->result;
            last;
        }
    }

    unless ($result_text) {
        return Wordsmith::Claude::Result->new(
            original => $text,
            text     => '',
            error    => $iter->error // 'No result received',
        );
    }

    # Parse variations if requested
    my @variations;
    if ($variations > 1) {
        @variations = _parse_variations($result_text, $variations);
    }

    return Wordsmith::Claude::Result->new(
        original   => $text,
        text       => $variations > 1 ? $variations[0] : $result_text,
        ($mode ? (mode => $mode) : ()),
        (@variations ? (variations => \@variations) : ()),
    );
}

sub _build_prompt {
    my ($text, $mode, $instruction, $variations) = @_;

    my $system_instruction;

    if ($mode) {
        $system_instruction = Wordsmith::Claude::Mode->get_instruction($mode);
        die "Unknown mode: $mode" unless $system_instruction;
    } else {
        $system_instruction = $instruction;
    }

    my $prompt = "Rewrite the following text.\n\n";
    $prompt .= "Instructions: $system_instruction\n\n";

    if ($variations > 1) {
        $prompt .= "Provide $variations different variations, numbered 1) 2) 3) etc.\n\n";
    }

    $prompt .= "Text to rewrite:\n\"\"\"$text\"\"\"\n\n";

    if ($variations > 1) {
        $prompt .= "Output $variations numbered variations:";
    } else {
        $prompt .= "Output only the rewritten text, no explanation:";
    }

    return $prompt;
}

sub _parse_variations {
    my ($text, $count) = @_;

    my @variations;

    # Try to parse numbered variations like "1) ..." or "1. ..."
    while ($text =~ /(?:^|\n)\s*\d+[\)\.]\s*(.+?)(?=\n\s*\d+[\)\.]\s*|\z)/gs) {
        push @variations, $1;
    }

    # If parsing failed, just return the whole text as one variation
    if (@variations == 0) {
        return ($text);
    }

    return @variations;
}

=head2 question

    my $result = question(
        question => "What is the capital of France?",  # Required
        text     => $context_text,                      # Optional context
        options  => $options_obj,                       # Optional
        loop     => $loop,                              # Optional
    )->get;

    # With context
    my $result = question(
        text     => $essay,
        question => "What is the main argument?",
        loop     => $loop,
    )->get;

    print $result->text;  # The answer

Ask a question, optionally about provided text context. Returns a Future that
resolves to a L<Wordsmith::Claude::Result> object.

=cut

async sub question {
    my (%args) = @_;

    my $question = $args{question} // die "question() requires 'question' argument";
    my $text = $args{text};
    my $options = $args{options} // Wordsmith::Claude::Options->new();
    my $loop = $args{loop} // IO::Async::Loop->new;

    # Build the prompt
    my $prompt;
    if ($text) {
        $prompt = "Given the following text:\n\n\"\"\"$text\"\"\"\n\n";
        $prompt .= "Answer this question: $question\n\n";
        $prompt .= "Provide a clear, direct answer:";
    } else {
        $prompt = "$question\n\nProvide a clear, direct answer:";
    }

    # Build Claude options
    my $claude_opts = Claude::Agent::Options->new(
        permission_mode => 'bypassPermissions',
        $options->has_model ? (model => $options->model) : (),
    );

    # Run query
    my $iter = query(
        prompt  => $prompt,
        options => $claude_opts,
        loop    => $loop,
    );

    # Collect result
    my $result_text;
    while (my $msg = await $iter->next_async) {
        if (blessed($msg) && $msg->isa('Claude::Agent::Message::Result')) {
            $result_text = $msg->result;
            last;
        }
    }

    unless ($result_text) {
        return Wordsmith::Claude::Result->new(
            original => $text // '',
            text     => '',
            error    => $iter->error // 'No result received',
        );
    }

    return Wordsmith::Claude::Result->new(
        original => $text // '',
        text     => $result_text,
    );
}

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent> - The underlying Claude Agent SDK

=item * L<Wordsmith::Claude::Options> - Configuration options

=item * L<Wordsmith::Claude::Result> - Result object

=item * L<Wordsmith::Claude::Mode> - Built-in mode definitions

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
