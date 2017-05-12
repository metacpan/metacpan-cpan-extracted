package XML::Toolkit::Generator;
{
  $XML::Toolkit::Generator::VERSION = '0.15';
}
use Moose;
use XML::SAX::Writer;
use namespace::autoclean;

has output => (
    isa        => 'ArrayRef',
    is         => 'ro',
    required   => 1,
    auto_deref => 1,
);

has engine => (
    does     => 'XML::Toolkit::Generator::Interface',
    is       => 'ro',
    required => 1,
    handles  => { render_object => 'parse' },
);

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::Generator - A set of tools for converting Moose Objects into XML

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use XML::Toolkit::Generator;
    my $generator =     XML::Toolkit::Generator->new(engine => $engine);
    $generator->render_object( $object );
    say for $generator->output;

=head1 ATTRIBUTES

=over

=item output - Output Buffer

An ArrayRef that contains all of the output.

=item engine - An XML::Toolkit::Generator Engine

This must do the XML::Toolkit::Generator::Interface. This is the class that
introspects Moose Objects and converts them into a SAX Stream. It defaults to
XML::Toolkit::Generator::Default.

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
