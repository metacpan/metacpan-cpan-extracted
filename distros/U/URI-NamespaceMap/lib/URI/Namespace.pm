package URI::Namespace;
use Moo 1.006000;
use URI;
use IRI 0.003;
use Scalar::Util qw(blessed);
use Types::Namespace 0.004 qw( Iri );
use namespace::autoclean;

our $VERSION = '1.10';

=head1 NAME

URI::Namespace - A namespace URI/IRI class with autoload methods

=head1 SYNOPSIS

  use URI::Namespace;
  my $foaf = URI::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
  print $foaf->as_string;
  print $foaf->name;

=head1 DESCRIPTION

This module provides an object with a URI/IRI attribute, typically used
prefix-namespace pairs, typically used in XML, RDF serializations,
etc. The local part can be used as a method, these are autoloaded.

=head1 METHODS

=over

=item C<< new ( $string | URI | IRI ) >>

This is the constructor. You may pass a string with a URI or a URI object.

=item C<< uri ( [ $local_part ] ) >>

Returns a L<URI> object with the namespace IRI. Optionally, the method
can take a local part as argument, in which case, it will return the
namespace URI with the local part appended.

=item C<< iri ( [ $local_part ] ) >>

Returns a L<IRI> object with the namespace IRI. Optionally, the method
can take a local part as argument, in which case, it will return the
namespace IRI with the local part appended.

=item C<< local_part ( $uri ) >>

Returns the local part string if the given argument URI (which may be
a string, L<URI> or L<IRI> object) matches the namespace URI, or
C<undef> if not.


=back

The following methods from L<URI> can be used on an URI::Namespace object: C<as_string>, C<as_iri>, C<canonical>, C<eq>, C<abs>, C<rel>.

One important usage for this module is to enable you to create L<URI>s for full URIs, e.g.:

  print $foaf->Person->as_string;

will return

  http://xmlns.com/foaf/0.1/Person

=head1 FURTHER DETAILS

See L<URI::NamespaceMap> for further details about authors, license, etc.

=cut

around BUILDARGS => sub {
	my ($next, $self, @parameters) = @_;
	return $self->$next(@_) if ((@parameters > 1) || (ref($parameters[0]) eq 'HASH'));
	return { _uri => $parameters[0] };
};

has _uri => (
             is => "ro",
             isa => Iri,
             coerce => 1,
             required => 1,
             handles => {
                         'as_string' => 'as_string',
                         'as_iri' => 'as_string',
                        }
            );

sub iri {
	my ($self, $name) = @_;
	if (defined($name)) {
		my $str = $self->_uri->as_string;
		# XSD is given without hash in XML world, but hash should be added anyway (see issue #14)
		$str .= '#' if ($str eq 'http://www.w3.org/2001/XMLSchema');
		return IRI->new($str . "$name");
	} else {
		return $self->_uri;
	}
}

sub uri {
	my ($self, $name) = @_;
	my $iri = $self->_uri->as_string;
	if (defined($name)) {
		$iri .= '#' if ($iri eq 'http://www.w3.org/2001/XMLSchema');
		return URI->new($iri . "$name");
	} else {
		return URI->new($iri);
	}
}

sub local_part {
  my ($self, $fulluri) = @_;
  my $local_part = undef;
  if (blessed($fulluri) && $fulluri->isa('IRI')) {
	 $fulluri = $fulluri->as_string;
  }
  my $iri = $self->_uri->as_string;
  if ($fulluri =~ m/^$iri(.+)/) {
	 $local_part = $1;
  } else {
	 # TODO: throw error?
  }
  return $local_part;
}


for my $method (qw/ abs rel eq canonical /) {
	eval qq[ sub $method { shift->uri->${method}(\@_) } ];
}

our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	my ($name) = $AUTOLOAD =~ /::(\w+)$/;
	return $self->uri($name);
}

1;
__END__
