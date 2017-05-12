package Text::PageLayout;

use utf8;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.05';

use Text::PageLayout::Page;
use Moo;
use Scalar::Util qw/reftype/;

with 'Text::PageLayout::PageElements';

has page_size  => (
    is          => 'rw',
    default     => sub { 67 },
);

has tolerance  => (
    is          => 'rw',
    default     => sub { 6 },
);

has fillup_pages  => (
    is          => 'rw',
    default     => sub { 1 },
);

has split_paragraph => (
    is          => 'rw',
    default     => sub {
        sub {
            my %param  = @_;
            my @lines  = split /\n/, $param{paragaraph}, $param{max_lines} + 1;
            my $last = pop @lines;
            return  (
                join("", map "$_\n", @lines),
                $last,
            );
        };
    },
);

sub line_count {
    my ($self, $str) = @_;
    my $cnt = $str =~ tr/\n//;
    return $cnt;
}

sub pages {
    my $self = shift;
    my @pars = @{ $self->paragraphs };
    my $separator    = $self->separator;
    my $sep_lines    = $self->line_count($separator);
    my $tolerance    = $self->tolerance;
    my $goal         = $self->page_size;
    my $current_page = 1;
    my $header       = $self->_get_elem('header', $current_page);
    my $footer       = $self->_get_elem('footer', $current_page);
    my $lines_used   = $self->line_count($header) + $self->line_count($footer);

    my @pages;
    my @current_pars;

    while (@pars) {
        my $paragraph = shift @pars;
        my $l = $self->line_count($paragraph);

        my $start_new_page = 0;
        # for a page with a single paragraph, we have no separation
        # lines, so the effective height introduce by separator is 0
        my $effective_sep_lines = @current_pars ? $sep_lines : 0;

        if ( $lines_used + $l + $effective_sep_lines <= $goal ) {
            # use the paragraph
            $lines_used += $l + $effective_sep_lines;
            push @current_pars, $paragraph;
        }
        elsif ( $lines_used + $tolerance >= $goal) {
            # start a new page, re-schedule the current paragraph
            $start_new_page = 1;
            unshift @pars, $paragraph;
        }
        else {
            # no such luck; start a new page, potentially by
            # splitting the paragraph
            $start_new_page = 1;
            my ($c1, $c2) = $self->split_paragraph->(
                paragraph   => $paragraph,
                max_lines   => $goal - $lines_used - $effective_sep_lines,
                page_number => $current_page,
            );
            my $c1_lines = $self->line_count($c1);
            if ($c1_lines + $lines_used + $effective_sep_lines <= $goal) {
                # accept the split
                $lines_used += $c1_lines + $effective_sep_lines;
                push @current_pars, $c1;
                # re-schedule the second chunk
                unshift @pars, $c2;
            }
            elsif (!@current_pars) {
                my $message = sprintf "Paragraph too long even after splitting (%d lines) to fit on a page (max height %d, header and foot take up %d lines in total)\n",
                   $c1_lines,
                   $goal,
                   $lines_used;
                require Carp;
                Carp::croak($message);
            }
        }
        if ($start_new_page) {
            push @pages, Text::PageLayout::Page->new(
                paragraphs          => [@current_pars],
                page_number         => $current_page,
                header              => $header,
                footer              => $footer,
                process_template    => $self->process_template,
                bottom_filler       => $self->fillup_pages
                                        ? "\n" x ($goal - $lines_used)
                                        : '',
                separator           => $separator,
            );
            $current_page++;
            @current_pars = ();
            $header       = $self->_get_elem('header', $current_page);
            $footer       = $self->_get_elem('footer', $current_page);
            $lines_used   = $self->line_count($header) + $self->line_count($footer);
        }
    }
    if (@current_pars) {
        # final page
        push @pages, Text::PageLayout::Page->new(
            paragraphs          => [@current_pars],
            page_number         => $current_page,
            header              => $header,
            footer              => $footer,
            process_template    => $self->process_template,
            bottom_filler       => $self->fillup_pages
                                    ? "\n" x ($goal - $lines_used)
                                    : '',
            separator           => $separator,
        );
    }
    for my $p (@pages) {
        $p->total_pages($current_page);
    }
    return @pages;
}

sub _get_elem {
    my ($self, $elem, $page) = @_;
    my $e = $self->$elem();
    if (ref $e && reftype($e) eq 'CODE') {
        $e = $e->(page_number => $page);
    }
    return $e;
}

=head1 NAME

Text::PageLayout - Distribute paragraphs onto pages, with headers and footers.

=head1 SYNOPSIS

    use 5.010;
    use Text::PageLayout;

    my @paragraphs = ("a\nb\nc\nd\n") x 6,

    # simple example
    my $layout = Text::PageLayout->new(
        page_size   => 20,      # number of lines per page
        header      => "head\n",
        footer      => "foot\n",
        paragraphs  => \@paragraphs,    # REQUIRED
    );

    for my $p ( $layout->pages ) {
        say "Page No. ", $p->page_number;
        say $p;
    }

    # more complex example:
    sub header {
        my %param = @_;
        if ($param{page_number} == 1) {
            return "header for first page\n";
        }
        return "== page %d of %d == \n";
    }
    sub process_template {
        my %param = @_;
        my $t = $param{template};
        if ($t =~ /%/) {
            return sprintf $t, $param{page_number}, $param{total_pages};
        }
        else {
            return $t;
        }
    }
    sub split_paragraph {
        my %param = @_;
        my ($first, $rest) = split /\n\n/, $param{paragraph}, 2;
        return ("$first\n", $rest);
    }

    
    $layout = Text::PageLayout->new(
        page_size           => 42,
        tolerance           => 2,
        paragraphs          => [ ... ],
        separator           => "\n\n",
        footer              => "\nCopyright (C) 2014 by M. Lenz\n",
        header              => \&header,
        process_template    => \&process_template,
        split_paragraph     => \&split_paragraph,
    );

=head1 DESCRIPTION

Text::PageLayout breaks up a list of paragraphs into pages. It supports
headers and footers, possibly varying by page number.

It operates under the assumption that all text blocks that are passed to
(header, footer, paragraphs, separator) are either the empty string, or
terminated by a newline. It also assumes that all those text blocks are
properly line-wrapped already.

The header and footer can either be strings, or subroutines that will be
called, and must return the string that is then used as a header or a footer.
In both cases, the string that is used as header or footer can be
post-processed with a custom callback C<process_template>.

The layout of a result page is always the header first, then as many
paragraphs as fit on the page, separated by C<separator>, followed by
as many blank lines as necessary to fill the page (if C<fillup_pages> is set,
which it is by default), followed by the footer.

If the naive layouting algorithm (take as many paragraphs as fit) leaves
more than C<tolerance> empty fill lines, the C<split_paragraph> callback is
called, which can attempt to split the paragraph into small chunks, which are
nicer to format.

=head1 ATTRIBUTES

Attributes should be set in the constructor (C<< Text::PageLayout->new >>),
but most of them can also be set later on, for example the C<page_size>
attribute with C<< $layout->page_size(42) >>.

Note that all callbacks receive named arguments, i.e. are called like this:

    $callback->(
        page_number => 1,
        total_pages => 2,
    );

Callbacks I<must> accept additional named arguments (future versions of this
module might pass more arguments).

=head2 page_size

Max. number of lines on a result page.

Default: 67

=head2 tolerance

Number of empty lines to accept on a page before attempting to split
paragraphs.

Default: 6 (subject to change)

=head2 paragraphs

An array reference of paragraphs (newline-terminated strings) that is to be
split up in pages.

This attribute is required.

=head2 header

A string that is used as a per-page header (or header template, if C<process_template> is
set), or a callback that returns the header.

If used as a callback, it receives C<page_number> as a named argument.

Default: empty string.

=head2 footer

A string that is used as a per-page footer (or footer template, if C<process_template> is
set), or a callback that returns the footer.

If used as a callback, it receives C<page_number> as a named argument.

Default: empty string.

=head2 fillup_pages

If set to a true value, pages are filled up to their maximum length by
adding newlines before the footer.

Default: 1.

=head2 separator

A string that is used to separate multiple paragraphs on the same page.

Default: "\n" (newline)

=head2 split_paragraph

A callback that can split a paragraph into smaller chunks to create nicer
layouts. If paragraphs exist that exceed the number of free lines on a page
that only contains header or footer, this callback B<must> split such a
paragraph into smaller chunks, the first of which must fit on a page.

The return value must be a list of paragraphs.

It receives the arguments C<paragraph>, C<max_lines> and C<page_number>.
C<max_lines> is the maximal number of lines that fit on the current page.

The default C<split_paragraph> simply splits off the first C<max_lines> as a
sparate chunk, without any consideration for its content.

=head2 process_template

A callback that turns a header or footer template into the actual header or
footer. It receives the named arguments C<template>, C<element> (which can be
C<header> or C<footer>), C<page_number> and C<total_pages>.

It must return a string with the same number of lines as the C<template>.

The default template callback simply returns the template.

=head1 METHODS

=head2 new

Creates a new C<Text::PageLayout> object. Expects attributes as named
arguments, with C<paragraphs> being the only required attribute.

=head2 pages

Returns a list of C<Text::PageLayout::Page> objects (which you can use like
strings, if you want to).

=head1 AUTHOR

Moritz Lenz, C<< <moritz at faui2k3.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-pagelayout at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-PageLayout>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::PageLayout

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-PageLayout>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-PageLayout>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-PageLayout>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-PageLayout/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<noris network AG|http://www.noris.net/> for letting the author
develop and open-source this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Moritz Lenz.
Written for L<noris network AG|http://www.noris.net/>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DEVELOPMENT

Development happens at github, see
L<https://github.com/moritz/perl5-Text-Layout>. Pull requests welcome!

=cut

1; # End of Text::PageLayout
