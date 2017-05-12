package Text::MetaMarkup;
use 5.006;
use strict;
use Carp qw(croak);

our $VERSION = '0.01';

my $link       = qr/ \[ ([^\]]*) \] /x;
my $inlinetag = do {
    our $acc =
    qr/(?> \{          (?: (?> \\. | [^\\{}]+ | (??{ $acc }) ) )*   \} )/xs;
    qr/    \{ (\w+): ( (?: (?> \\. | [^\\{}]+ | (??{ $acc }) ) )* ) \}  /xs;
};
my $text       = qr/(?: (?> \\. | [^{\[\\]+ ) )*/sx;
my $stuff      = qr/(?>$text) | (?>$link) | (?>$inlinetag)/x;
my $paratag    = qr/(\w+):\s*/;
my $n          = qr/\n\s*\n/;

BEGIN {
    # Undocumented feature: this module can export its regexes.
    # Suggested use line: use Text::MetaMarkup _prefix => 'mm_', qw(:re);
    if (eval { require Exporter::Tidy }) {
        Exporter::Tidy->import(
            re => [ qw/link inlinetag text stuff paratag n/ ],
            _map => {
                link => \$link, inlinetag => \$inlinetag, text => \$text, 
                stuff => \$stuff, paratag => \$paratag, n => \$n
            }
        );
    }
}

sub new { my $class = shift; bless { @_ }, $class }

sub parse {
    my ($self, $type, $arg) = @_;
    local $/;
    if ($type eq 'file') {
        open my $fh, '<', $arg or croak $!;
        ($type, $arg) = ('fh', $fh);
    }
    if ($type eq 'fh') {
        $arg = readline $arg;
    }
    return $self->parse_document($arg);
}

sub parse_document {
    my ($self, $document) = @_;
    return if not defined $document;
    my $result;

    if ($self->can('start_document')) {
        my $r = $self->start_document();
        $result .= $r if defined $r;
    }

    my @paragraphs = split /$n/, $document;
    for (@paragraphs) {
        my $r = $self->parse_paragraph($_);
        $result .= $r if defined $r;
    }

    if ($self->can('end_document')) {
        my $r = $self->end_document();
        $result .= $r if defined $r;
    }
    
    return $result;
}

sub parse_paragraph {
    my ($self, $text) = @_;
    /^#/ and return;
    my $tag = $text =~ s/^$paratag// ? $1 : '';

    my $result;
    
    if ($self->can('start_paragraph')) {
        my $r = $self->start_paragraph($tag);
        $result .= $r if defined $r;
    }
    
    my $method = "paragraph_$tag";
    $self->can($method) or $method = 'paragraph';
    my $r = $self->$method($tag, $text);
    $result .= $r if defined $r;

    if ($self->can('end_paragraph')) {
        my $r = $self->end_paragraph($tag);
        $result .= $r if defined $r;
    }
    return $result;
};

sub parse_paragraph_text {
    my ($self, $paragraph) = @_;
    return if not defined $paragraph;

    # Store and then use, to avoid some strange bug where Perl seems to forget
    # the value of pos($paragraph)
    
    my @chunks;
    while ($paragraph =~ /\G($stuff)/g) {
        push @chunks, [ $1, $2, $3, $4 ];
    }

    my $result;
    while (my $chunk = shift @chunks) {
        my $char = substr $chunk->[0], 0, 1;
        if ($char eq '[') {
            my $r = $self->parse_link($chunk->[1]);
            $result .= $r if defined $r;
        } elsif ($char eq '{') {
            my ($tag, $text) = ($chunk->[2], $chunk->[3]);
            my $method = "inline_$tag";
            $self->can($method) or $method = 'inline';
            my $r = $self->$method($tag, $text);
            $result .= $r if defined $r;
        } else {
            my $r = $self->text($chunk->[0]);
            $result .= $r if defined $r;
        }
    }
    return $result;
}

sub parse_link {
    my ($self, $link) = @_;
    my ($href, $text) = split /\|/, $link, 2;
    my ($scheme, $rest) = split /:/, $href, 2;
    if (not defined $rest) {
        $rest = $scheme;
        $scheme = '';
    }

    my $method = "link_$scheme";
    $self->can($method) or $method = 'link';
    
    return $self->$method(
        { href => $href, scheme => $scheme, rest => $rest},
        $text
    );
}

sub link_ {
    my ($self, $href, $text) = @_;
    return unless $href->{href} or $text;
    $self->link($href, $text);
}


sub text {
    my ($self, $text) = @_;
    return if not defined $text;
    $text =~ s/\\(.)/$1/gs;
    return $self->escape($text);
}

1;

__END__

=head1 NAME

Text::MetaMarkup - Simple structured POD/Wiki-ish markup

=head1 SYNOPSIS

    use Text::MetaMarkup::HTML;
    print Text::MetaMarkup::HTML->new->parse(file => $filename);

=head1 DESCRIPTION

MetaMarkup was inspired by POD, Wiki and PerlMonks. I created it because
I wanted a simple format to write documents for my site quickly.

A document consists of paragraphs. Paragraphs are separated by blank lines,
which may contain whitespace. A paragraph can be prefixed with C<tag:>, which
should correspond to an HTML block level tag like C<h1>, C<p> or C<pre>.

Paragraphs cannot be nested. Paragraphs that start with C<#> are ignored.

In a paragraph, inline tags are used with curly braces. That is: C<{i:foo}> is
C<< <i>foo</i> >> in HTML.

Inline tags can be nested.

Characters can be escaped using a backslash character. Never are escaped
characters special: C<\n> is C<n> in the result, not a newline.

Links are written as C<[url|text]>. Inline tags can be used in the text part.

=head1 SUBCLASSING

Do not use Text::MetaMarkup directly. It is intended to be subclassed. Most
people will just use Text::MetaMarkup::HTML, but you can create your own.

Packages in Text::MetaMarkup::AddOn:: are special. They don't subclass
Text::MetaMarkup but used by subclasses (using C<@ISA> (C<use base>)) to
provide additional tags.

Text::MetaMarkup::HTML::JuerdNL is used by my own homepage and is included
in the distribution as an example.

=head1 METHODS

=head2 Provided by Text::MetaMarkup

=over 4

=item C<new>

Constructor method. Takes a list of key/value pairs which is used to fill
the hash that gets blessed. These values are currently not used, but could be
used by the subclasses.

=item C<parse>

Takes two arguments. Either C<file> and a filename, C<fh> and a filehandle 
or C<string> and a string. Returns the converted document.

=item C<parse_document>

Takes one argument: a string of paragraphs. Returns the converted document.

=item C<parse_paragraph>

Takes one argument: a string of text, possibly with inline tags. Returns
the converted paragraph.

=item C<parse_link>

Takes one argument: The link (without square brackets). Returns the converted
link.

=item C<text>

Takes one argument: Plain text. Unescapes the text and returns it.

=back

=head2 To be provided by a subclass

=over 4

=item C<escape>

Takes one argument: text. Should return the escaped version of that text.

=item C<paragraph>

Takes two arguments: tag and text. Should return the converted form.

=item C<inline>

Takes two arguments: tag and text. Should return the converted form.

=item C<link>

Takes two arguments: a hashref and text. The hashref contains C<href>,
C<scheme> and C<rest>. Should return the converted form.

If the link provided is C<[http://juerd.nl/|Juerd's homepage]>, then
C<link> gets in @_: C<< { href => 'http://juerd.nl/', scheme => 'http',
rest => '//juerd.nl/' }, 'Juerd\'s homepage' >>.

=item Special methods

If paragraph tag C<foo> is encountered, C<paragraph_foo> is tried before
C<paragraph>. If inline tag C<foo> is encountered, C<inline_foo> is tried
before C<inline>. If link scheme C<foo> is encountered, C<link_foo> is tried
before C<link>. If the tag or scheme specific method exists, the general one
is not called.

Furthermore, a subclass can implement any of C<start_document>,
C<end_document>, C<start_paragraph> and C<end_paragraph>. Parapgraph start/end
handlers get the tag as their only argument. The value returned by any of these
methods is used in the result document.

=back

A subclass should try to format paragraphs that start with C<*> as bulleted
lists.

=head1 LICENSE

There is no license. This software was released into the public domain. Do with
it what you want, but on your own risk. The author disclaims any
responsibility. 

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=head1 SEE ALSO

L<Text::MetaMarkup::HTML>

=cut
