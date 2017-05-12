package WWW::KeenIO;

use 5.010;
use strict;
use warnings;

=head1 NAME

WWW::KeenIO - Perl API for Keen.IO L<< http://keen.io >> event storage and analytics

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use Carp qw(cluck);
use Data::Dumper;
use REST::Client;
use JSON::XS;
use URI;
use Scalar::Util qw(blessed reftype);
use Readonly;
use Exporter 'import';

use Mouse;

#** @attr public api_key $api_key API access key
#*
has api_key => ( isa => 'Str', is => 'rw', required => 1 );

#** @attr public CodeRef $read_key API key for writing data (if different from api_key
#*
has write_key => ( isa => 'Maybe[Str]', is => 'rw' );

#** @attr public Int $project_id ID of the project
#*
has project => ( isa => 'Str', is => 'rw', required => 1 );

#** @attr protected String $base_url Base REST URL
#*
has base_url => (
    isa     => 'Str',
    is      => 'rw',
    default => 'https://api.keen.io/3.0/'
);

Readonly my $REST_data => {
    put => {
        path  => 'projects/$project/events/$collection',
        write => 1
    },
    batch_put => {
        path  => 'projects/$project/events',
        write => 1
    },
    select => {
        path => 'projects/$project/queries/extraction'
    }
};

Readonly our $KEEN_OP_EQ       => 'eq';
Readonly our $KEEN_OP_NE       => 'ne';
Readonly our $KEEN_OP_EXISTS   => 'exists';
Readonly our $KEEN_OP_IN       => 'exists';
Readonly our $KEEN_OP_CONTAINS => 'contains';

my @operators = qw($KEEN_OP_EQ $KEEN_OP_NE $KEEN_OP_EXISTS $KEEN_OP_IN
  $KEEN_OP_CONTAINS);
our @EXPORT_OK = (@operators);
our %EXPORT_TAGS = ( 'operators' => [@operators] );

#** @attr protected CodeRef $ua Reference to the REST UA
#*
has ua => (
    isa      => 'Object',
    is       => 'rw',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        return REST::Client->new();
    }
);

#** @attr public String $error_message Error message regarding the last failed operation
#*
has error_message =>
  ( isa => 'Str', is => 'rw', init_arg => undef, default => '' );

sub _url {
    my ( $self, $path, $url_params, $query_params ) = @_;

    $url_params //= {};
    $url_params->{project} = $self->project
      unless defined( $url_params->{project} );
    $query_params //= {};
    my $url = $self->base_url . $path;
    $url =~ s^\$([\w\d\_]+)^$url_params->{$1} // ''^eg;
    my $uri = URI->new( $url, 'http' );
    $uri->query_form($query_params);
    #print "URL=".$uri->as_string;
    return $uri->as_string;
}

sub _process_response {
    my ( $self, $response ) = @_;

    if ($@) {
        $self->error_message("Error $@");
        return undef;
    } elsif ( !blessed($response) ) {
        $self->error_message(
            "Unknown response $response from the REST client instead of object"
        );
        return undef;
    }
    print "Got response:"
      . Dumper( $response->responseCode() ) . "/"
        . Dumper( $response->responseContent() ) . "\n" if $ENV{DEBUG};
    my $code = $response->responseCode();
    my $parsed_content = eval { decode_json( $response->responseContent() ) };
    if ($@) {
        cluck(  "Cannot parse response content "
              . $response->responseContent()
              . ", error msg: $@. Is this JSON?" );
        $parsed_content = {};
    }
    print "parsed ".Dumper($parsed_content) if $ENV{DEBUG};
    if ( $code ne '200' && $code ne '201' ) {
        my $err = "Received error code $code from the server instead of "
          . 'expected 200/201';
        if ( reftype($parsed_content) eq 'HASH'
            && $parsed_content->{message} )
        {
            $err .=
                "\nError message from KeenIO: "
              . $parsed_content->{message}
              . ( $parsed_content->{error_code}
                ? ' (' . $parsed_content->{error_code} . ')'
                : q{} );

            $self->error_message($err);
        }
        return undef;
    }

    $self->error_message(q{});
    return $parsed_content;
}

sub _transaction {
    my ( $self, $query_params, $data ) = @_;

    my $caller_sub = ( split( '::', ( caller(1) )[3] ) )[-1];
    my $rest_data = $REST_data->{$caller_sub};

    $data //= {};
    my $key =
      $rest_data->{write}
      ? ( $self->write_key // $self->api_key )
      : $self->api_key;
    my $method_path = $rest_data->{path};
    confess("No URL path defined for method $caller_sub") unless $method_path;

    my $url = $self->_url( $method_path, $query_params );
    my $headers = {
        'Content-Type' => 'application/json',
        Authorization  => $key
    };
    my $response =
      eval { $self->ua->POST( $url, encode_json($data), $headers ); };
    cluck($@) if $@;
    return $self->_process_response($response);
}

=head1 SYNOPSIS

    use WWW::KeenIO qw(:operators);
    use Text::CSV_XS;
    use Data::Dumper;

    my $csv = Text::CSV_XS->new;
    my $keen = WWW::KeenIO->new( {
          project    => '123',
          api_key   => '456',
          write_key  => '789'
    }) or die 'Cannot create KeenIO object';

    # process a CSV file with 3 columns: name, in|out, date-time
    # import them as keenIO events
    while(<>) {
      chomp;
      my $status = $csv->parse($_);
      unless ($status) {
          warn qq{Cannot parse '$_':}.$csv->error_diag();
          next;
      }
      my @fields = $csv->fields();
      my $data = {
          keen => {
             timestamp => $fields[2]
          },
          name => $fields[0],
          type => $fields[1]
      };
      my $res = $keen->put('in_out_log', $data);
      unless ($res) {
         warn "Unable to store the data in keenIO";
      }
    }
 
    # now read the data
    my $data = $keen->select('in_out_log', 'this_7_days',
        [ $keen->filter('name', $KEEN_OP_EQ, 'John Doe') ] );
    print Dumper($data);

=head1 CONSTRUCTOR

=head2 new( hashref )

Creates a new object, acceptable parameters are:

=over 16

=item C<api_key> - (required) the key to be used for read operations

=item C<project> - (required) the ID of KeenIO project

=item C<write_key> - the key to be used for write operations (if different from api_key)

=item C<base_url> - L<< https://api.keen.io/3.0/ >> by default; in case if you are using KeenIO-compatible API on some other server you can specify your own URL here

=back

=head1 METHODS

=head2 put( $collection_name, $data )

Inserts an event (C<$data> is a hashref) into the collection. Returns a 
reference to a hash, which contains the response
received from the server (typically there is a key C<created> with
C<true> value). Returns C<undef> on failure, application then may call
C<error_message()> method to get the detailed info about the error.

    my $res = $keen->put('in_out_log', $data);
    unless ($res) {
        warn 'Something went wrong '.$keen->error_message();
    }

=cut

sub put {
    my ( $self, $collection, $record ) = @_;
    return $self->_transaction(
        {
            collection => $collection
        },
        $record
    );
}

=head2 batch_put( $data )

Inserts multiple events into Keen. C<$data> is a hashref, where every key
represents a collection name, where data should be inserted. Value of
the key is a reference to an array, which contains references to
individual event data (hashes).

Returns C<undef> on total failure (e.g. unable to access the servers). Otherwise
returns a reference to a hash; each key represents a collection name and the
value is a reference to an array of statuses for individual events.

    my $res = $keen->batch_put( {
        payments => [
            {
                name        => 'John Doe',
                customer_id => 123,
                amount      => 35.00
            },
            {
                name        => 'Peter Smith',
                customer_id => 125,
                amount      => '10.00'
            }
        ],
        purchases => [
            {
                name        => 'John Doe',
                customer_id => 123,
                product_id  => 567,
                quantity    => 1,
                date        => '2015-11-01 15:06:34'
            }
        ]
    });
    unless ($res) {
        warn 'Something went wrong '.$keen->error_message();
    }

=cut

sub batch_put {
    my ( $self, $data ) = @_;
    return $self->_transaction( { }, $data );
}

=head2 get($collection_name, $interval [, $filters ] )

Retrieves a list of events from the collection. C<$collection_name> is 
self-explanatory. C<$interval> is a string, which describes the time period
we are interested in (see L<< https://keen.io/docs/api/#timeframe) >>).
C<$filters> is optional. If provided - should be an arrayref, each element
is an additional condition according to L<< https://keen.io/docs/api/#query-parameters >>.

Returns a reference to an array on hashrefs; each element is a reference
to an actual events. Upon failure returns C<undef>.

    my $data = $keen->select('in_out_log', 'this_7_days',
         [ $keen->filter('name', $KEEN_OP_EQ, 'John Doe') ]);
    print Dumper($data);

=cut

sub select {
    my ( $self, $collection, $timeframe, $filters ) = @_;

    unless ( defined($collection) && defined($timeframe) ) {
        $self->error_message("Must provide collection name and timeframe");
        return undef;
    }

    my $params = {};
    $params->{filters}          = $filters if $filters;
    $params->{event_collection} = $collection;
    $params->{timeframe}        = $timeframe;
    my $x = $self->_transaction( {}, $params );
    unless ( reftype($x) eq 'HASH' && reftype( $x->{result} ) eq 'ARRAY' ) {
        return undef;
    }
    return $x->{result};
}

=head2 filter($field, $operator, $value)

Creates a filter for retrieving events via select() method.

    use WWW::KeenIO qw(:operators);
    my $res = $keen->select('tests', 'this_10_years', [
                  $keen->filter('Author', $KEEN_OP_CONTAINS, 'Andrew'),
                  $keen->filter('Status', $KEEN_OP_EQ, 'resolved')
              ] );

Please refer to Keen API documentation regarding all available operators and
their usage. For convenience constants for most frequently used operators are exported via :operators tag:
$KEEN_OP_EQ, $KEEN_OP_NE, $KEEN_OP_EXISTS, $KEEN_OP_IN, $KEEN_OP_CONTAINS 

=cut

sub filter {
    my ( $self, $field, $operator, $value ) = @_;
    return {
        property_name  => $field,
        operator       => $operator,
        property_value => $value
    };
}

=head2 error_message()

Returns the detailed explanation of the last error. Empty string if
everything went fine.

    my $res = $keen->put('in_out_log', $data);
    unless ($res) {
        warn 'Something went wrong '.$keen->error_message();
    }

=cut

=head1 AUTHOR

Andrew Zhilenko, C<< <perl at putinhuylo.org> >>
(c) Putin Huylo LLC, 2015

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-keenio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-KeenIO>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::KeenIO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-KeenIO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-KeenIO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-KeenIO>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-KeenIO/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Putin Huylo LLC

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1;    # End of WWW::KeenIO
