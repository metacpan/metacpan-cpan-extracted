package Wordsmith::Claude::Blog;

use 5.020;
use strict;
use warnings;

=head1 NAME

Wordsmith::Claude::Blog - Blog style definitions and presets

=head1 SYNOPSIS

    use Wordsmith::Claude::Blog;

    # Get style instruction
    my $instruction = Wordsmith::Claude::Blog->get_style('technical');

    # Get tone instruction
    my $tone = Wordsmith::Claude::Blog->get_tone('enthusiastic');

    # List all styles
    my @styles = Wordsmith::Claude::Blog->all_styles;

    # Get style info
    my $info = Wordsmith::Claude::Blog->style_info('tutorial');

=head1 DESCRIPTION

Defines blog styles, tones, and length presets for the blog() function.

=head1 STYLES

=cut

our %STYLES;
BEGIN {
    %STYLES = (
        technical => {
            description => 'Technical deep-dive with code examples',
            instruction => 'Write a technical blog post aimed at developers. Include code examples where appropriate, provide clear explanations of concepts, and share practical insights. Use proper technical terminology but explain complex ideas. Structure the content logically with clear headings.',
        },
        tutorial => {
            description => 'Step-by-step guide with hands-on examples',
            instruction => 'Write a tutorial-style blog post that guides readers through a process step by step. Include prerequisites at the start, number each step clearly, provide code examples that readers can follow along with, and explain what each step accomplishes. End with a working result.',
        },
        announcement => {
            description => 'Product or feature announcement',
            instruction => 'Write an engaging announcement blog post that highlights key features and benefits. Lead with the most exciting news, explain what problem this solves, include examples of how to use new features, and end with a clear call to action. Be enthusiastic but authentic.',
        },
        casual => {
            description => 'Conversational, personal tone',
            instruction => 'Write a casual, conversational blog post that feels like chatting with a knowledgeable friend. Share personal insights and opinions, use informal language and contractions, tell stories to illustrate points, and keep paragraphs short and punchy.',
        },
        listicle => {
            description => 'Numbered list format',
            instruction => 'Write a listicle-style blog post with numbered items. Each item should have a clear heading and a paragraph of explanation. Make items scannable, lead with the most compelling points, and ensure each item provides standalone value.',
        },
        opinion => {
            description => 'Thought leadership piece',
            instruction => 'Write a thought-provoking opinion piece that takes a clear stance on the topic. Support your position with evidence and examples, acknowledge counterarguments, and invite discussion. Be bold but fair.',
        },
        comparison => {
            description => 'Side-by-side comparison',
            instruction => 'Write a comparison blog post that objectively analyzes multiple options. Create clear criteria for comparison, provide specific examples for each option, include a summary table or key takeaways, and give a recommendation based on different use cases.',
        },
        howto => {
            description => 'Practical how-to guide',
            instruction => 'Write a practical how-to guide focused on solving a specific problem. Start with what readers will achieve, list requirements upfront, provide clear actionable steps, include troubleshooting tips, and verify the solution works.',
        },
    );
}

our %TONES;
BEGIN {
    %TONES = (
        professional => {
            description => 'Polished and authoritative',
            instruction => 'Maintain a professional, authoritative voice. Use precise language, avoid slang, and present information with confidence. Sound knowledgeable and trustworthy.',
        },
        friendly => {
            description => 'Warm and approachable',
            instruction => 'Use a warm, friendly tone that makes readers feel welcome. Be approachable and encouraging, use inclusive language like "we" and "let\'s", and celebrate small wins.',
        },
        enthusiastic => {
            description => 'Excited and energetic',
            instruction => 'Be genuinely excited and energetic about the topic. Share your enthusiasm naturally, highlight what makes things exciting, and inspire readers to try things themselves.',
        },
        thoughtful => {
            description => 'Reflective and considered',
            instruction => 'Take a thoughtful, considered approach. Weigh different perspectives, acknowledge complexity, and guide readers through your reasoning process.',
        },
        humorous => {
            description => 'Light-hearted with wit',
            instruction => 'Add appropriate humor and wit to make the content enjoyable. Use clever analogies, self-deprecating humor when appropriate, and keep things light while still being informative.',
        },
        direct => {
            description => 'Straight to the point',
            instruction => 'Be direct and no-nonsense. Get to the point quickly, avoid filler, use short sentences, and respect the reader\'s time.',
        },
    );
}

our %LENGTHS;
BEGIN {
    %LENGTHS = (
        short => {
            description => 'Quick read (500-800 words)',
            instruction => 'Keep the post concise at 500-800 words. Focus on one key point, use short paragraphs, and trim any unnecessary content.',
        },
        medium => {
            description => 'Standard post (1000-1500 words)',
            instruction => 'Write a standard-length post of 1000-1500 words. Cover the topic thoroughly with enough depth to be useful, but stay focused.',
        },
        long => {
            description => 'In-depth article (2000-3000 words)',
            instruction => 'Write a comprehensive, in-depth article of 2000-3000 words. Cover all aspects of the topic, include multiple examples, and provide thorough explanations.',
        },
    );
}

=head1 CLASS METHODS

=head2 get_style

    my $instruction = Wordsmith::Claude::Blog->get_style('technical');

Returns the instruction text for a style, or undef if style doesn't exist.

=cut

sub get_style {
    my ($class, $style) = @_;
    return unless $style && exists $STYLES{$style};
    return $STYLES{$style}{instruction};
}

=head2 get_tone

    my $instruction = Wordsmith::Claude::Blog->get_tone('friendly');

Returns the instruction text for a tone, or undef if tone doesn't exist.

=cut

sub get_tone {
    my ($class, $tone) = @_;
    return unless $tone && exists $TONES{$tone};
    return $TONES{$tone}{instruction};
}

=head2 get_length

    my $instruction = Wordsmith::Claude::Blog->get_length('medium');

Returns the instruction text for a length, or undef if length doesn't exist.

=cut

sub get_length {
    my ($class, $length) = @_;
    return unless $length && exists $LENGTHS{$length};
    return $LENGTHS{$length}{instruction};
}

=head2 style_exists

    if (Wordsmith::Claude::Blog->style_exists('tutorial')) { ... }

Returns true if the style exists.

=cut

sub style_exists {
    my ($class, $style) = @_;
    return $style && exists $STYLES{$style};
}

=head2 tone_exists

    if (Wordsmith::Claude::Blog->tone_exists('friendly')) { ... }

Returns true if the tone exists.

=cut

sub tone_exists {
    my ($class, $tone) = @_;
    return $tone && exists $TONES{$tone};
}

=head2 length_exists

    if (Wordsmith::Claude::Blog->length_exists('short')) { ... }

Returns true if the length exists.

=cut

sub length_exists {
    my ($class, $length) = @_;
    return $length && exists $LENGTHS{$length};
}

=head2 all_styles

    my @styles = Wordsmith::Claude::Blog->all_styles;

Returns list of all style names.

=cut

sub all_styles {
    my @sorted = sort keys %STYLES;
    return @sorted;
}

=head2 all_tones

    my @tones = Wordsmith::Claude::Blog->all_tones;

Returns list of all tone names.

=cut

sub all_tones {
    my @sorted = sort keys %TONES;
    return @sorted;
}

=head2 all_lengths

    my @lengths = Wordsmith::Claude::Blog->all_lengths;

Returns list of all length names.

=cut

sub all_lengths {
    my @sorted = sort keys %LENGTHS;
    return @sorted;
}

=head2 style_info

    my $info = Wordsmith::Claude::Blog->style_info('technical');
    # { description => '...', instruction => '...' }

Returns full info hashref for a style.

=cut

sub style_info {
    my ($class, $style) = @_;
    return unless $style && exists $STYLES{$style};
    return { %{$STYLES{$style}} };
}

=head2 tone_info

    my $info = Wordsmith::Claude::Blog->tone_info('friendly');

Returns full info hashref for a tone.

=cut

sub tone_info {
    my ($class, $tone) = @_;
    return unless $tone && exists $TONES{$tone};
    return { %{$TONES{$tone}} };
}

=head2 length_info

    my $info = Wordsmith::Claude::Blog->length_info('medium');

Returns full info hashref for a length.

=cut

sub length_info {
    my ($class, $length) = @_;
    return unless $length && exists $LENGTHS{$length};
    return { %{$LENGTHS{$length}} };
}

=head2 style_description

    my $desc = Wordsmith::Claude::Blog->style_description('tutorial');

Returns the short description for a style.

=cut

sub style_description {
    my ($class, $style) = @_;
    return unless $style && exists $STYLES{$style};
    return $STYLES{$style}{description};
}

=head2 tone_description

    my $desc = Wordsmith::Claude::Blog->tone_description('enthusiastic');

Returns the short description for a tone.

=cut

sub tone_description {
    my ($class, $tone) = @_;
    return unless $tone && exists $TONES{$tone};
    return $TONES{$tone}{description};
}

=head2 length_description

    my $desc = Wordsmith::Claude::Blog->length_description('long');

Returns the short description for a length.

=cut

sub length_description {
    my ($class, $length) = @_;
    return unless $length && exists $LENGTHS{$length};
    return $LENGTHS{$length}{description};
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
