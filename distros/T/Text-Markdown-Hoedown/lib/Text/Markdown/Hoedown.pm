package Text::Markdown::Hoedown;
use 5.008005;
use strict;
use warnings;
use parent qw(Exporter);

our $VERSION = "1.03";

our @EXPORT = qw(
    markdown
    markdown_toc
);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub markdown {
    my $str = shift;
    my %args = (
        html_options    => 0,
        extensions      => 0,
        max_nesting     => 16,
        toc_nesting_lvl => 99,
        @_,
    );

    my $renderer = Text::Markdown::Hoedown::Renderer::HTML->new(
        $args{html_options},
        $args{toc_nesting_lvl},
    );
    my $md = Text::Markdown::Hoedown::Markdown->new(
        $args{extensions},
        $args{max_nesting},
        $renderer
    );
    return $md->render($str);
}

sub markdown_toc {
    my $str = shift;
    my %args = (
        nesting_level   => 6,
        extensions      => 0,
        max_nesting     => 16,
        @_,
    );

    my $renderer = Text::Markdown::Hoedown::Renderer::HTMLTOC->new(
        $args{nesting_level},
    );
    my $md = Text::Markdown::Hoedown::Markdown->new(
        $args{extensions},
        $args{max_nesting},
        $renderer,
    );
    return $md->render($str);
}

1;
__END__

=for stopwords sundown hoedown markdown subtree

=encoding utf-8

=head1 NAME

Text::Markdown::Hoedown - hoedown for Perl5

=head1 SYNOPSIS

    use Text::Markdown::Hoedown;

    print markdown(<<'...');
    # foo

    bar

      * hoge
      * fuga
    ...

=head1 DESCRIPTION

Text::Markdown::Hoedown is binding library for hoedown.

hoedown is a forking project from sundown.

=head1 FUNCTIONS

=over 4

=item C< my $out = markdown($src :Str, %options) :Str >

Rendering markdown.

Options are following:

=over 4

=item toc_nesting_lvl

Nesting levels for TOC generation.

(Default: 99)

=item extensions

This is bit flag.  You can use the flags by '|' operator.
Values are following:

=over 4

=item HOEDOWN_EXT_TABLES

Parse PHP-Markdown style tables.

=item HOEDOWN_EXT_FENCED_CODE

Parse fenced code blocks.

=item HOEDOWN_EXT_FOOTNOTES

Parse footnotes.

=item HOEDOWN_EXT_AUTOLINK

Automatically turn safe URLs into links.

=item HOEDOWN_EXT_STRIKETHROUGH

Parse ~~stikethrough~~ spans.

=item HOEDOWN_EXT_UNDERLINE

Parse _underline_ instead of emphasis.

=item HOEDOWN_EXT_HIGHLIGHT

Parse ==highlight== spans.

=item HOEDOWN_EXT_QUOTE

Render "quotes" as E<lt>qE<gt>quotesE<lt>/qE<gt>.

=item HOEDOWN_EXT_SUPERSCRIPT

Parse super^script.

=item HOEDOWN_EXT_MATH

Parse TeX $$math$$ syntax, Kramdown style.

=item HOEDOWN_EXT_NO_INTRA_EMPHASIS

Disable emphasis_between_words.

=item HOEDOWN_EXT_SPACE_HEADERS

Require a space after '#' in headers.

=item HOEDOWN_EXT_MATH_EXPLICIT

Instead of guessing by context, parse $inline math$ and $$always block math$$ (requires HOEDOWN_EXT_MATH).

=item HOEDOWN_EXT_DISABLE_INDENTED_CODE

Don't parse indented code blocks.

=back

=item html_options

This is bit flag.  You can use the flags by '|' operator.
Values are following:

=over 4

=item HOEDOWN_HTML_SKIP_HTML

Strip all HTML tags.

=item HOEDOWN_HTML_ESCAPE

Escape all HTML.

=item HOEDOWN_HTML_HARD_WRAP

Render each linebreak as E<lt>brE<gt>.

=item HOEDOWN_HTML_USE_XHTML

Render XHTML.

=back

=item max_nesting

I don't know what this do.

=back

=item C<< markdown_toc($src:Str, %opts) :Str >>

Generate TOC HTML from C<$str>.

Options are following:

=over 4

=item nesting_level

Maximum nesting level for TOC.

=item extensions

Same as above.

=item max_nesting

Same as above.

=back

All C<HOEDOWN_*> constants are exported by default.

=back

=head1 TODO

=over 4

=item Document about low level APIs

=back

=head1 HACKING

C<hoedown/> directory is managed by git subtree.

You can pull the modifications from upstream by following command:

     git subtree pull --prefix=hoedown git@github.com:hoedown/hoedown.git master

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

