package W3C::SOAP::XSD::Traits;

# Created on: 2012-05-26 23:08:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Moose::Role;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Moose::Util::TypeConstraints;

our $VERSION = 0.14;

Moose::Util::meta_attribute_alias('W3C::SOAP::XSD');

subtype 'xml_node' => as 'XML::LibXML::Node';
subtype 'PositiveInt',
    as 'Int',
    where { $_ >= 0 },
    message { "The number you provided, $_, was not a positive number" };

has xs_perl_module => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_xs_perl_module',
);
has xs_min_occurs => (
    is        => 'rw',
    isa       => 'PositiveInt',
    default   => 0,
    predicate => 'has_xs_min_occurs',
);
has xs_max_occurs => (
    is        => 'rw',
    isa       => 'PositiveInt',
    default   => 1,
    predicate => 'has_xs_max_occurs',
);
has xs_name => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_xs_name',
);
has xs_ns => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_xs_ns',
);
has xs_type => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_xs_type',
);
has xs_choice_group => (
    is        => 'rw',
    isa       => 'PositiveInt',
    predicate => 'has_xs_choice_group',
);
has xs_serialize => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_xs_serialize',
);

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Traits - Specifies the traits of an XSD Moose attribute

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Traits version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Traits;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Defines the Moose attribute trait C<W3C::SOAP::XSD>. This specifies a number
of properties that an attribute can have which helps the processing of
objects representing XSDs.

=over 4

=item C<xs_perl_module>

If the attribute has a type that is a perl module (or a list of a perl module)
This parameter helps in the coercing of XML nodes to the attribute.

=item C<xs_min_occurs>

This represents the minimum number of occurrences of elements in a list.

=item C<xs_max_occurs>

This specifies the maximum number of occurrences of elements in a list.

=item C<xs_name>

This is the name as it appears in the XSD

=item C<xs_type>

This is the type as it appears in the XSD (this will be translated
to perl types/modules specified by the isa property)

=item C<xs_choice_group>

If a complex element has choices this records the grouping of those
choices.

=back

=head1 SUBROUTINES/METHODS

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
