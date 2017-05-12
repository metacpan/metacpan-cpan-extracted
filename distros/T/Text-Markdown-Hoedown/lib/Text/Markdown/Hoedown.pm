package Text::Markdown::Hoedown;
use 5.008005;
use strict;
use warnings;
use parent qw(Exporter);

our $VERSION = "1.01";

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

    enum hoedown_extensions {
        HOEDOWN_EXT_NO_INTRA_EMPHASIS = (1 << 0),
        HOEDOWN_EXT_TABLES = (1 << 1),
        HOEDOWN_EXT_FENCED_CODE = (1 << 2),
        HOEDOWN_EXT_AUTOLINK = (1 << 3),
        HOEDOWN_EXT_STRIKETHROUGH = (1 << 4),
        HOEDOWN_EXT_UNDERLINE = (1 << 5),
        HOEDOWN_EXT_SPACE_HEADERS = (1 << 6),
        HOEDOWN_EXT_SUPERSCRIPT = (1 << 7),
        HOEDOWN_EXT_LAX_SPACING = (1 << 8),
        HOEDOWN_EXT_DISABLE_INDENTED_CODE = (1 << 9),
        HOEDOWN_EXT_HIGHLIGHT = (1 << 10),
        HOEDOWN_EXT_FOOTNOTES = (1 << 11),
        HOEDOWN_EXT_QUOTE = (1 << 12)
    };

=item html_options

This is bit flag.  You can use the flags by '|' operator.
Values are following:

    typedef enum {
        HOEDOWN_HTML_SKIP_HTML = (1 << 0),
        HOEDOWN_HTML_SKIP_STYLE = (1 << 1),
        HOEDOWN_HTML_SKIP_IMAGES = (1 << 2),
        HOEDOWN_HTML_SKIP_LINKS = (1 << 3),
        HOEDOWN_HTML_EXPAND_TABS = (1 << 4),
        HOEDOWN_HTML_SAFELINK = (1 << 5),
        HOEDOWN_HTML_TOC = (1 << 6),
        HOEDOWN_HTML_HARD_WRAP = (1 << 7),
        HOEDOWN_HTML_USE_XHTML = (1 << 8),
        HOEDOWN_HTML_ESCAPE = (1 << 9),
        HOEDOWN_HTML_PRETTIFY = (1 << 10)
    } hoedown_html_render_mode;

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

