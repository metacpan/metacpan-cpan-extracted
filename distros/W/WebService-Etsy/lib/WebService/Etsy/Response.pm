package WebService::Etsy::Response;

use strict;
use warnings;
use Carp;

use base qw( Class::Accessor );
__PACKAGE__->mk_accessors( qw( results params count type ) );
our( $AUTOLOAD );

=head1 NAME

WebService::Etsy::Response - Returned data from the Etsy API.

=head1 SYNOPSIS

    my $resp = $api->getFeaturedSellers( detail_level => 'medium' );
    # call methods on the object
    print $resp->count . " featured sellers\n";
    # use the object like an arrayref of Resource objects
    for my $shop ( @$resp ) {
        print $shop->shop_name, "\n";
    }

=head1 DESCRIPTION

This class encapsulates the response from the API, as described at L<http://developer.etsy.com/docs#api_response_structure>.

=head2 Arrayification

For convenience, the Response object behaves like an arrayref of Resource objects when used as such.

=head2 Stringification

When used in a scalar context, the Response object will return a comma-separated list of stringified Resource objects. This is noteworthy for the case of

    print $api->getServerEpoch() . "\n";

which will print the epoch directly, without having to do something like

    print $api->getServerEpoch()->results->[ 0 ]->value . "\n";

=head1 METHODS

=over 4

=item C<results()>

An arrayref of L<WebService::Etsy::Resource> objects. Using the Response object as an arrayref accesses this results arrayref.

=item C<params()>

A hashref of the parameters supplied to the method call.

=item C<count()>

The number of results found (not necessarily the number returned).

=item C<type()>

The Resource objects' type.

=back

=head1 AUTOLOADED METHODS

As a convenience, the Response object will accept method calls the belong to its Resource objects. The method calls will be executed on the first object in the results arrayref. This allows you to use the Response object just like a Resource object, which is useful when a method call (e.g. C<getUserDetails>) is expected to return one and only one result.

Note that C<WebService::Etsy::Method> objects include methods that collide with C<WebService::Etsy::Response> object methods, in which case you'll need to use the longer form of C<$resp-E<gt>[ 0 ]-E<gt>method()> (although this shouldn't matter too much since there aren't currently any API methods that return only one method result).

These methods are generated using C<AUTOLOAD>, and so won't be picked up by C<can()> etc.

=cut

use overload
    '""' => "stringify",
    '@{}' => "array",
    fallback => 1,
;    

sub stringify {
    return join ",", @{ $_[ 0 ]->results };
}

sub array {
    return $_[ 0 ]->results;
}

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ /::([^:]*?)$/;
    my $method = $1;
    if ( $self->results->[ 0 ]->can( $method ) ) {
        return $self->results->[ 0 ]->$method( @_ );
    } else {
        croak "No such method: $method";
    }
}

sub DESTROY {
}

=head1 SEE ALSO

L<http://developer.etsy.com/docs#api_response_structure>, L<WebService::Etsy::Resource>.

=head1 AUTHOR

Ian Malpass (ian-cpan@indecorous.com)


=head1 COPYRIGHT

Copyright 2009, Ian Malpass

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
