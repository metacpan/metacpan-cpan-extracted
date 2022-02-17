package Text::Amuse::Compile::Merged;

use strict;
use warnings;
use utf8;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_format_line/;
use Text::Amuse::Compile::Templates;
use Template::Tiny;

=encoding utf8

=head1 NAME

Text::Amuse::Compile::Merged - Merging muse files together.

=head2 

=head1 SYNOPSIS

  my $doc = Text::Amuse::Compile::Merged->new( files => ([ file1, file2, ..]);
  $doc->as_html;
  $doc->as_splat_html;
  $doc->as_latex;
  $doc->header_as_html;
  $doc->header_as_latex;

This module emulates a L<Text::Amuse> document merging files together,
and so it can be passed to Text::Amuse::Compile::File and have the
thing produced seemlessly.

=head1 METHODS

=head2 new(files => [qw/file1 file2/], title => 'blabl', ...)

The constructor requires the C<files> argument. Any other option is
considered part of the header of this virtual L<Text::Amuse> document.

On creation, the module will store in the object a list of
L<Text::Amuse> objects, which will be merged together.

When asking for header_as_html, you get the constructor options (save
for the C<files> option) properly formatted.

The headers of the individual merged files go into the body.

The first file determine the main language of the whole document.

Anyway, if it's a multilanguage text, hyphenation is supposed to
switch properly.

Optionally, C<include_paths> can be passed here.

=cut

sub new {
    my ($class, %args) = @_;
    my $files = delete $args{files};
    my $include_paths = delete $args{include_paths};
    die "Missing files" unless $files && @$files;
    my @docs;
    my (%languages, %language_codes);
    my ($main_lang, $main_lang_code);
    foreach my $file (@$files) {
        my %args;
        if (ref($file)) {
            %args = $file->text_amuse_constructor;
        }
        else {
            %args = (file => $file);
        }
        my $doc = Text::Amuse->new(%args,
                                   include_paths => $include_paths || [],
                                  );
        push @docs, $doc;

        my $current_lang_code = $doc->language_code;
        my $current_lang      = $doc->language;

        # the first file determine the main language
        $main_lang      ||= $current_lang;
        $main_lang_code ||= $current_lang_code;

        if ($main_lang ne $current_lang) {
            $languages{$current_lang}++;
            $language_codes{$current_lang_code}++;
        }
        foreach my $other (@{ $doc->other_languages || [] }) {
            if ($main_lang ne $other) {
                $languages{$other}++;
            }
        }
        foreach my $other (@{ $doc->other_language_codes || [] }) {
            if ($main_lang_code ne $other) {
                $language_codes{$other}++;
            }
        }
    }
    my (%html_headers, %latex_headers);
    foreach my $k (keys %args) {
        $html_headers{$k} = muse_format_line(html => $args{$k});
        $latex_headers{$k} = muse_format_line(ltx => $args{$k});
    }

    my $self = {
                headers => { %args },
                html_headers  => \%html_headers,
                latex_headers => \%latex_headers,
                files   => [ @$files ],
                docs    => \@docs,
                hyphenation => $docs[0]->hyphenation, # use the first
                language      => $main_lang,
                language_code => $main_lang_code,
                other_languages => \%languages,
                other_language_codes => \%language_codes,
                tt      => Template::Tiny->new,
                templates => Text::Amuse::Compile::Templates->new,
                font_script => $docs[0]->font_script,
                html_direction => $docs[0]->html_direction,
                is_rtl => $docs[0]->is_rtl,
                is_bidi => scalar(grep { $_->is_rtl || $_->is_bidi } @docs),
                include_paths => $include_paths || [],
               };
    bless $self, $class;
}

=head2 language

Return the english name of the main language

=head2 language_code

Return the code of the main language

=head2 other_languages

If it's a multilingual merged text, return an arrayref of the other
language names, undef otherwise.

=head2 other_language_codes

If it's a multilingual merged text, return an arrayref of the other
language codes, undef otherwise.

=head2 hyphenation

Return the hyphenation of the first text.

=head2 font_script

The font script of the first text.

=head2 html_direction

The direction (rtl or ltr) of the first text

=head2 is_rtl

Return true if the first text is RTL.

=head2 is_bidi

Return true if any of the text is RTL or bidirectional.

=head2 include_paths

Return the include paths set in the object.

=cut

sub include_paths {
    return @{shift->{include_paths}}
}

sub language {
    return shift->{language};
}

sub language_code {
    return shift->{language_code},
}

sub hyphenation {
    return shift->{hyphenation},
}

sub other_language_codes {
    my $self = shift;
    my %langs = %{ $self->{other_language_codes} };
    if (%langs) {
        return [ sort keys %langs ];
    }
    else {
        return;
    }
}

sub other_languages {
    my $self = shift;
    my %langs = %{ $self->{other_languages} };
    if (%langs) {
        return [ sort keys %langs ];
    }
    else {
        return;
    }
}

sub font_script {
    return shift->{font_script};
}

sub is_bidi {
    return shift->{is_bidi};
}

sub html_direction {
    return shift->{html_direction};
}
sub is_rtl {
    return shift->{is_rtl};
}

=head2 as_splat_html

Return a list of HTML fragments.

=head2 as_splat_html_with_attrs

Return a list of tokens for the minimal html template

=head2 as_html

As as as_splat_html but return a single string. This is invalid HTML
and it should be used only for debugging.

=cut

sub _as_splat_html {
    my ($self, %opts) = @_;
    my @out;
    my $counter = 0;
    foreach my $doc ($self->docs) {
        $counter++;
        # we need to add a title page for each fragment
        my $title_page = '';
        $self->tt->process($self->templates->title_page_html,
                           { doc => $doc },
                           \$title_page);

        # add a prefix to disambiguate anchors
        my $prefix = sprintf('piece%06d', $counter);
        my @pieces = $doc->as_splat_html;
        foreach my $piece (@pieces) {
            $piece =~ s/(<a\x{20}
                            (?:class="text-amuse-link"\x{20} href="\#
                            |id=")
                            text-amuse-label)/$1-$prefix/gx;
        }
        if ($opts{attrs}) {
            push @out, map {
                +{
                  text => $_,
                  language_code => $doc->language_code,
                  html_direction => $doc->html_direction,
                 }
            } ($title_page, @pieces);
        }
        else {
            push @out, $title_page, @pieces;
        }
    }
    return @out;
}

sub as_splat_html_with_attrs {
    return shift->_as_splat_html(attrs => 1);
}

sub as_splat_html {
    return shift->_as_splat_html;
}

sub as_html {
    return join("\n", shift->as_splat_html);
}

=head2 raw_html_toc

Implements the C<raw_html_toc> from L<Text::Amuse>

=cut

sub raw_html_toc {
    my $self = shift;
    my @out;
    my $index = 0;
    foreach my $doc ($self->docs) {

        # push the title page
        push @out, {
                    index => $index++,
                    level => 1,
                    string => $doc->header_as_html->{title},
                   };

        # do the same thing we do in the File.pm
        my @pieces = $doc->as_splat_html;
        my @toc = $doc->raw_html_toc;
        my $missing = scalar(@pieces) - scalar(@toc);
        die "This shouldn't happen: missing pieces: $missing" if $missing;
        # main loop
        foreach my $entry (@toc) {
            push @out, {
                        index => $index++,
                        level => $entry->{level},
                        string => $entry->{string},
                       };
        }
    }
    return @out;
}

=head2 attachments

Implement the C<attachments> method from C<Text::Amuse::Document>

=cut

sub attachments {
    my $self = shift;
    my %out;
    foreach my $doc ($self->docs) {
        foreach my $attachment ($doc->attachments) {
            $out{$attachment} = 1;
        }
    }
    return sort keys %out;
}

=head2 included_files

Implement the C<included_files> method from C<Text::Amuse::Document>

=cut


sub included_files {
    my $self = shift;
    my @out;
    foreach my $doc ($self->docs) {
        push @out, $doc->included_files;
    }
    return @out;
}

=head2 as_latex

Return the latex body

=cut

sub as_latex {
    my $self = shift;
    my @out;
    my $current_language = $self->language;
    my $counter = 0;
    foreach my $doc ($self->docs) {
        $counter++;
        my $prefix = sprintf('piece%06d', $counter);
        my $output = "\n\n";

        my $doc_language = $doc->language;

        if ($doc_language ne $current_language) {
            $output .= sprintf('\selectlanguage{%s}', $doc_language) . "\n\n";
            $current_language = $doc_language;
        }

        my $template_output = '';
        $self->tt->process($self->templates->bare_latex,
                           { doc => $doc },
                           \$template_output);
        # disambiguate the refs names when merging
        $template_output =~ s/(
                                  \\hyper(def|ref\{\})
                                  \{
                              )
                              amuse
                              (\})
                             /$1${prefix}amuse$3/gx;
        $output .= $template_output;
        push @out, $output;
    }
    return join("\n\n", @out, "\n");
}


=head2 wants_toc

Always returns true

=head2 wants_postamble

Always returns true

=head2 wants_preamble

Always returns true

=cut

sub wants_toc       { return 1; }

sub wants_postamble { return 1; }

sub wants_preamble  { return 1; }

=head2 is_deleted

Always returns false

=cut

sub is_deleted {
    return 0;
}


=head2 header_as_latex

Returns an hashref with the LaTeX-formatted info (passed to the constructor).

=head2 header_as_html

Same as above, but with HTML format.

=cut

sub header_as_latex {
    return { %{ shift->{latex_headers} } };
}

sub header_as_html {
    return { %{ shift->{html_headers} } };
}

=head2 header_defined

Implements the C<header_defined> method of L<Text::Amuse>.

=cut

sub header_defined {
    my $self = shift;
    unless (defined $self->{_header_defined_hashref}) {
        my %fields;
        my %headers = $self->headers;
        foreach my $k (keys %headers) {
            if (defined($headers{$k}) and length($headers{$k})) {
                $fields{$k} = 1;
            }
        }
        $self->{_header_defined_hashref} = \%fields;
    }
    return { %{ $self->{_header_defined_hashref} } };
}



=head1 INTERNALS

=head2 docs

Accessor to the list of L<Text::Amuse> objects.

=head2 files

Accessor to the list of files.

=head3 headers

Accessor to the headers.

=head3 tt

Accessor to the L<Template::Tiny> object.

=head3 templates

Accessor to the L<Text::Amuse::Compile::Templates> object.

=cut

sub docs {
    return @{ shift->{docs} };
}

sub files {
    return @{ shift->{files} };
}

sub headers {
    return %{ shift->{headers} };
}

sub tt {
    return shift->{tt};
}

sub templates {
    return shift->{templates};
}


1;

