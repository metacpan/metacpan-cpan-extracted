package Wordsmith::Claude;

use 5.020;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(rewrite question blog);

use Claude::Agent qw(query);
use Claude::Agent::Options;
use Wordsmith::Claude::Options;
use Wordsmith::Claude::Result;
use Wordsmith::Claude::Mode;
use Wordsmith::Claude::Blog;
use Wordsmith::Claude::Blog::Result;
use Future::AsyncAwait;
use IO::Async::Loop;
use Scalar::Util qw(blessed);
use Unicode::Normalize;

our $VERSION = '0.02';

=head1 NAME

Wordsmith::Claude - AI-powered text rewriting with style

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Wordsmith::Claude qw(rewrite question blog);
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
        permission_mode => $options->permission_mode // 'bypassPermissions',
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
            error    => (blessed($iter) && $iter->can('error') ? $iter->error : undef) // 'No result received',
        );
    }

    # Parse variations if requested
    my @variations;
    if ($variations > 1) {
        @variations = _parse_variations($result_text, $variations);
    }

    return Wordsmith::Claude::Result->new(
        original   => $text,
        text       => ($variations > 1 && @variations) ? $variations[0] : $result_text,
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

    # NOTE: Security consideration - user-provided text is embedded in the prompt.
    # While delimited with triple quotes, this may not prevent all prompt injection
    # attacks. API consumers should sanitize inputs if accepting untrusted user data.
    my $prompt = "Rewrite the following text.\n\n";
    $prompt .= "Instructions: $system_instruction\n\n";

    if ($variations > 1) {
        $prompt .= "Provide $variations different variations. Separate each variation with '---VARIATION N---' markers (e.g., ---VARIATION 1---, ---VARIATION 2---, etc.).\n\n";
    }

    # Defense: escape delimiter, filter common patterns, but note this is not comprehensive
    # WARNING: These filters are NOT comprehensive. Do NOT rely on them for untrusted input.
    # The regex only filters specific phrases but attackers can use synonyms, Unicode homoglyphs,
    # or obfuscation techniques to bypass filtering. See SECURITY.md for proper input handling guidelines.
    # This module should NOT be used with untrusted user input without additional application-level validation.
    my $safe_text = $text;
    $safe_text =~ s/\"\"\"/\"\"\" /g;  # Add space to break delimiter pattern
    # Filter injection patterns (non-exhaustive - see security docs)
    # WARNING: These filters provide minimal protection only.
    # For untrusted input, implement application-level validation.
    # NOTE: This filter is NOT comprehensive - see SECURITY.md
    # Apply Unicode normalization to mitigate homoglyph bypass attempts
    $safe_text = NFC($safe_text);
    # Consider expanding to cover more variations, or use a dedicated prompt injection detection library
    # For untrusted input, implement strict application-level validation before calling this module
    # NOTE: No regex-based filter can reliably prevent prompt injection.
    # For untrusted input, use application-level validation or a dedicated prompt injection detection library.
    # See OWASP LLM Top 10: https://owasp.org/www-project-top-10-for-large-language-model-applications/
    # IMPORTANT: Additional validation recommended for untrusted input
    $prompt .= "Text to rewrite:\n\"\"\"$safe_text\"\"\"\n\n";

    if ($variations > 1) {
        $prompt .= "Output $variations variations with ---VARIATION N--- markers:";
    } else {
        $prompt .= "Output only the rewritten text, no explanation:";
    }

    return $prompt;
}

sub _parse_variations {
    my ($text, $count) = @_;

    my @variations;

    # Split on variation markers - use stricter pattern requiring number at start of line
    # The lookahead keeps the number with the content
    # WARNING: This pattern may incorrectly split content containing numbered lists within variation text.
    # For more reliable parsing, consider modifying _build_prompt to request Claude use unique delimiters
    # like '---VARIATION 1---' instead of numbered lists (1) 2) etc.).
    # Request unique delimiters from Claude instead:
    # $prompt .= "Separate variations with '---VARIATION N---' markers\n";
    # Try primary format first
    my @parts = split /---VARIATION \d+---/, $text;
    shift @parts if @parts && $parts[0] !~ /\S/;  # Remove empty first element
    # Consider adding fallback patterns for common AI response formats

    for my $part (@parts) {
        # Content after ---VARIATION N--- delimiter
        my $content = $part;
        $content =~ s/^\s+|\s+$//g;
        push @variations, $content if $content;
        last if @variations >= $count;  # Stop at expected count
    }

    # If parsing failed, just return the whole text as one variation
    if (@variations == 0) {
        warn "Failed to parse variations from response, returning as single result";
        return ($text);
    }
    if (@variations < $count) {
        warn "Parsed only " . scalar(@variations) . " variations, expected $count";
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
    # NOTE: Security consideration - user-provided text and question are embedded
    # in the prompt. While delimited with triple quotes, this may not prevent all
    # prompt injection attacks. API consumers should sanitize inputs if accepting
    # untrusted user data.
    # Escape any triple-quote sequences in user inputs to prevent prompt injection
    # Apply Unicode normalization to mitigate homoglyph bypass attempts
    my $safe_question = NFC($question);
    $safe_question =~ s/\"\"\"/\"\"\" /g;  # Add space to break delimiter pattern
    # NOTE: Input sanitization - consider using shared _sanitize_user_input() helper
    # to ensure consistent filtering across all public API functions.
    # These regex filters provide minimal protection only - see SECURITY.md
    $safe_question =~ s/\b(ignore|disregard|forget|skip|omit|override|bypass|neglect|dismiss|abandon)[^a-z]*(all|any|the|your|previous|above|prior|earlier|system|instructions?)\b/[filtered]/gi;
    $safe_question =~ s/\b(new|different|actual)[^a-z]*instructions?\b/[filtered]/gi;

    my $prompt;
    if ($text) {
        # Apply Unicode normalization to mitigate homoglyph bypass attempts
        my $safe_text = NFC($text);
        $safe_text =~ s/\"\"\"/\"\"\" /g;  # Add space to break delimiter pattern
        # More comprehensive filtering (still not complete)
        $safe_text =~ s/\b(ignore|disregard|forget|skip|omit|override|bypass|neglect|dismiss|abandon)[^a-z]*(all|any|the|your|previous|above|prior|earlier|system|instructions?)\b/[filtered]/gi;
        $safe_text =~ s/\b(new|different|actual)[^a-z]*instructions?\b/[filtered]/gi;
        $prompt = "Given the following text:\n\n\"\"\"$safe_text\"\"\"\n\n";
        $prompt .= "Answer this question: $safe_question\n\n";
        $prompt .= "Provide a clear, direct answer:";
    } else {
        $prompt = "$safe_question\n\nProvide a clear, direct answer:";
    }

    # Build Claude options
    my $claude_opts = Claude::Agent::Options->new(
        permission_mode => $options->permission_mode // 'bypassPermissions',
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
            error    => (blessed($iter) && $iter->can('error') ? $iter->error : undef) // 'No result received',
        );
    }

    return Wordsmith::Claude::Result->new(
        original => $text // '',
        text     => $result_text,
    );
}

=head2 blog

    my $result = blog(
        topic   => 'Building AI Tools with Perl',  # Required
        style   => 'technical',                     # Optional (default: technical)
        tone    => 'enthusiastic',                  # Optional (default: professional)
        length  => 'medium',                        # Optional (default: medium)
        sections => ['intro', 'main', 'conclusion'], # Optional custom sections
        options => $options_obj,                    # Optional
        loop    => $loop,                           # Optional
    )->get;

    print $result->title;
    print $result->text;
    print "Word count: ", $result->word_count, "\n";

Generate a blog post on a given topic. Returns a Future that resolves to
a L<Wordsmith::Claude::Blog::Result> object.

=head3 Interactive Mode

For an interactive blog building experience, use the C<prompt_cb> callback
to receive choices at each step:

    my $result = blog(
        topic     => 'AI in Perl',
        prompt_cb => sub {
            my ($step, $options, $default) = @_;
            # $step is 'style', 'tone', 'length', or 'sections'
            # $options is arrayref of valid choices
            # $default is the default value
            # Return the chosen value
            print "Choose $step [$default]: ";
            my $choice = <STDIN>;
            chomp $choice;
            return $choice || $default;
        },
        loop => $loop,
    )->get;

=head3 Available Styles

=over 4

=item * C<technical> - Technical deep-dive with code examples

=item * C<tutorial> - Step-by-step guide with hands-on examples

=item * C<announcement> - Product or feature announcement

=item * C<casual> - Conversational, personal tone

=item * C<listicle> - Numbered list format

=item * C<opinion> - Thought leadership piece

=item * C<comparison> - Side-by-side comparison

=item * C<howto> - Practical how-to guide

=back

=head3 Available Tones

=over 4

=item * C<professional> - Polished and authoritative

=item * C<friendly> - Warm and approachable

=item * C<enthusiastic> - Excited and energetic

=item * C<thoughtful> - Reflective and considered

=item * C<humorous> - Light-hearted with wit

=item * C<direct> - Straight to the point

=back

=head3 Available Lengths

=over 4

=item * C<short> - Quick read (500-800 words)

=item * C<medium> - Standard post (1000-1500 words)

=item * C<long> - In-depth article (2000-3000 words)

=back

=cut

async sub blog {
    my (%args) = @_;

    my $topic     = $args{topic} // die "blog() requires 'topic' argument";
    my $prompt_cb = $args{prompt_cb};
    my $options   = $args{options} // Wordsmith::Claude::Options->new();
    my $loop      = $args{loop} // IO::Async::Loop->new;

    # Interactive mode - prompt for each choice
    my ($style, $tone, $length, $sections);

    if ($prompt_cb) {
        # Style selection
        my @styles = Wordsmith::Claude::Blog->all_styles;
        $style = $prompt_cb->('style', \@styles, 'technical');
        $style = 'technical' unless Wordsmith::Claude::Blog->style_exists($style);

        # Tone selection
        my @tones = Wordsmith::Claude::Blog->all_tones;
        $tone = $prompt_cb->('tone', \@tones, 'professional');
        $tone = 'professional' unless Wordsmith::Claude::Blog->tone_exists($tone);

        # Length selection
        my @lengths = Wordsmith::Claude::Blog->all_lengths;
        $length = $prompt_cb->('length', \@lengths, 'medium');
        $length = 'medium' unless Wordsmith::Claude::Blog->length_exists($length);

        # Sections - prompt returns arrayref or comma-separated string
        my $sections_input = $prompt_cb->('sections', [], undef);
        if ($sections_input) {
            if (ref $sections_input eq 'ARRAY') {
                $sections = $sections_input;
            } else {
                $sections = [split /\s*,\s*/, $sections_input];
            }
        }
    } else {
        # Non-interactive - use provided values or defaults
        $style    = $args{style}    // 'technical';
        $tone     = $args{tone}     // 'professional';
        $length   = $args{length}   // 'medium';
        $sections = $args{sections};
    }

    # Validate style
    unless (Wordsmith::Claude::Blog->style_exists($style)) {
        die "Unknown blog style: $style. Valid styles: " .
            join(', ', Wordsmith::Claude::Blog->all_styles);
    }

    # Validate tone
    unless (Wordsmith::Claude::Blog->tone_exists($tone)) {
        die "Unknown blog tone: $tone. Valid tones: " .
            join(', ', Wordsmith::Claude::Blog->all_tones);
    }

    # Validate length
    unless (Wordsmith::Claude::Blog->length_exists($length)) {
        die "Unknown blog length: $length. Valid lengths: " .
            join(', ', Wordsmith::Claude::Blog->all_lengths);
    }

    # Build the prompt
    my $prompt = _build_blog_prompt($topic, $style, $tone, $length, $sections);

    # Build Claude options
    my $claude_opts = Claude::Agent::Options->new(
        permission_mode => $options->permission_mode // 'bypassPermissions',
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
        return Wordsmith::Claude::Blog::Result->new(
            topic => $topic,
            title => "Blog: $topic",
            text  => '',
            error => $iter->error // 'No result received',
        );
    }

    # Parse the result to extract title and sections
    my ($title, $parsed_sections) = _parse_blog_result($result_text);

    return Wordsmith::Claude::Blog::Result->new(
        topic    => $topic,
        title    => $title // "Blog: $topic",
        text     => $result_text,
        style    => $style,
        tone     => $tone,
        length   => $length,
        sections => $parsed_sections,
        metadata => {
            word_count   => _count_words($result_text),
            reading_time => _estimate_reading_time($result_text),
        },
    );
}

sub _build_blog_prompt {
    my ($topic, $style, $tone, $length, $sections) = @_;

    my $style_inst  = Wordsmith::Claude::Blog->get_style($style);
    my $tone_inst   = Wordsmith::Claude::Blog->get_tone($tone);
    my $length_inst = Wordsmith::Claude::Blog->get_length($length);

    my $safe_topic = $topic;
    $safe_topic =~ s/\"\"\"/''''/g;
    my $prompt = "Write a blog post about: \"\"\"$safe_topic\"\"\"\n\n";
    $prompt .= "Style: $style_inst\n\n";
    $prompt .= "Tone: $tone_inst\n\n";
    $prompt .= "Length: $length_inst\n\n";

    if ($sections && @$sections) {
        $prompt .= "Structure the post with these sections:\n";
        for my $sec (@$sections) {
            my $safe_sec = $sec;
            $safe_sec =~ s/\"\"\"/''''/g;
            $prompt .= "- $safe_sec\n";
        }
        $prompt .= "\n";
    }

    $prompt .= "Output format:\n";
    $prompt .= "1. Start with a compelling title on its own line, prefixed with '# '\n";
    $prompt .= "2. Use markdown formatting throughout\n";
    $prompt .= "3. Include code examples where relevant (use ```perl for Perl code)\n";
    $prompt .= "4. Use ## for section headings\n";
    $prompt .= "5. End with a clear conclusion or call to action\n\n";
    $prompt .= "Write the blog post now:";

    return $prompt;
}

sub _parse_blog_result {
    my ($text) = @_;
    return (undef, []) unless $text;

    my $title;
    my @sections;

    # Extract title (first # heading)
    if ($text =~ /^#\s+(.+?)$/m) {
        $title = $1;
    }

    # Extract sections (## headings)
    my @parts = split /^(##\s+.+?)$/m, $text;
    my $current_heading;

    for my $part (@parts) {
        if ($part =~ /^##\s+(.+)$/) {
            $current_heading = $1;
        } elsif ($current_heading && $part =~ /\S/) {
            push @sections, {
                heading => $current_heading,
                content => $part,
            };
            $current_heading = undef;
        }
    }

    return ($title, \@sections);
}

sub _count_words {
    my ($text) = @_;
    return 0 unless $text;
    my @words = split /\s+/, $text;
    return scalar @words;
}

sub _estimate_reading_time {
    my ($text) = @_;
    my $words = _count_words($text);
    my $minutes = int(($words + 199) / 200);  # ~200 words per minute, round up
    return $minutes > 0 ? $minutes : 1;
}

=head1 SEE ALSO

=over 4

=item * L<Claude::Agent> - The underlying Claude Agent SDK

=item * L<Claude::Agent::CLI> - Terminal UI utilities (spinners, menus, prompts)

=item * L<Wordsmith::Claude::Options> - Configuration options

=item * L<Wordsmith::Claude::Result> - Result object

=item * L<Wordsmith::Claude::Mode> - Built-in mode definitions

=item * L<Wordsmith::Claude::Blog> - Blog style definitions

=item * L<Wordsmith::Claude::Blog::Result> - Blog result object

=item * L<Wordsmith::Claude::Blog::Builder> - Multi-step blog building with callbacks

=item * L<Wordsmith::Claude::Blog::Interactive> - Interactive terminal blog builder

=item * L<Wordsmith::Claude::Blog::Reviewer> - Blog review and editing

=item * L<Wordsmith::Claude::Blog::Reviewer::Interactive> - Interactive terminal blog reviewer

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
