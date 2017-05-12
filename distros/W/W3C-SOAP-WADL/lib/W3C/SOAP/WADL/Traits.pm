package W3C::SOAP::WADL::Traits;

# Created on: 2013-04-21 10:52:17
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose::Role;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Moose::Util::TypeConstraints;

our $VERSION = version->new('0.007');

Moose::Util::meta_attribute_alias('W3C::SOAP::WADL');

has style => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_style',
);
has real_name => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_real_name',
);

1;

__END__

=head1 NAME

W3C::SOAP::WADL::Traits - Defines the extra attribute parameters for WADL
parameters.

=head1 VERSION

This documentation refers to W3C::SOAP::WADL::Traits version 0.007.

=head1 SYNOPSIS

   use W3C::SOAP::WADL::Traits;

   # create a wadl param attribute
   has my_header => (
       is        => 'rw',
       isa       => 'Str',
       traits    => [qw{ W3C::SOAP::WADL }],
       style     => 'header',
       real_name => 'My-Header',
   );

   # create a wadl param attribute
   has my_query => (
       is        => 'rw',
       isa       => 'Str',
       traits    => [qw{ W3C::SOAP::WADL }],
       style     => 'query',
       real_name => 'My-Query',
   );

=head1 DESCRIPTION

Adds the extra information that L<W3C""SOAP::WADL::Client> needs for sending
a request.

=head1 ATTRIBUTES

=over 4

=item style

The WADL parameter is either header or query parameter.

=item real_name

The value of the parameter as passed to or from the service. The may be different
as parameters my not match Perl's syntax

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

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
