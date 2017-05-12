package XML::Toolkit::Builder;
{
  $XML::Toolkit::Builder::VERSION = '0.15';
}
use Moose;
use Moose::Util::TypeConstraints qw(duck_type);
use namespace::autoclean;

has filter => (
    isa      => 'XML::Toolkit::Builder::Filter',
    is       => 'ro',
    required => 1,
    handles  => [qw(render)],
);

has parser => (
    isa => duck_type( [qw(parse_uri parse_file parse_string)] ),
    is => 'ro',
    required => 1,
    handles  => [qw(parse_uri parse_file parse_string)]
);

__PACKAGE__->meta->make_immutable();
1;
__END__


=head1 NAME

XML::Toolkit::Builder - A set of tools for Building XML Classes via XML::SAX Streams

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use XML::Toolkit::Builder;

    my $builder = XML::Toolkit::Builder->new(
        filter => $filter,
        parser => XML::SAX::ParserFactory->new( Handler => $filter ),
    );
    
    $self->builder->parse_file( $file );
    say $builder->render;

=head1 ATTRIBUTES

=over

=item filter - An XML::SAX Filter

The render method is required. This is the class that renders the parsed
events into a set of Moose classes. XML::Toolkit::Builder::Filter documented
elsewhere in this distribution is the default implementation.

=item parser - A Parser Object

The methods parse_uri, parse_file and parse_string are required. This defaults
to a XML::SAX::ParserFactory parser.

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
