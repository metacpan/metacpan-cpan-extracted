package Text::Amuse;

use strict;
use warnings;
# use Data::Dumper;
use Text::Amuse::Document;
use Text::Amuse::Output;
use Text::Amuse::Beamer;

=head1 NAME

Text::Amuse - Generate HTML and LaTeX documents from Emacs Muse markup.

=head1 VERSION

Version 1.63

=cut

our $VERSION = '1.63';


=head1 SYNOPSIS

Typical usage which should illustrate all the public methods

    use Text::Amuse;
    my $doc = Text::Amuse->new(file => "test.muse");

    # get the title, author, etc. as an hashref
    my $html_directives = $doc->header_as_html;

    # get the table of contents
    my $html_toc = $doc->toc_as_html;

    # get the body
    my $html_body = $doc->as_html;

    # same for LaTeX
    my $latex_directives = $doc->header_as_latex;
    my $latex_body = $doc->as_latex;

    # do we need a \tableofcontents ?
    my $wants_toc = $doc->wants_toc; # (boolean)

    # files attached
    my @images = $doc->attachments;

    # at this point you can inject the values in a template, which is
    # left to the user. If you want an executable, please install
    # Text::Amuse::Compile.

=head1 CONSTRUCTORS

=over 4

=item new (file => $file, partial => \@parts, include_paths => \@paths)

Create a new Text::Amuse object. You should pass the named parameter
C<file>, pointing to a muse file to process. Please note that you
can't pass a string. Build a wrapper going through a temporary file if
you need to pass strings.

Optionally, accept a C<partial> option pointing to an arrayref of
integers, meaning that only those chunks will be needed.

The beamer output doesn't take C<partial> in account.

Optionally, accept a C<include_paths> argument, with an arrayref of
directories to search for included files.

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = {
                file => $opts{file},
                debug => $opts{debug},
                partials => undef,
               };
    if (my $chunks = $opts{partial}) {
        die "partial needs an arrayref" unless ref($chunks) eq 'ARRAY';
        my %partials;
        foreach my $chunk (@$chunks) {
            if (defined $chunk) {
                if ($chunk =~ m/\A
                                (pre | post | [0-9] | [1-9][0-9]+ )
                                \z/x) {
                    $partials{$1} = 1;
                }
                else {
                    die q{Partials should be integers or strings "pre", "post"};
                }
            }
        }
        if (%partials) {
            $self->{partials} = \%partials;
        }
    }

    $self->{_document_obj} =
      Text::Amuse::Document->new(file => $self->{file},
                                 include_paths => $opts{include_paths},
                                 debug => $self->{debug});
    bless $self, $class;
}

=back

=head1 METHODS

=over 4

=item document

Accessor to the L<Text::Amuse::Document> object. [Internal]

=item file

Accessor to the file passed in the constructor (read-only)

=item partials

Return an hashref where the keys are the chunk indexes and the values
are true, undef otherwise.

=item include_paths

Return a list of directory to look into for included files

=item included_files

Return the list of files included

=cut

sub document {
    return shift->{_document_obj};
}

sub include_paths {
    return shift->document->include_paths;
}

sub included_files {
    my $self = shift;
    $self->document->raw_body; # call it to get it populated
    return $self->document->included_files;
}


sub partials {
    my $self = shift;
    if (my $partials = $self->{partials}) {
        return { %$partials };
    }
    else {
        return undef;
    }
}

sub file {
    return shift->{file};
}

=back

=head2 HTML output

=over 4

=item as_html

Output the HTML document (and cache it in the object)

=cut

sub _html_obj {
    my $self = shift;
    unless (defined $self->{_html_doc}) {
        $self->{_html_doc} =
          Text::Amuse::Output->new(
                                   document => $self->document,
                                   format => 'html',
                                  );
    }
    return $self->{_html_doc};
}

sub _get_body {
    my ($self, $doc, $split) = @_;
    if (my $partials = $self->partials) {
        my @chunks = @{ $doc->process(split => 1) };
        my @out;
        for (my $i = 0; $i < @chunks; $i++) {
            push @out, $chunks[$i] if $partials->{$i};
        }
        return \@out;
    }
    else {
        return $doc->process(split => $split);
    }
}

sub _get_full_body {
    my ($self, $doc) = @_;
    return $self->_get_body($doc => 0);
}

sub _get_splat_body {
    my ($self, $doc) = @_;
    return $self->_get_body($doc => 1);
}


sub as_html {
    my $self = shift;
    unless (defined $self->{_html_output_strings}) {
        $self->{_html_output_strings} = $self->_get_full_body($self->_html_obj);
    }
    return unless defined wantarray;
    return join("", @{ $self->{_html_output_strings} });
}

=item header_as_html

The directives of the document in HTML (title, authors, etc.),
returned as an hashref.

B<Please note that the keys are not escaped nor manipulated>.

=cut

sub header_as_html {
    my $self = shift;
    $self->as_html; # trigger the html generation. This operation is
                    # not expensive if we already call it, and won't
                    # be the next time.
    unless (defined $self->{_cached_html_header}) {
        $self->{_cached_html_header} = $self->_html_obj->header;
    }
    return { %{ $self->{_cached_html_header} } };
}

=item toc_as_html

Return the HTML formatted ToC, as a string.

=cut

sub toc_as_html {
    my $self = shift;
    my @toc = $self->raw_html_toc;
    return "" unless @toc;
    # do the dirty job
    my @out;
    foreach my $item (@toc) {
        next unless $item->{index}; # skip the 0 one, is dummy
        next unless length $item->{string}; # skip empty one at output level
        my $anchor = $item->{named} ? $item->{named}  : 'toc' . $item->{index};
        my $line = qq{<p class="tableofcontentline toclevel} .
          $item->{level} . qq{"><span class="tocprefix">} .
          '&#160;&#160;' x  $item->{level} . "</span>" .
            qq{<a href="#} . $anchor . qq{">} .
              $item->{string} . "</a></p>";
        push @out, $line;
    }
    if (@out) {
        return join ("\n", @out) . "\n";
    }
    else {
        return '';
    }
}

=item as_splat_html

Return a list of strings, each of them is a html page resulting from
the splitting of the as_html output. Linked footnotes as inserted at
the end of each page.

=cut

sub as_splat_html {
    my $self = shift;
    return @{ $self->_get_splat_body($self->_html_obj) };
}


=item raw_html_toc

Return an internal representation of the ToC

=cut

sub raw_html_toc {
    my $self = shift;
    my $html = $self->_html_obj;
    my @pieces = @{ $html->process(split => 1) };
    my @toc = $html->table_of_contents;
    my $missing = scalar(@pieces) - scalar(@toc);
    if ($missing) {
        if ($missing == 1) {
            unshift @toc, {
                           index => 0,
                           level => 2,
                           string => $html->header->{title} || "start body",
                          };
        }
        else {
            die "This shouldn't happen: missing pieces: $missing!";
        }
    }
    if (my $partials = $self->partials) {
        my @out;
        for (my $i = 0; $i < @toc; $i++) {
            push @out, $toc[$i] if $partials->{$i};
        }
        return @out;
    }
    return @toc;
}

=back

=head2 LaTeX output

=over 4

=item as_latex

Output the (Xe)LaTeX document (and cache it in the object), as a
string.

=cut

sub _latex_obj {
    my $self = shift;
    unless (defined $self->{_ltx_doc}) {
        $self->{_ltx_doc} =
          Text::Amuse::Output->new(
                                   document => $self->document,
                                   format => 'ltx',
                                  );
    }
    return $self->{_ltx_doc};
}

=item as_splat_latex

Return a list of strings, each of them is a LaTeX chunk resulting from
the splitting of the as_latex output.

=cut

sub as_latex {
    my $self = shift;
    unless (defined $self->{_latex_output_strings}) {
        $self->{_latex_output_strings} = $self->_get_full_body($self->_latex_obj);
    }
    return unless defined wantarray;
    return join("", @{ $self->{_latex_output_strings} });
}

sub as_splat_latex {
    my $self = shift;
    return @{ $self->_get_splat_body($self->_latex_obj) };
}

=item as_beamer

Output the document as LaTeX, but wrap each section which doesn't
contain a comment C<; noslide> inside a frame.

=cut

sub as_beamer {
    my $self = shift;
    my $latex = $self->_latex_obj->process;
    return Text::Amuse::Beamer->new(latex => $latex)->process;
}

=item wants_toc

Return true if a ToC is needed because we found some headings inside.

=item wants_preamble

Normally returns true. If partial output, only if the C<pre> string was passed.

Preamble is the title page, or the title/author/date chunk.

=item wants_postamble

Normally returns true. If partial output, only if the C<post> string was passed.

Postamble is the metadata of the text.

=cut

sub wants_preamble {
    my $self = shift;
    if (my $partials = $self->partials) {
        if ($partials->{pre}) {
            return 1;
        }
        else {
            return 0;
        }
    }
    return 1;
}

sub wants_postamble {
    my $self = shift;
    if (my $partials = $self->partials) {
        if ($partials->{post}) {
            return 1;
        }
        else {
            return 0;
        }
    }
    return 1;
}


sub wants_toc {
    my $self = shift;
    $self->as_latex;
    my @toc = $self->_latex_obj->table_of_contents;
    return scalar(@toc);
}


=item header_as_latex

The LaTeX formatted header, as an hashref. Keys are not interpolated
in any way.

=cut

sub header_as_latex {
    my $self = shift;
    $self->as_latex;
    unless (defined $self->{_cached_latex_header}) {
        $self->{_cached_latex_header} = $self->_latex_obj->header;
    }
    return { %{ $self->{_cached_latex_header} } };
}

=back

=head2 Helpers

=over 4

=item attachments

Report the attachments (images) found, as a list.

=cut

sub attachments {
    my $self = shift;
    $self->as_latex;
    return $self->document->attachments;
}

=item language_code

The language code of the document. This method will looks into the
header of the document, searching for the keys C<lang> or C<language>,
defaulting to C<en>.

=item language

Same as above, but returns the human readable version, notably used by
Babel, Polyglossia, etc.

=cut

sub _language_mapping {
    shift->document->_language_mapping;
}

=item header_defined

Return a convenience hashref with the header fields set to true when
they are defined in the document.

This way, in the template you can write doc.header_defined.subtitle
without doing crazy things like C<doc.header_as_html.subtitle.size>
which relies on virtual methods.

=cut

sub header_defined {
    my $self = shift;
    unless (defined $self->{_header_defined_hashref}) {
        my %fields;
        my %header = $self->document->raw_header;
        foreach my $k (keys %header) {
            if (defined($header{$k}) and length($header{$k})) {
                $fields{$k} = 1;
            }
        }
        $self->{_header_defined_hashref} = \%fields;
    }
    return { %{ $self->{_header_defined_hashref} } };
}


sub language_code {
    shift->document->language_code;
}
sub language {
    shift->document->language;
}

=item other_language_codes

Always return undef, because in the current implementation you can't
switch language in the middle of a text. But could be implemented in
the future. It should return an arrayref or undef.

=cut

sub other_language_codes {
    return;
}

=item other_languages

Always return undef. When and if implemented, it should return an
arrayref or undef.

=cut


sub other_languages {
    return;
}

=item hyphenation

Return a validated version of the C<#hyphenation> header, if present,
or the empty string.

=cut

sub hyphenation {
    my $self = shift;
    unless (defined $self->{_doc_hyphenation}) {
        my %header = $self->document->raw_header;
        my $hyphenation = $header{hyphenation} || '';
        my @validated = grep {
            m/\A(
            [[:alpha:]]+
            (-[[:alpha:]]+)*
            )\z/x
        } split(/\s+/, $hyphenation);
        $self->{_doc_hyphenation} = @validated ? join(' ', @validated) : '';
    }
    return $self->{_doc_hyphenation};
}

=item is_rtl

Return true if the language is RTL (ar, he, fa -- so far)

=item is_bidi

Return true if the document use direction switches.

=item html_direction

Return the direction (rtl or ltr) of the document, based on the
language

=item font_script

Return the script of the language.

Implemented for Russian, Macedonian, Farsi, Arabic, Hebrew. Otherwise
return Latin.

=cut

sub is_rtl {
    my $self = shift;
    my $lang = $self->language_code;
    my %rtl = (
               ar => 1,
               he => 1,
               fa => 1,
              );
    return $rtl{$lang};
}

sub is_bidi {
    my $self = shift;
    # trigger the parsing
    $self->as_latex;
    return $self->document->bidi_document;
}

sub html_direction {
    my $self = shift;
    if ($self->is_rtl) {
        return 'rtl';
    }
    else {
        return 'ltr';
    }
}

sub font_script {
    my $self = shift;
    my %scripts = (
                   mk => 'Cyrillic',
                   ru => 'Cyrillic',
                   fa => 'Arabic',
                   ar => 'Arabic',
                   he => 'Hebrew',
                  );
    return $scripts{$self->language_code} || 'Latin';
}

=back

=head1 DIFFERENCES WITH THE ORIGINAL EMACS MUSE MARKUP

The updated manual can be found at
L<http://www.amusewiki.org/library/manual> or
L<https://github.com/melmothx/amusewiki-site/blob/master/m/ml/manual.muse>

See the section "Differences between Text::Amuse and Emacs Muse".


=head3 Inline markup

Underlining has been dropped.

Emphasis and strong can also be written with tags, like <em>emphasis</em>,
<strong>strong</strong> and <code>code</code>.

Added tag <sup> and <sub> for superscript and subscript.

=head4 Inline logic

Asterisk and equal symbols (*, **, *** =) are interpreted as markup
elements if they are paired (an opening one and a closing one).

The opening one must be preceded by something which is not an
alphanumerical character (or at the beginning of the line) and
followed by something which is not a space.

The closing one must be preceded by something which is not a space,
and followed by something which is not an alphanumerical character (or
at the end of the line).

=head3 Block markup

The only tables supported are the native one (with ||| as separator).

Since version 0.60, the code blocks, beside the C<example> tag, can
also be written as:

  {{{
   if ($perl) {...}
  }}}

Borrowed from the Creole markup.

=head3 Others

Embedded lisp code and syntax highlight is not supported.

Esoteric stuff like citing from other resources is not supported.

The scope of this module is not to replicate all the features of the
original implementation, but to use the markup for a wiki (as opposed
as a personal and private wiki).

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author's email or
just use the CPAN's RT. If you find a bug, please provide a minimal
muse file which reproduces the problem (so I can add it to the test
suite).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Amuse

Repository available at GitHub: L<https://github.com/melmothx/text-amuse>

=head1 SEE ALSO

The original documentation for the Emacs Muse markup can be found at:
L<http://mwolson.org/static/doc/muse/Markup-Rules.html>

L<Text::Amuse::Compile> ships an executable to compile muse files.

Amusewiki, L<http://amusewiki.org>, a wiki/publishing engine which
uses this module under the hood (and for which this module was written
and is maintained).

=head1 LICENSE

This module is free software and is published under the same terms as
Perl itself.

=cut

1; # End of Text::Amuse
