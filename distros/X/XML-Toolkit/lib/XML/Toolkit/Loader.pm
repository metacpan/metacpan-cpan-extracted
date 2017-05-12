package XML::Toolkit::Loader;
{
  $XML::Toolkit::Loader::VERSION = '0.15';
}
use Moose;
use namespace::autoclean;

has filter => (
    isa      => 'XML::Toolkit::Loader::Filter',
    is       => 'ro',
    required => 1,
    handles  => [qw(root_object)],
);

has generator => (
    isa      => 'XML::Toolkit::Generator',
    is       => 'ro',
    required => 1,
    handles  => [qw(render_object output)],
);

has parser => (
    is       => 'ro',
    required => 1,
    handles  => [qw(parse_uri parse_file parse_string)]
);

before [qw(parse_uri parse_file parse_string)] =>
  sub { shift->filter->reset_state };

sub render {
    my ($self) = @_;
    $self->render_object( $self->root_object );
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::Loader - A set of tools for Loading XML into Moose Objects

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use XML::Toolkit::Loader;
    my $loader = XML::Toolkit::Loader->new( namespace => 'MyApp' );
    $loader->parse_file( $file );
    print join '', @{ $loader->render };

=head1 ATTRIBUTES

=over

=item filter - An XML::SAX Filter

The render method is required. This is the class that renders the parsed
events into a set of Moose Objects. XML::Toolkit::Loader::Filter documented
elsewhere in this distribution is the default implementation.

=item generator - An XML::Toolkit::Generator

The render method is required. This is the class that renders a set of Moose
objects parsed by the Filter into XML again. XML::Toolkit::Generator
documented elsewhere in this distribution is the default implementation.

=item parser - A Parser Object

The methods parse_uri, parse_file and parse_string are required. This defaults
to a XML::SAX::ParserFactory parser.

=back 

=head1 METHODS

=over 

=item render()

Render the current root_object via the XML::Toolkit::Generator's render_object method

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-toolkit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Chris Prather  C<< <chris@prather.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Prather C<< <chris@prather.org> >>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
