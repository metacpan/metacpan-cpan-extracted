package Wordsmith::Claude::Blog::Result;

use 5.020;
use strict;
use warnings;

use Types::Standard qw(Str ArrayRef HashRef);
use Text::Markdown 'markdown';
use HTML::Scrubber;
use URI;

use Marlin
    'topic!'    => Str,
    'title!'    => Str,
    'text!'     => Str,
    'style?'    => Str,
    'tone?'     => Str,
    'size?'     => Str,
    'sections?' => ArrayRef[HashRef],
    'metadata?' => HashRef,
    'error?'    => Str;

=head1 NAME

Wordsmith::Claude::Blog::Result - Result object for blog generation

=head1 SYNOPSIS

    my $result = Wordsmith::Claude::Blog::Result->new(
        topic    => 'AI in Perl',
        title    => 'Building AI Tools with Perl',
        text     => '# Building AI Tools...',
        style    => 'technical',
        tone     => 'enthusiastic',
        metadata => { word_count => 1234 },
    );

    print $result->title;
    print $result->word_count;
    print $result->reading_time, " minutes\n";

    if ($result->is_success) {
        print $result->as_markdown;
    }

=head1 DESCRIPTION

Result object returned by the blog() function containing the generated
blog post and metadata.

=head2 ATTRIBUTES

=over 4

=item * topic - The original topic requested

=item * title - The generated title for the blog post

=item * text - The full generated blog text (markdown)

=item * style - The style used (technical, tutorial, etc.)

=item * tone - The tone used (professional, friendly, etc.)

=item * length - The length preset used (short, medium, long)

=item * sections - ArrayRef of parsed sections (optional)

=item * metadata - HashRef of metadata (word_count, etc.)

=item * error - Error message if generation failed

=back

=head1 METHODS

=head2 is_success

    if ($result->is_success) { ... }

Returns true if the blog was generated successfully (no error).

=cut

sub is_success {
    my ($self) = @_;
    return !$self->has_error;
}

=head2 is_error

    if ($result->is_error) { ... }

Returns true if an error occurred.

=cut

sub is_error {
    my ($self) = @_;
    return $self->has_error;
}

=head2 word_count

    my $count = $result->word_count;

Returns the word count of the generated text.

=cut

sub word_count {
    my ($self) = @_;

    # Return from metadata if available
    if ($self->has_metadata && exists $self->metadata->{word_count}) {
        return $self->metadata->{word_count};
    }

    # Calculate from text
    my $text = $self->text // '';
    my @words = split /\s+/, $text;
    return scalar @words;
}

=head2 reading_time

    my $minutes = $result->reading_time;

Returns estimated reading time in minutes (assuming 200 words/minute).

=cut

sub reading_time {
    my ($self) = @_;

    # Return from metadata if available
    if ($self->has_metadata && exists $self->metadata->{reading_time}) {
        return $self->metadata->{reading_time};
    }

    # Calculate: ~200 words per minute
    my $words = $self->word_count;
    my $minutes = int(($words + 199) / 200);  # Round up
    return $minutes > 0 ? $minutes : 1;
}

=head2 as_markdown

    print $result->as_markdown;

Returns the blog post as markdown (same as text, but ensures proper formatting).

=cut

sub as_markdown {
    my ($self) = @_;
    return $self->text // '';
}

=head2 as_html

    print $result->as_html;

Returns the blog post converted to basic HTML.

=cut

sub as_html {
    my ($self) = @_;
    my $text = $self->text // '';

    my $html = markdown($text);
    my $scrubber = HTML::Scrubber->new(
        default => [0, {'*' => 0}],  # Deny all by default
        allow => [qw(p h1 h2 h3 h4 h5 h6 ul ol li a code pre blockquote strong em br)],
        # Explicitly deny all attributes for all tags, then allow specific ones for 'a' tags
        rules => [
            '*' => { '*' => 0 },  # Deny all attributes by default for all tags
            # Use URI module for proper URL parsing and validation
            a => { href => sub { my $url = shift; my $u = eval { URI->new($url) }; if ($@) { warn "URI parse error: $@"; return 0; } return 0 unless $u && $u->scheme; return 0 if $u->scheme =~ /^(javascript|data|vbscript)$/i; return (($u->scheme eq 'https' || $u->scheme eq 'http') && $u->host && !$u->userinfo) ? 1 : 0; } },
        ],
    );
    my $scrubbed = $scrubber->scrub($html);
    # Defense-in-depth: reject dangerous URI schemes that might bypass the regex
    # First decode common HTML entities to catch encoded bypasses like &#106;avascript:
    # Apply in a loop to handle nested/double-encoded entities like &amp;#106;
    my $decoded = $scrubbed;
    my $prev_decoded;
    my $max_decode_iterations = 5;  # Prevent infinite loops
    my $decode_iterations = 0;
    do {
        $prev_decoded = $decoded;
        # Decode &amp; first to handle nested encoding
        $decoded =~ s/&amp;/&/gi;
        # Add bounds checking to ensure valid Unicode codepoints (max 0x10FFFF)
        # Also reject surrogate pair codepoints (0xD800-0xDFFF) which are invalid in UTF-8
        $decoded =~ s/&#x([0-9a-fA-F]+);/do { my $cp = hex($1); ($cp <= 0x10FFFF && !($cp >= 0xD800 && $cp <= 0xDFFF)) ? chr($cp) : '' }/ge;
        $decoded =~ s/&#(\d+);/do { my $cp = $1; ($cp <= 0x10FFFF && !($cp >= 0xD800 && $cp <= 0xDFFF)) ? chr($cp) : '' }/ge;
        $decode_iterations++;
    } while ($decoded ne $prev_decoded && $decode_iterations < $max_decode_iterations);
    # Check decoded version for dangerous schemes (case-insensitive)
    # NOTE: Consider using a dedicated HTML security library like HTML::Restrict for more robust protection.
    # Consider using HTML::Restrict instead of regex post-processing:
    # use HTML::Restrict;
    # my $hr = HTML::Restrict->new(rules => { a => ['href'] });
    # Validate href values are HTTP(S) URLs before allowing
    # Normalize by removing all whitespace/control chars before checking to prevent bypass via tabs, null bytes, etc.
    my $normalized = $decoded;
    $normalized =~ s/[\x00-\x20]+//g;
    # Fix TOCTOU issue: if dangerous schemes detected, remove all href attributes
    # from the decoded/normalized version to ensure consistency
    if ($normalized =~ /\bhref=["']?(javascript|data|vbscript):/i) {
        # Remove all href attributes since the content is potentially malicious
        $decoded =~ s/\bhref\s*=\s*["'][^"']*["']/href=""/gi;
        $decoded =~ s/\bhref\s*=\s*[^\s>"']+//gi;
    }
    # Also apply the filter on the decoded output to catch any remaining dangerous patterns
    $decoded =~ s/\bhref\s*=\s*["']?\s*(javascript|data|vbscript)\s*:[^"'>\s]*["']?/href=""/gi;
    return $decoded;
}

=head2 section_count

    my $count = $result->section_count;

Returns the number of sections in the blog post.

=cut

sub section_count {
    my ($self) = @_;
    return 0 unless $self->has_sections;
    return scalar @{$self->sections};
}

=head2 get_section

    my $section = $result->get_section(0);
    print $section->{heading}, "\n", $section->{content};

Returns a specific section by index.

=cut

sub get_section {
    my ($self, $index) = @_;
    return unless $self->has_sections;
    return unless defined $index && $index >= 0 && $index < @{$self->sections};
    return $self->sections->[$index];
}

=head2 to_hash

    my $hash = $result->to_hash;

Returns a hashref representation of the result.

=cut

sub to_hash {
    my ($self) = @_;

    return {
        topic        => $self->topic,
        title        => $self->title,
        text         => $self->text,
        word_count   => $self->word_count,
        reading_time => $self->reading_time,
        ($self->has_style    ? (style    => $self->style)    : ()),
        ($self->has_tone     ? (tone     => $self->tone)     : ()),
        ($self->has_size     ? (size     => $self->size)     : ()),
        ($self->has_sections ? (sections => $self->sections) : ()),
        ($self->has_error    ? (error    => $self->error)    : ()),
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
