package W3C::SOAP::WSDL::Meta::Method;

# Created on: 2012-07-15 19:45:13
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

extends 'Moose::Meta::Method';

our $VERSION = 0.14;

has wsdl_operation => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    predicate => 'has_wsdl_operation',
);
has in_class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_in_class',
);
has in_attribute => (
    is        => 'rw',
    isa       => 'Str',
    default   => 0,
    predicate => 'has_in_attribute',
);
has in_header_class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_in_header_class',
);
has in_header_attribute => (
    is        => 'rw',
    isa       => 'Str',
    default   => 0,
    predicate => 'has_in_header_attribute',
);
has out_class => (
    is        => 'rw',
    isa       => 'Str',
    default   => 1,
    predicate => 'has_out_class',
);
has out_attribute => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_out_attribute',
);
has out_header_class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_out_header_class',
);
has out_header_attribute => (
    is        => 'rw',
    isa       => 'Str',
    default   => 0,
    predicate => 'has_out_header_attribute',
);
has faults => (
    is        => 'rw',
    isa       => 'ArrayRef[HashRef]',
    predicate => 'has_faults',
);
has security => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_security',
);


1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Meta::Method - Moose meta method for WSDL methods

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Meta::Method version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Meta::Method;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Extra meta info for WSDL methods

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
