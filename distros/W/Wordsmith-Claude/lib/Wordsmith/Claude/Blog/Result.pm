package Wordsmith::Claude::Blog::Result;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Text::Markdown 'markdown';
use HTML::Scrubber;
use URI;

BEGIN {
    Object::Proto::define('Wordsmith::Claude::Blog::Result',
        'topic:Str:required',
        'title:Str:required',
        'text:Str:required',
        'style:Str:predicate',
        'tone:Str:predicate',
        'size:Str:predicate',
        'sections:ArrayRef:predicate',
        'metadata:HashRef:predicate',
        'error:Str:predicate',
    );
}

sub is_success {
    my ($self) = @_;
    return !$self->has_error;
}

sub is_error {
    my ($self) = @_;
    return $self->has_error;
}

sub word_count {
    my ($self) = @_;

    if ($self->has_metadata && exists $self->metadata->{word_count}) {
        return $self->metadata->{word_count};
    }

    my $text = $self->text // '';
    my @words = split /\s+/, $text;
    return scalar @words;
}

sub reading_time {
    my ($self) = @_;

    if ($self->has_metadata && exists $self->metadata->{reading_time}) {
        return $self->metadata->{reading_time};
    }

    my $words = $self->word_count;
    my $minutes = int(($words + 199) / 200);
    return $minutes > 0 ? $minutes : 1;
}

sub as_markdown {
    my ($self) = @_;
    return $self->text // '';
}

sub as_html {
    my ($self) = @_;
    my $text = $self->text // '';

    my $html = markdown($text);
    my $scrubber = HTML::Scrubber->new(
        default => [0, {'*' => 0}],
        allow => [qw(p h1 h2 h3 h4 h5 h6 ul ol li a code pre blockquote strong em br)],
        rules => [
            '*' => { '*' => 0 },
            a => { href => sub { my $url = shift; my $u = eval { URI->new($url) }; if ($@) { warn "URI parse error: $@"; return 0; } return 0 unless $u && $u->scheme; return 0 if $u->scheme =~ /^(javascript|data|vbscript)$/i; return (($u->scheme eq 'https' || $u->scheme eq 'http') && $u->host && !$u->userinfo) ? 1 : 0; } },
        ],
    );
    my $scrubbed = $scrubber->scrub($html);
    my $decoded = $scrubbed;
    my $prev_decoded;
    my $max_decode_iterations = 5;
    my $decode_iterations = 0;
    do {
        $prev_decoded = $decoded;
        $decoded =~ s/&amp;/&/gi;
        $decoded =~ s/&#x([0-9a-fA-F]+);/do { my $cp = hex($1); ($cp <= 0x10FFFF && !($cp >= 0xD800 && $cp <= 0xDFFF)) ? chr($cp) : '' }/ge;
        $decoded =~ s/&#(\d+);/do { my $cp = $1; ($cp <= 0x10FFFF && !($cp >= 0xD800 && $cp <= 0xDFFF)) ? chr($cp) : '' }/ge;
        $decode_iterations++;
    } while ($decoded ne $prev_decoded && $decode_iterations < $max_decode_iterations);
    my $normalized = $decoded;
    $normalized =~ s/[\x00-\x20]+//g;
    if ($normalized =~ /\bhref=["']?(javascript|data|vbscript):/i) {
        $decoded =~ s/\bhref\s*=\s*["'][^"']*["']/href=""/gi;
        $decoded =~ s/\bhref\s*=\s*[^\s>"']+//gi;
    }
    $decoded =~ s/\bhref\s*=\s*["']?\s*(javascript|data|vbscript)\s*:[^"'>\s]*["']?/href=""/gi;
    return $decoded;
}

sub section_count {
    my ($self) = @_;
    return 0 unless $self->has_sections;
    return scalar @{$self->sections};
}

sub get_section {
    my ($self, $index) = @_;
    return unless $self->has_sections;
    return unless defined $index && $index >= 0 && $index < @{$self->sections};
    return $self->sections->[$index];
}

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


1;

__END__

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

=item * size - The size preset used (short, medium, long)

=item * sections - ArrayRef of parsed sections (optional)

=item * metadata - HashRef of metadata (word_count, etc.)

=item * error - Error message if generation failed

=back

=head1 METHODS

=head2 is_success

    if ($result->is_success) { ... }

Returns true if the blog was generated successfully (no error).

=cut

=head2 is_error

    if ($result->is_error) { ... }

Returns true if an error occurred.

=cut

=head2 word_count

    my $count = $result->word_count;

Returns the word count of the generated text.

=cut

=head2 reading_time

    my $minutes = $result->reading_time;

Returns estimated reading time in minutes (assuming 200 words/minute).

=cut

=head2 as_markdown

    print $result->as_markdown;

Returns the blog post as markdown (same as text, but ensures proper formatting).

=cut

=head2 as_html

    print $result->as_html;

Returns the blog post converted to basic HTML.

=cut

=head2 section_count

    my $count = $result->section_count;

Returns the number of sections in the blog post.

=cut

=head2 get_section

    my $section = $result->get_section(0);
    print $section->{heading}, "\n", $section->{content};

Returns a specific section by index.

=cut

=head2 to_hash

    my $hash = $result->to_hash;

Returns a hashref representation of the result.

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
