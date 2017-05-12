package WebService::Buxfer::Response;

use Moose;
use JSON::XS ();
use Carp qw(carp);

has 'raw_response' => (
    is      => 'ro',
    isa     => 'Object',
    handles => [ qw( status_code status_message is_success is_error ) ]
);

has 'content' => ( is => 'rw', isa => 'HashRef', lazy_build => 1 );

sub BUILDARGS {
    my ( $self, $res ) = @_;
    return { raw_response => $res };
}

sub _build_content {
    my $self = shift;
    my $content = $self->raw_response->content;
    return {} unless $content;

    my $obj;
    return JSON::XS::decode_json( $content );
}

sub ok {
    my $self = shift;
    my $status = $self->buxfer_status;
    return defined $status && $status !~ /^ERROR:/ && !$self->raw_response->is_error;
}

sub buxfer_status {
    return shift->content->{response}->{status};
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WebService::Buxfer::Response

=head1 SYNOPSIS

    my $response = WebService::Buxfer::Response->new(
        $lwp_ua->request(
            GET 'https://www.buxfer.com/transactions.json?token=XXX'
        )
        );

    exit 1 unless $response->ok;

    foreach ( $response->content->{response}->{transactions} ) {
        print "Result: ".Data::Dumper::Dumper($_)."\n";
    }

=head1 DESCRIPTION

This is a simple class to encapsulate responses from the Buxfer webservice.

=head1 ACCESSORS

=over 4

=item * raw_response - the raw L<HTTP::Response> object.

=item * content - a hashref of deserialized JSON data from the response.

=back

=head1 METHODS

=head2 new( $response )

Given an L<HTTP::Response> object, it will parse the returned data as
required.

=head2 buxfer_status( )

Returns the status string from Buxfer.

=head2 ok( )

Parses C<buxfer_status()> and checks the HTTP::Response status to determine
if the request was successful.

=head1 TODO

Move some of the logic out of WebService::Buxfer into here.

Add a pager for flipping through transactions based on 25 results per
page and numTransactions in the response.

=head1 ACKNOWLEDGEMENTS

Portions of this package borrowed/adapted from the
L<WebService::Solr::Response> code.

Thanks to Brian Cassidy and Kirk Beers for that package.

=head1 AUTHORS

Nathaniel Heinrichs E<lt>nheinric@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2009 Nathaniel Heinrichs.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut

