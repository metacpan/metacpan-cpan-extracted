package WWW::RT::CPAN;

our $DATE = '2017-02-03'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       list_dist_active_tickets
                       list_dist_resolved_tickets
                       list_dist_rejected_tickets
               );

our %SPEC;

my %dist_arg = (
    dist => {
        schema => 'perl::distname*',
        req => 1,
        pos => 0,
    },
);

sub _list_dist_tickets {
    require HTTP::Tiny;
    require HTML::Entities;

    my ($dist, $status) = @_;

    my $url = "https://rt.cpan.org/Public/Dist/Display.html?Status=$status;Name=$dist";
    my $res = HTTP::Tiny->new->get($url);
    unless ($res->{success}) {
        return [$res->{status}, "Can't get $url: $res->{reason}"];
    }
    if ($res->{content} =~ /<title>Unable to find distribution/) {
        return [404, "No such distribution"];
    }
    my @tickets;
    while ($res->{content} =~ m!<tr[^>]*>\s*
                                <td[^>]*><a[^>]+>(\d+)</a></td>\s* # 1) id
                                <td[^>]*><b><a[^>]+>(.+?)</a></b></td>\s* # 2) title
                                <td[^>]*>(.*?)</td>\s* # 3) status
                                <td[^>]*>(.*?)</td>\s* # 4) severity
                                <td[^>]*><small>(.*?)</small></td>\s* # 5) last updated
                                <td[^>]*>(.*?)</td>\s* # 6) broken in
                                <td[^>]*>(.*?)</td>\s* # 7) fixed in
                                #</tr>
                               !gsx) {
        push @tickets, {
            id => $1,
            title => HTML::Entities::decode_entities($2),
            status => $3,
            severity => $4,
            last_updated_raw => $5,
            # last_update => parse $5, but the duration is not accurate e.g. '7 months ago'
            broken_in => [split '<br />', ($6 // '')],
            fixed_in => [split '<br />', ($7 // '')],
        };
    }
    [200, "OK", \@tickets];
}

$SPEC{list_dist_active_tickets} = {
    v => 1.1,
    summary => 'List active tickets for a distribution',
    args => {
        %dist_arg,
    },
};
sub list_dist_active_tickets {
    my %args = @_;
    _list_dist_tickets($args{dist}, 'Active');
}

$SPEC{list_dist_resolved_tickets} = {
    v => 1.1,
    summary => 'List resolved tickets for a distribution',
    args => {
        %dist_arg,
    },
};
sub list_dist_resolved_tickets {
    my %args = @_;
    _list_dist_tickets($args{dist}, 'Resolved');
}

$SPEC{list_dist_rejected_tickets} = {
    v => 1.1,
    summary => 'List rejected tickets for a distribution',
    args => {
        %dist_arg,
    },
};
sub list_dist_rejected_tickets {
    my %args = @_;
    _list_dist_tickets($args{dist}, 'Rejected');
}

1;
# ABSTRACT: Scrape information from https://rt.cpan.org

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::RT::CPAN - Scrape information from https://rt.cpan.org

=head1 VERSION

This document describes version 0.002 of WWW::RT::CPAN (from Perl distribution WWW-RT-CPAN), released on 2017-02-03.

=head1 SYNOPSIS

 use WWW::RT::CPAN qw(
     list_dist_active_tickets
     list_dist_resolved_tickets
     list_dist_rejected_tickets
 );

 my $res = list_dist_active_tickets(dist => 'Acme-MetaSyntactic');

Sample result:

 [
   200,
   "OK",
   [
     {
       broken_in => [], # e.g. ["0.40", "0.41"]
       fixed_in => [],
       id => 120076,
       last_updated_raw => "8 hours ago",
       severity => "Wishlist",
       status => "new",
       title => "Option to return items in order?",
     },
     {
       broken_in => [],
       fixed_in => [],
       id => 118805,
       last_updated_raw => "3 months ago",
       severity => "Wishlist",
       status => "new",
       title => "Print list of categories of a theme?",
     },
   ],
  ]

Another example (dist not found):

 my $res = list_dist_active_tickets(dist => 'Foo-Bar');

Example result:

 [400, "No such distribution"]

=head1 DESCRIPTION

This module provides some functions to retrieve data from L<https://rt.cpan.org>
by scraping the web pages. Compared to L<RT::Client::REST>, it provides less
functionality but it can get public information without having to log in first.

=head1 FUNCTIONS


=head2 list_dist_active_tickets

Usage:

 list_dist_active_tickets(%args) -> [status, msg, result, meta]

List active tickets for a distribution.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist>* => I<perl::distname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_dist_rejected_tickets

Usage:

 list_dist_rejected_tickets(%args) -> [status, msg, result, meta]

List rejected tickets for a distribution.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist>* => I<perl::distname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_dist_resolved_tickets

Usage:

 list_dist_resolved_tickets(%args) -> [status, msg, result, meta]

List resolved tickets for a distribution.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist>* => I<perl::distname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-RT-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-RT-CPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-RT-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<RT::Client::REST>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
