package W3C::SOAP::WADL::Meta::Method;

# Created on: 2012-07-15 19:45:13
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

extends 'Moose::Meta::Method';

our $VERSION = version->new('0.007');

has name => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_name',
);
has path => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    predicate => 'has_path',
);
has method => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    predicate => 'has_method',
);
has request => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_request',
);
has response => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    predicate => 'has_response',
);


1;

__END__

=head1 NAME

W3C::SOAP::WADL::Meta::Method - Parameters needed for WADL operations.

=head1 VERSION

This documentation refers to W3C::SOAP::WADL::Meta::Method version 0.007.

=head1 SYNOPSIS

   use W3C::SOAP::WADL::Utils;

   # create an operation in the current class
   operation name => (
       path     => 'rel/path',
       method   => 'GET',
       request  => 'Some::Thing::nameGET',
       response => {
           200 => 'Some::Ting::pingGet::200',
           400 => 'Some::Ting::pingGet::400',
       },
   );

=head1 DESCRIPTION

Provides the description of extra parameters for operations, use L<W3C::SOAP::WADL::Utils>'s
operation function to access this functionality.

=head1 ATTRIBUTES

=over 4

=item name

The name of the operation

=item path

The path of the operation (relative to the WADL's base)

=item method

The type of HTTP request GET, POST, PUT, DELETE etc

=item request

The request class name

=item response

A map of response HTTP status codes to classes

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
