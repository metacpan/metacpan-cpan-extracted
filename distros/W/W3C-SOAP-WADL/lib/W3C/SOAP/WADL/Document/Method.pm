package W3C::SOAP::WADL::Document::Method;

# Created on: 2013-04-22 20:57:52
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use XML::Rabbit;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use W3C::SOAP::WADL::Document::Request;
use W3C::SOAP::WADL::Document::Response;

our $VERSION = version->new('0.007');

has_xpath_value name => './@name';
has_xpath_value id   => './@id';

has_xpath_value_list doc => './wadl:doc';
has_xpath_object request => (
    './wadl:request' => 'W3C::SOAP::WADL::Document::Request',
);
has_xpath_object_list response => (
    './wadl:response' => 'W3C::SOAP::WADL::Document::Response',
    predicate => 'has_response',
);

finalize_class();

1;

__END__

=head1 NAME

W3C::SOAP::WADL::Document::Method - Container for WADL method elements

=head1 VERSION

This documentation refers to W3C::SOAP::WADL::Document::Method version 0.007.

=head1 SYNOPSIS

   use W3C::SOAP::WADL::Document::Method;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

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

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
