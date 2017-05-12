package URL::Signature::Path;

use strict;
use warnings;
use parent 'URL::Signature';
use Params::Util qw( _NONNEGINT );

our $VERSION = '0.03';


sub new {
    my ($class, %attrs) = @_;
    return $class->SUPER::new( %attrs, format => 'path' );
}

sub BUILD {
    my $self = shift;
    $self->{'as'} = 1 unless exists $self->{'as'};
    Carp::croak( q[in 'path' format, 'as' needs to be a non-negative integer])
        unless defined _NONNEGINT($self->{'as'});

    return;
}


sub extract {
    my ($self, $uri) = @_;
    my @segments = $uri->path_segments;
    return if scalar @segments <= $self->{'as'};

    my $code = splice @segments, $self->{'as'}, 1;
    $uri->path_segments( @segments );

    return ($code, $uri);
}


sub append {
    my ($self, $uri, $code) = @_;
    my @segments = $uri->path_segments;
    return if scalar @segments <= $self->{'as'};
    splice @segments, $self->{'as'}, 0, $code;
    $uri->path_segments(@segments);
    return $uri;
}


42;
__END__

=head1 NAME

URL::Signature::Path - Sign your URL's path

=head1 SYNOPSIS

stand-alone usage:

  use URL::Signature::Path;
  my $signer = URL::Signature::Path->new( key => 'my-secret-key' );

  my $url = $signer->sign('/some/path');


or, from within URL::Signature:

  use URL::Signature;
  my $signer = URL::Signature->new(
    key    => 'my-secret-key',
    format => 'path',
    as     => 1,
  );

=head1 DESCRIPTION

This module provides path signature for URLs. It is a subset of
L<URL::Signature> but can also be used as a stand-alone module if you
don't care as much about signature flexibility.

=head1 METHODS

=head2 new( %attributes )

Instantiates a new object. You can set the same attributes as URL::Signatures,
but it will force 'format' to be 'path'. The following extra parameters are
also available:

=over 4

=item * B<as> - This option specifies the segment's position in which to
inject/extract the authentication code. This option is 0-based, and
defaults to B<1>, meaning the second segment of the provided path should
contain the signature.

So, when you say something like:

   my $signer = URL::Signature::Path->new( key => 'my-secret-key' );
   
   $signer->validate( 'www.example.com/1234/foo/bar' );

it will split the URL into ('www.example.com', '1234', 'foo', 'bar'),
and, since 'C<as>' is set to 1, it will assume 'C<1234>' is the signature
to be extracted.

Similarly, if you say:

   my $url = $signer->sign( 'www.example.com/foo/bar' );

then it will place the signature on the second segment of the provided path,
so C<$url> will stringify to 'C<www.example.com/CODE/foo/bar>', where
C<CODE> is the calculated signature for that path.

Similarly, if you omit the domain (and/or the root of your application)
and instead provide just the relative path, it should also append the
signature properly:

   my $url = $signer->sign( '/foo/bar' );

And 'C<$url>' will stringify to 'C</CODE/foo/bar>'.

Note, however, that for this to work you B<must> provide the path starting with
a '/', otherwise it will take the first element of your path to be segment 0:

   $url = $signer->sign( 'foo/bar' );

The code above will create your C<$uri> object as 'C<foo/CODE/bar>', which is
probably NOT what you want.

=back

=head2 sign( $url_string )

I<< (Inherited from L<URL::Signature>) >>

Receives a string containing the URL to be signed. Returns a
L<URI> object with the original URL modified to contain the
authentication code.

=head2 validate( $url_string )

I<< (Inherited from L<URL::Signature>) >>

Receives a string containing the URL to be validated. Returns
false if the URL's auth code is not a match, otherwise returns
an L<URI> object containing the original URL minus the
authentication code.

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

=item * a new URI object just like the original minus the signature

=back

In C<URL::Signature::Path>, it will assume the original uri contains
the signature in the position specified by the 'C<as>' parameter set
in the constructor. The returned uri will be the same except the
signature itself will be removed. For instance:

   my $path = URI->new( 'example.com/12345/some/path' );
   my ($code, $uri) = $obj->extract( $path );

   print $code;  # '12345'
   print "$uri"; # 'example.com/some/path'


=head3 append

    my $new_uri = $obj->append( $original_uri, $code );

Receives a L<URI> object and the authentication code to be inserted.
Returns a new URI object with the auth code properly appended, according
to the position specified by the 'C<as>' parameter set in the constructor.
For example:

    my $original_uri = URI->new( 'example.com/some/path' );
    my $signed_uri   = $obj->append( $original_uri, '1234' );

    print "$signed_uri";  # 'example.com/1234/some/path'


=head1 SEE ALSO

L<URL::Signature>

=cut
