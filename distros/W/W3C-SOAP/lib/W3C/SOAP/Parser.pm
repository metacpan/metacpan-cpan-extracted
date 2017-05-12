package W3C::SOAP::Parser;

# Created on: 2012-05-27 18:58:29
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = 0.14;

has document => (
    is       => 'rw',
    isa      => 'W3C::SOAP::Document',
);
has template => (
    is        => 'rw',
    isa       => 'Template',
    predicate => 'has_template',
);
has lib => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_lib',
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    my $type = $class;
    $type =~ s/Parser/Document/;

    for my $arg ( keys %$args ) {
        if ( $arg eq 'location' || $arg eq 'string' ) {
            $args->{document} = $type->new($args);
        }
    }

    return $class->$orig($args);
};

1;

__END__

=head1 NAME

W3C::SOAP::Parser - Base module for creating Moose objects from XML documents

=head1 VERSION

This documentation refers to W3C::SOAP::Parser version 0.14.

=head1 SYNOPSIS

   # only used as a base
   extends 'W3C::SOAP::Parser';

=head1 DESCRIPTION

This module parses a WSDL file so that it can produce a client to talk to the
SOAP service.

=head1 SUBROUTINES/METHODS

=head2 EXPORTED SUBROUTINES

=over 4

=item C<load_wsdl ($location)>

Helper method that takes the supplied location and creates the dynamic WSDL
client object.

=back

=head2 CLASS METHODS

=over 4

=item C<new (%args)>

Create the new object C<new> accepts the following arguments:

=over 4

=item location

This is the location of the WSDL file, it may be a local file or a URL

=item module

This is the name of the module to be generated, it is required when writing
the SOAP client to disk, the dynamic client generator creates a semi random
namespace.

=item lib

The library directory where modules should be stored. only required when
calling C<write_modules>

=item template

The Template Toolkit object used for the generation of on disk modules

=item ns_module_map

The mapping of XSD namespaces to perl Modules.

=back

=back

=head2 OBJECT METHODS

=over 4

=item C<<$wsdl->write_modules ()>>

Writes out a module that is a SOAP Client to interface with the contained
WSDL document, also writes any referenced XSDs.

=item C<<$wsdl->dynamic_classes ()>>

Creates a dynamic SOAP client object to talk to the WSDL this object was
created for

=item C<<$wsdl->get_xsd ()>>

Creates the L<W3C::SOAP::XSD::Parser> object that represents the XSDs that
are used by the specified WSDL file.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
