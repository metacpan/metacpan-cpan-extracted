package Text::Amuse::Compile::MuseHeader;

use Moo;
use Types::Standard qw/HashRef Bool Str ArrayRef/;
use Text::Amuse::Functions qw/muse_format_line/;

=head1 NAME

Text::Amuse::Compile::MuseHeader - Module to parse muse metadata

=head1 DESCRIPTION

This class is still a work in progress.

=head1 METHODS

=head2 new(\%header)

Constructor. It accepts only one mandatory argument with the output of
muse_fast_scan_header (an hashref).

=head2 wants_slides

Return true if slides are needed. False if C<#slides> is not present
or "no" or "false".

=head2 header

The cleaned and lowercased header. Directives with underscores are
ignored.

=head2 title

Verbatim header field

=head2 subtitle

Verbatim header field

=head2 listtitle

Verbatim header field

=head2 listing_title

Return listtitle if set, title otherwise.

=head2 author

Verbatim header field

=head2 language

Defaults to en if not present.

=head2 topics

An arrayref with topics from C<sorttopics>, C<topics> and C<cat>
fields. The C<cat> field is meant to be reserved from fixed category
list, so it splits at space too, while the others split at semicolon
(if present) or at comma.

=head2 authors

An arrayref with the authors from C<sortauthors> and C<authors>
fields.

Fields split at semicolon if present, otherwise at comma.

=head2 topics_as_html_list

Same as C<topics>, but returns a plain list of HTML formatted topics.

=head2 authors_as_html_list

Same as C<authors>, but returns a plain list of HTML formatted authors.

=head2 tex_metadata

Return an hashref with the following keys: C<title> C<author>
C<subject> C<keywords> with the values LaTeX escaped, mapping to the
relevant headers values for setting PDF metadata.

=head1 INTERNALS

=head2 BUILDARGS

Moo-ifies the constructor.

=cut

sub BUILDARGS {
    my ($class, $hash) = @_;
    if ($hash) {
        die "Argument must be an hashref" unless ref($hash) eq 'HASH';
    }
    else {
        die "Missing argument";
    }
    my $directives = { %$hash };
    my %lowered;
  DIRECTIVE:
    foreach my $k (keys %$directives) {
        if ($k =~ m/_/) {
            warn "Ignoring $k directive with underscore\n";
            next DIRECTIVE;
        }
        my $lck = lc($k);
        if (exists $lowered{$lck}) {
            warn "Overwriting $lck, directives are case insensitive!\n";
        }
        $lowered{$lck} = $directives->{$k};
    }
    my %args = (header => { %lowered });
    foreach my $f (qw/title listtitle subtitle author/) {
        if (exists $lowered{$f} and
            defined $lowered{$f} and
            $lowered{$f} =~ m/\w/) {
            $args{$f} = $lowered{$f};
        }
        else {
            $args{$f} = '';
        }
    }
    return \%args;
}

has title => (is => 'ro', isa => Str, required => 1);
has subtitle => (is => 'ro', isa => Str, required => 1);
has listtitle => (is => 'ro', isa => Str, required => 1);
has author => (is => 'ro', isa => Str, required => 1);

has header => (is => 'ro', isa => HashRef[Str]);

has language => (is => 'lazy', isa => Str);

sub _build_language {
    my $self = shift;
    my $lang = 'en';
    # language treatment
    if (my $lang_orig = $self->header->{lang}) {
        if ($lang_orig =~ m/([a-z]{2,3})/) {
            $lang = $1;
        }
        else {
            warn qq[Garbage $lang_orig found in #lang, using "en" instead\n];
        }
    }
    else {
        warn "No language found, assuming english\n";
    }
    return $lang;
}

has wants_slides => (is => 'lazy', isa => Bool);

sub _build_wants_slides {
    my $self = shift;
    my $bool = 0;
    if (my $slides = $self->header->{slides}) {
        if (!$slides or $slides =~ /^\s*(no|false)\s*$/si) {
            $bool = 0;
        }
        else {
            $bool = 1;
        }
    }
    return $bool;
}

has is_deleted => (is => 'lazy', isa => Bool);

sub _build_is_deleted {
    return !!shift->header->{deleted};
}

has cover => (is => 'lazy', isa => Str);

sub _build_cover {
    my $self = shift;
    if (my $cover = $self->header->{cover}) {
        if ($cover =~ m/\A
                        (
                            [a-zA-Z0-9]
                            [a-zA-Z0-9-]*
                            [a-zA-Z0-9]
                            \.(jpe?g|png)
                        )\z
                       /x) {
            if (-f $cover) {
                return $cover;
            }
        }
    }
    return '';
}

has coverwidth => (is => 'lazy', isa => Str);


sub _build_coverwidth {
    # compare with TemplateOptions
    my $self = shift;
    if ($self->cover) {
        if (my $width = $self->header->{coverwidth}) {
            if ($width =~ m/\A[01](\.[0-9][0-9]?)?\z/) {
                return $width;
            }
            else {
                warn "Invalid measure passed for coverwidth, should be 0.01 => 1.00\n";
            }
        }
        return 1;
    }
    return 0;
}

has nocoverpage => (is => 'lazy', isa => Bool);

sub _build_nocoverpage {
    my $self = shift;
    return !!$self->header->{nocoverpage};
}

has notoc => (is => 'lazy', isa => Bool);

sub _build_notoc {
    my $self = shift;
    return !!$self->header->{notoc};
}

has nofinalpage => (is => 'lazy', isa => Bool);

sub _build_nofinalpage {
    my $self = shift;
    return !!$self->header->{nofinalpage};
}



has topics => (is => 'lazy', isa => ArrayRef);

sub _build_topics {
    my $self = shift;
    my @topics;
    foreach my $field (qw/cat sorttopics topics/) {
        push @topics, $self->_parse_topic_or_author($field);
    }
    return \@topics;
}

has authors => (is => 'lazy', isa => ArrayRef);

sub _build_authors {
    my $self = shift;
    my @authors;
    foreach my $field (qw/authors sortauthors/) {
        push @authors, $self->_parse_topic_or_author($field);
    }
    return \@authors;
}

sub authors_as_html_list {
    my $self = shift;
    return $self->_html_strings($self->authors);
}

sub topics_as_html_list {
    my $self = shift;
    return $self->_html_strings($self->topics);
}

sub _html_strings {
    my ($self, $list) = @_;
    my @out;
    foreach my $el (@$list) {
        push @out, muse_format_line(html => $el);
    }
    return @out;
}

sub listing_title {
    my $self = shift;
    if (length($self->listtitle)) {
        return $self->listtitle;
    }
    else {
        return $self->title;
    }
}

sub tex_metadata {
    my $self = shift;
    my %out = (
               title => $self->listing_title,
               author => (scalar(@{$self->authors}) ? join('; ', @{$self->authors}) : $self->author),
               subject => $self->subtitle,
               keywords => (scalar(@{$self->topics}) ? join('; ', @{$self->topics}) : ''),
              );
    foreach my $k (keys %out) {
        $out{$k} = muse_format_line(ltx => $out{$k});
    }
    return \%out;
}

sub _parse_topic_or_author {
    my ($self, $field) = @_;
    my $header = $self->header;
    my %fields = (
                  cat => 1,
                  sorttopics => 1,
                  sortauthors => 1,
                  topics => 1,
                  authors => 1,
                 );
    die "Called _parse_topic_or_author for unknown field $field"
      unless $fields{$field};
    my @out;
    if (exists $header->{$field}) {
        my $string = $header->{$field};
        if (defined $string and length $string) {
            my $separator = qr{\s*\,\s*};
            if ($field eq 'cat') {
                $separator = qr{[\s;,]+};
            }
            elsif ($string =~ m/\;/) {
                $separator = qr{\s*\;\s*};
            }
            @out = grep { /\w/ } split(/$separator/, $string);
        }
    }
    return @out;
}

1;
