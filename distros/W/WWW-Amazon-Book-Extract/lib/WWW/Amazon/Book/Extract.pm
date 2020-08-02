package WWW::Amazon::Book::Extract;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-15'; # DATE
our $DIST = 'WWW-Amazon-Book-Extract'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use HTML::Entities qw(decode_entities);

our %SPEC;

sub _strip_summary {
    my $html = shift;
    $html =~ s!<a[^>]+>.+?</a>!!sg;
    #$html = replace($html, {
    #    '&nbsp;' => ' ',
    #    '&raquo;' => '"',
    #    '&quot;' => '"',
    #});
    decode_entities($html);
    $html =~ s/\n+/ /g;
    $html =~ s/\s{2,}/ /g;
    $html;
}

$SPEC{parse_amazon_book_page} = {
    v => 1.1,
    summary => 'Extract information from an Amazon book page',
    args => {
        page_content => {
            schema => 'str*',
            req => 1,
            cmdline_src => 'stdin_or_file',
        },
    },
};
sub parse_amazon_book_page {
    my %args = @_;

    my $ct = $args{page_content} or return [400, "Please supply page_content"];

    my $res = {};
    my $resmeta = {};
    my $ld;

    # isbn
    if ($ct =~ m!<li><b>ISBN-10:</b> ([0-9Xx]+)</li>!) {
        $res->{isbn10} = $1;
    }
    if ($ct =~ m!<li><b>ISBN-13:</b> ([0-9Xx-]+)</li>!) {
        $res->{isbn13} = $1;
    }

    # title
    if ($ct =~ m!<span id="productTitle" class="a-size-large">(.+?)</span>!) {
        $res->{title} = $1;
    }

    # edition & pages
    if ($ct =~ m!<li><b>(Hardcover|Paperback):</b> ([0-9,]+) pages</li>!) {
        my ($edition, $num_pages) = ($1, $2);
        $num_pages =~ s/\D+//g;
        $res->{edition} = $edition;
        $res->{num_pages} = $num_pages;
    }

    # publisher & date
    if ($ct =~ m!<li><b>Publisher:</b> (.+?) \(([^)]+)\)</li>!) {
        my ($publisher, $pubdate) = ($1, $2);
        require DateTime::Format::Natural;
        my $dt = DateTime::Format::Natural->new->parse_datetime($pubdate);
        $res->{publisher} = $publisher;
        $res->{pub_date} = $dt->ymd if $dt;
    }

    [200, "OK", $res, $resmeta];
}

1;
# ABSTRACT: Extract information from an Amazon book page

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Amazon::Book::Extract - Extract information from an Amazon book page

=head1 VERSION

This document describes version 0.001 of WWW::Amazon::Book::Extract (from Perl distribution WWW-Amazon-Book-Extract), released on 2020-04-15.

=head1 FUNCTIONS


=head2 parse_amazon_book_page

Usage:

 parse_amazon_book_page(%args) -> [status, msg, payload, meta]

Extract information from an Amazon book page.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<page_content>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-Amazon-Book-Extract>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-Amazon-Book-Extract>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Amazon-Book-Extract>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The Amazon drivers for L<WWW::Scraper::ISBN>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
