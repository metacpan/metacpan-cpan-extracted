package URL::Signature::Query;

use strict;
use warnings;
use parent 'URL::Signature';
use Params::Util qw( _STRING );

our $VERSION = '0.03';

sub new {
    my ($class, %attrs) = @_;
    return $class->SUPER::new( %attrs, format => 'query' );
}


sub BUILD {
    my $self = shift;
    $self->{'as'} = 'k' unless exists $self->{'as'};
    Carp::croak(q[in 'query' format, 'as' needs to be a valid string])
        unless defined _STRING($self->{'as'});
    return;
}


sub extract {
    my ($self, $uri) = @_;
    my $code = $uri->query_param_delete( $self->{as} );
    return ($code, $uri);
}


sub append {
    my ($self, $uri, $code) = @_;
    my $varname = $self->{as};
    my $code_check = $uri->query_param_delete($varname);
    Carp::croak("variable '$varname' (reserved for auth code) found in path")
        if $code_check;

    $uri->query_param_append( $varname => $code );
    return $uri;
}


42;
__END__

=head1 NAME

URL::Signature::Query - Sign your URL with a query parameter

=head1 SYNOPSIS

  use URL::Signature::Query;
  my $signer = URL::Signature::Query->new( key => 'my-secret-key' );

  my $url = $signer->sign('/some/path');


or, from within URL::Signature:

  use URL::Signature;
  my $signer = URL::Signature->new(
    key    => 'my-secret-key',
    format => 'query',
    as     => 'k',
  );


=head1 DESCRIPTION

This module provides query signature for URLs. It is a subset of
L<URL::Signature> but can also be used as a stand-alone module if you
don't care as much about signature flexibility.

=head1 METHODS

=head2 new( %attributes )

Instantiates a new object. You can set the same attributes as URL::Signatures,
but it will force 'format' to be 'query'. The following extra parameters are
also available:

=over 4

=item * B<as> - This option specifies the variable (query parameter) name
in which to inject/extract the authentication code. This option
defaults to B<k>, so when you say something like:

   my $signer = URL::Signature::Query->new( key => 'my-secret-key' );
   
   $signer->validate( 'www.example.com/foo/bar?k=1234' );

it will look for the available query parameters and see if the one labelled
'C<k>' has the appropriate key for the remaining URL.

Similarly, if you say:

    my $url = $signer->sign( 'www.example.com/foo/bar' );

it will place the signature as the 'C<k>' query parameter, so C<$url> will
stringify to 'C<www.example.com/foo/bar?k=CODE>', where C<CODE> is the
calculated signature for that path.

Note that 'C<k>' is just the default, it will use whichever name you set
in the 'C<as>' attribute:

   my $signer = URL::Signature::Query->new(
         key => 'my-secret-key',
         as  => 'Signature',
   );

   my $url = $signer->sign( '/foo/bar?someKey=someValue&answer=42' );

   print "$url";
   # => /foo/bar?answer=42&someKey=someValue&Signature=68bPh9H8gsqT6I5TM4J3E7xqrfw

Note that the order of the query parameters might change. This won't matter to
the signature itself, and it shouldn't matter to the URL as well.

=back


=head2 sign( $url_string )

I<< (Inherited from L<URL::Signature>) >>

Receives a string containing the URL to be signed. Returns a
L<URI> object with the original URL modified to contain the
authentication code as a query parameter.

=head2 validate( $url_string )

I<< (Inherited from L<URL::Signature>) >>

Receives a string containing the URL to be validated. Returns
false if the URL's auth code is not a match, otherwise returns
an L<URI> object containing the original URL minus the
authentication code query parameter.

=head2 Convenience Methods

Aside from C<sign()> and C<validate()>, there are a few other
methods you may find useful:

=head3 code_for_uri( $uri_object )

Receives a L<URI> object and returns a string containing the
authentication code necessary for that object.

=head3 extract( $uri_object )

    my ($code, $new_uri) = $obj->extract( $original_uri );

Receives a L<URI> object and returns two elements:

=over 4

=item * the extracted signature from the given URI

=item * a new URI object just like the original minus
the signature query parameter

=back

In C<URL::Signature::Query>, it will assume the original uri contains
the signature in the query parameter label specified by the 'C<as>'
parameter set in the constructor. The returned uri will be the same
except the signature itself will be removed. For instance:

   my $path = URI->new( 'example.com/some/path?foo=bar&k=12345' );
   my ($code, $uri) = $obj->extract( $path );

   print $code;  # '12345'
   print "$uri"; # 'example.com/some/path?foo=bar'


=head3 append

    my $new_uri = $obj->append( $original_uri, $code );

Receives a L<URI> object and the authentication code to be inserted.
Returns a new URI object with the auth code properly appended, according
to the query parameter name specified by the 'C<as>' parameter set in the
constructor. For example:

    my $original_uri = URI->new( 'example.com/some/path?foo=bar' );
    my $signed_uri   = $obj->append( $original_uri, '1234' );

    print "$signed_uri";  # 'example.com/some/path?foo=bar&k=12345'


=head1 SEE ALSO

L<URL::Signature>

=cut
