package URI::Platonic;

use Moose;
use MooseX::Types::URI qw(Uri);
use overload '""' => \&as_string, fallback => 1;

has 'uri' => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

# no Moose handles ?
{
    my @handles = qw(
        authority opaque userinfo host_port
        scheme host port path query fragment
        path_query path_segments
        query_form query_keywords
        as_string
    );

    for my $method (@handles) {
        __PACKAGE__->meta->add_method($method, sub {
            my $self = shift;
            $self->uri->$method(@_);
        });
    }
}

has 'extension' => (
    is  => 'rw',
    isa => 'Str',
);

no Moose;

our $VERSION = '0.03';

sub BUILD {
    my $self = shift;

    my $path = $self->uri->path;
    if ($path =~ m![^/]+\.([^/\.]+)$!) {
        $self->extension($1);
        $path =~ s/\.$1$//;
        $self->uri->path($path);
    }
}

sub clone {
    my $self = shift;
    my $class = ref $self || $self;
    return $class->new(uri => $self->distinct->clone);
}

sub canonical {
    my $self = shift;
    my $class = ref $self || $self;
    return $class->new(uri => $self->distinct->canonical);
}

sub platonic {
    my $self = shift;
    return $self->uri->clone;
}

sub distinct {
    my $self = shift;

    my $uri = $self->uri->clone;
    if ($self->extension) {
        $uri->path(join '.', $uri->path, $self->extension);
    }

    return $uri;
}

1;

__PACKAGE__->meta->make_immutable;

=head1 NAME

URI::Platonic - Platonic and Distinct URIs

=head1 SYNOPSIS

  use URI::Platonic;
  
  my $uri = URI::Platonic->new(uri => "http://example.com/path/to/resource.html");
     $uri = URI::Platonic->new(uri => URI->new("http://example.com/foo.xml"));
  
  print $uri->path;      # "/path/to/resource"
  print $uri->extension; # "html"
  print $uri->platonic;  # "http://example.com/path/to/resource"
  print $uri->distinct;  # "http://example.com/path/to/resource.html"
  
  $uri->extension('xml');
  print $uri->distinct;  # "http://example.com/path/to/resource.xml"
  
  $uri->path('/path/to/another');
  print $uri->platonic;  # "http://example.com/path/to/another"
  print $uri->distinct;  # "http://example.com/path/to/another.xml"

=head1 DESCRIPTION

URI::Platonic is a L<URI>-like module for "Platonic" and "Distinct" URIs,
described in RESTful Web Services.

=head1 METHODS

=head2 new(uri => $uri)

Constructs a new L<URI::Platonic> object.

=head2 extension([ $extension ])

Gets/Sets a extension part of the distinct URI.

=head2 platonic()

Returns a platonic L<URI>.

=head2 distinct()

Returns a distinct L<URI>.

=head2 clone()

Returns a copy of the L<URI::Platonic> object.

=head2 canonical()

Returns a normalized version of the L<URI::Platonic> object.

=head2 as_string()

Returns a plain string of the platonic URI.

=head1 PRIVATES

=head2 BUILD

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<URI>

=cut
