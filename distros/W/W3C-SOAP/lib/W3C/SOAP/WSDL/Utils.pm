package W3C::SOAP::WSDL::Utils;

# Created on: 2013-06-27 17:13:29
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use W3C::SOAP::WSDL::Meta::Method;

Moose::Exporter->setup_import_methods(
    with_meta => ['operation'],
);

our $VERSION = 0.14;

sub operation {
    my ( $meta, $name, %options ) = @_;
    $meta->add_method(
        $name,
        W3C::SOAP::WSDL::Meta::Method->wrap(
            body            => sub { shift->_request($name => @_) },
            package_name    => $meta->name,
            name            => $name,
            %options,
        )
    );
    return;
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Utils - WSDL related utilities

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Utils version 0.14


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Utils;

   # In a WSDL package to generate an operation method:
   operation wsdl_op => (
       wsdl_operation => 'WsdlOp',
       in_class       +> 'MyApp::Some::XSD',
       in_attribute   +> 'wsdl_op_request',
       out_class      +> 'MyApp::Some::XSD',
       out_attribute  +> 'wsdl_op_response',
   );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 MOOSE HELPERS

=over 4

=item C<operation ($name, %optisns)>

Generates a SOAP operation method with the name C<$name>

The options are:

=over 4

=item C<wsdl_operation>

The name of the operation from the WSDL

=item C<in_class>

The name of the XSD generated module that the inputs should be made against

=item C<in_attribute>

The particular element form the C<in_class> XSD

=item C<out_class>

The name of the XSD generated module that the outputs should be passed to

=item C<out_attribute>

The particular element form the C<out_class> XSD that contains the results.

=back

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
