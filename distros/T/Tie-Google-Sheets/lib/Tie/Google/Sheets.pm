use warnings;
use v5.42;

package Tie::Google::Sheets 0.02 {

    # ABSTRACT: Tie perl variables to Google Sheets

    use Carp qw( croak );
    use List::Util qw( any );
    use Ref::Util qw( is_plain_hashref );
    use Tie::Google::Sheets::Client;
    use Tie::Google::Sheets::Worksheet;

    our @CARP_NOT = qw( Tie::Google::Sheets::Client Tie::Google::Sheets::Worksheet Class::Tiny::Object );

    use Class::Tiny qw( _client ), {
        _worksheets => sub { {} },
    };

    sub BUILDARGS ($class, %args) {
        return {
            _client => Tie::Google::Sheets::Client->new(%args),
        };
    }

    sub TIEHASH ($class, %args) {
        return $class->new(%args);
    }

    sub FETCH ($self, $title) {
        return $self->_worksheets->{$title} if exists $self->_worksheets->{$title};
        return undef unless $self->EXISTS($title);

        my %worksheet;
        tie %worksheet, 'Tie::Google::Sheets::Worksheet', client => $self->_client, title => $title;
        return $self->_worksheets->{$title} = \%worksheet;
    }

    sub STORE ($self, $title, $value) {
        croak "worksheet '$title' already exists; assign individual cells instead, e.g. \$doc{$title}{A1} = ..."
            if $self->EXISTS($title);
        croak 'a new worksheet may only be assigned undef, or a hashref of cell => value pairs'
            if defined($value) && !is_plain_hashref($value);

        $self->_client->add_sheet($title);
        delete $self->_worksheets->{$title};

        if(is_plain_hashref($value)) {
            my $worksheet = $self->FETCH($title);
            $worksheet->{$_} = $value->{$_} for keys $value->%*;
        }

        return $value;
    }

    sub DELETE ($self, $title) {
        $self->_client->delete_sheet($title);
        delete $self->_worksheets->{$title};
        return undef;
    }

    sub EXISTS ($self, $title) {
        return !!any { $_ eq $title } $self->_client->sheet_titles->@*;
    }

    sub CLEAR ($self) {
        croak 'cannot delete every worksheet by clearing the tied hash (a spreadsheet must keep at least one worksheet); '
            . 'use delete $doc{$title} to remove individual worksheets';
    }

    sub FIRSTKEY ($self) {
        $self->{_iter}     = $self->_client->sheet_titles;
        $self->{_iter_pos} = 0;
        return $self->NEXTKEY;
    }

    sub NEXTKEY ($self, $lastkey = undef) {
        my $titles = $self->{_iter} // [];
        return undef if $self->{_iter_pos} >= @$titles;
        return $titles->[ $self->{_iter_pos}++ ];
    }

    sub add_worksheet ($self, $title, $values = undef) {
        $self->STORE($title, $values);
        return $self->FETCH($title);
    }

    sub delete_worksheet ($self, $title) {
        return $self->DELETE($title);
    }

    sub copy_worksheet ($self, $from_title, $to_title) {
        croak "worksheet '$to_title' already exists; delete it first, or choose a different name"
            if $self->EXISTS($to_title);

        $self->_client->copy_worksheet($from_title, $to_title);
        delete $self->_worksheets->{$to_title};

        return $self->FETCH($to_title);
    }

    sub worksheet_titles ($self) {
        return $self->_client->sheet_titles->@*;
    }

    sub flush ($self) {
        $self->_client->flush;
        return;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Google::Sheets - Tie perl variables to Google Sheets

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Tie::Google::Sheets;
 
 tie my %doc, 'Tie::Google::Sheets',
     spreadsheet_id  => '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms',
     service_account => '/path/to/service-account-key.json';
 
 # read and write individual cells
 my $name = $doc{Employees}{A1};
 $doc{Employees}{A2} = 'Grace Hopper';
 
 # create a new worksheet, optionally pre-populated
 tied(%doc)->add_worksheet('Report', { A1 => 'Total', B1 => 42 });
 
 # iterate over worksheet tabs
 for my $title (keys %doc) {
     print "$title\n";
 }
 
 # remove a worksheet
 delete $doc{Report};

=head1 DESCRIPTION

This module ties a Perl hash to a Google Sheets spreadsheet document. The
outer hash is keyed by worksheet (tab) title; each value is itself a hash
(implemented by L<Tie::Google::Sheets::Worksheet>) keyed by cell reference in
A1 notation (C<A1>, C<B12>, and so on), so that a spreadsheet can be read and
written using ordinary Perl hash syntax:

 $doc{'Sheet1'}{'A1'} = 'hello';
 print $doc{'Sheet1'}{'A1'};

Authentication is via a Google service account. Remember to share the
spreadsheet (or its containing folder) with the service account's
C<client_email> address, the same way you would share it with any other
Google account, otherwise API calls will fail with a permission error.

=head1 CONSTRUCTOR

 tie my %doc, 'Tie::Google::Sheets', %options;

C<%options> may contain:

=over 4

=item spreadsheet_id

The id of the spreadsheet, taken from its URL
(C<https://docs.google.com/spreadsheets/d/E<lt>idE<gt>/edit>). Required
unless L</spreadsheet_url> is given instead.

=item spreadsheet_url

The full URL of the spreadsheet, from which the spreadsheet id will be
extracted. Ignored if L</spreadsheet_id> is also given.

=item service_account

Either a hash reference containing the decoded contents of a Google service
account JSON key file, or a path to the key file itself. Required unless
L</access_token> is given instead.

=item access_token

An OAuth2 bearer token (or a code reference which returns one) to use
instead of authenticating with a service account. Useful when the caller
already has its own way of obtaining and refreshing tokens (or, in tests,
for supplying a fake token).

=item ua

A user agent object (for example an L<HTTP::Tiny> or L<LWP::UserAgent>
instance) to be wrapped in an L<HTTP::AnyUA>. Defaults to a plain
L<HTTP::Tiny> instance.

=item any_ua

An already constructed L<HTTP::AnyUA> compatible object (that is, anything
providing a C<request($method, $url, \%options)> method with the same
contract as L<HTTP::Tiny>). Used as-is instead of wrapping L</ua>. Mutually
exclusive with L</ua>.

=item batch_size

Enables write batching. When set to a positive integer, cell writes (that
is, C<< $doc{$title}{$cell} = $value >>) are queued instead of being sent
immediately, and are combined into a single API call once the queue reaches
C<batch_size> pending writes. Defaults to C<undef>, meaning every write is
sent immediately as its own API call.

Regardless of C<batch_size>, queued writes are always flushed before they
could otherwise be observed out of order: immediately before any read,
before any worksheet is added or deleted, and when C<%doc> (or the last
reference to it) goes out of scope. Queued writes can also be flushed
explicitly at any time; see L</flush>.

=item backoff_retry

Enables automatic retry when Google rate limits a request (HTTP status
429). When set to a positive integer, a rate limited API call is retried
that many times, with exponential backoff (1, 2, 4, ... seconds) between
attempts, before giving up and croaking. Defaults to C<undef>, meaning a
rate limited request fails immediately.

=back

=head1 TIE METHODS

This class implements the standard L<perltie> C<TIEHASH> protocol; see
L<perltie> for the full semantics of each method.

=head2 TIEHASH

Constructor, called via C<tie>; see L</CONSTRUCTOR> above.

=head2 FETCH

Returns the worksheet named by the given key, as a hashref implemented by
L<Tie::Google::Sheets::Worksheet>, or C<undef> if no worksheet with that
title exists on the server.

=head2 STORE

Creates a new worksheet. The key is the new worksheet's title; the value
must be C<undef> or a hashref of cell reference / value pairs to populate
it with. Croaks if a worksheet with that title already exists.

=head2 DELETE

Deletes a worksheet.

=head2 EXISTS

Returns true if a worksheet with the given title exists.

=head2 CLEAR

Always croaks: a spreadsheet must keep at least one worksheet, so the
tied hash cannot be emptied wholesale.

=head2 FIRSTKEY, NEXTKEY

Together implement iteration (C<keys>, C<values>, C<each>) over the
spreadsheet's worksheet titles.

=head1 METHODS

These are ordinary (non-tie) methods available on the underlying object via
C<tied %doc>.

=head2 add_worksheet

 tied(%doc)->add_worksheet($title);
 tied(%doc)->add_worksheet($title, \%cells);

Creates a new worksheet named C<$title>. If C<\%cells> is given, its
key/value pairs are written into the new worksheet as cell reference /
value pairs. Returns the new worksheet hashref, the same as C<$doc{$title}>.

This is equivalent to C<< $doc{$title} = \%cells >>.

=head2 delete_worksheet

 tied(%doc)->delete_worksheet($title);

Deletes the worksheet named C<$title>. Equivalent to C<< delete $doc{$title} >>.

=head2 copy_worksheet

 tied(%doc)->copy_worksheet($from_title, $to_title);

Copies the worksheet named C<$from_title> to a new worksheet named
C<$to_title>, including its formatting, data validation, and other
properties, not just its cell values. Croaks if C<$from_title> doesn't
exist, or if C<$to_title> already exists. Returns the new worksheet
hashref, the same as C<$doc{$to_title}>.

=head2 worksheet_titles

 my @titles = tied(%doc)->worksheet_titles;

Returns the titles of all worksheets in the spreadsheet, in the order
Google Sheets returns them. Equivalent to C<< keys %doc >>.

=head2 flush

 tied(%doc)->flush;

Sends any cell writes queued by the L</batch_size> constructor option as a
single API call. A no-op if C<batch_size> wasn't given, or if there is
nothing queued. See L</batch_size> for when this happens automatically.

=head1 CAVEATS

=over 4

=item *

Every cell access is a separate Google Sheets API call; there is no local
caching, and writes are not batched unless L</batch_size> is given. Be
mindful of
L<Google's API quotas|https://developers.google.com/sheets/api/limits> if
you access many cells.

=item *

A spreadsheet must always have at least one worksheet, so C<%doc> cannot be
emptied with C<%doc = ()>; delete worksheets individually instead.

=item *

Only cell values are read and written; formatting, formulas results vs
formula text, and other cell metadata are not exposed.

=item *

Because of how Perl autovivifies nested data structures, reading or writing
a cell of a worksheet that doesn't yet exist (for example
C<< $doc{NewSheet}{A1} >>) creates that worksheet as a side effect, the same
way C<< $doc{NewSheet} = undef >> would. To check whether a worksheet
exists without creating it, use C<exists $doc{$title}> or
L</worksheet_titles>, not a truth test on C<$doc{$title}>.

=back

=head1 SEE ALSO

=over 4

=item L<Tie::Google::Sheets::Worksheet>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
