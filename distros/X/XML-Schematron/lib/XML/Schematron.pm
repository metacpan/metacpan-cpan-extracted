package XML::Schematron;
use Moose;
use namespace::autoclean;
with 'MooseX::Traits';

use Moose::Util::TypeConstraints;
use XML::Schematron::Test;
use Check::ISA;

use vars qw/$VERSION/;
$VERSION = '1.09';


has '+_trait_namespace' => ( default => 'XML::Schematron' );


has tests => (
    traits      => ['Array'],
    is          =>  'rw',
    isa         =>  'ArrayRef[XML::Schematron::Test]',
    default     =>  sub { [] },
    handles     => {
        _add_test    => 'push',
        all_tests   => 'elements',
    }
);


sub add_test {
    my $self = shift;
    my $ref = shift;

    if ( obj($ref, 'XML::Schematron::Test') ) {
            $self->_add_test( $ref );
    }
    else {
        $self->_add_test( XML::Schematron::Test->new( %{$ref} ) );
    }
}

sub add_tests {
    my $self = shift;
    my @tests = @_;
    foreach my $test (@tests) {
        $self->add_test( $test );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Schematron - Perl implementation of the Schematron.

=head1 SYNOPSIS

  This package should not be used directly. Use one of the subclasses instead.

=head1 DESCRIPTION

This is the superclass for the XML::Schematron::* modules.

Please run perldoc XML::Schematron::XPath, or perldoc XML::Schematron::Sablotron for examples and complete documentation.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2000-2010 Kip Hampton. All rights reserved. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

For information about Schematron, sample schemas, and tutorials to help you write your own schmemas, please visit the
Schematron homepage at: http://www.ascc.net/xml/resource/schematron/

=cut
