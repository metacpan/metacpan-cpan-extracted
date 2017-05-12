package W3C::SOAP::WADL::Document;

# Created on: 2013-04-21 10:44:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use XML::Rabbit::Root;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use W3C::SOAP::WADL::Document::Resources;

our $VERSION = version->new('0.007');

add_xpath_namespace wadl => 'http://wadl.dev.java.net/2009/02';
add_xpath_namespace json => 'http://rest.domain.gdl.optus.com.au/rest/3/common-json';

has_xpath_value target_namespace => './@targetNamespace';
has_xpath_value_list doc => './doc';

has_xpath_object grammars => (
    '//wadl:grammars' => 'W3C::SOAP::WADL::Document::Grammars',
);
has_xpath_object_list resources => (
    '//wadl:resources' => 'W3C::SOAP::WADL::Document::Resources',
);
has_xpath_object_list resource_type => (
    '//wadl:resource_type' => 'W3C::SOAP::WADL::Document::ResourceType',
);
has_xpath_object_list method => (
    '//wadl:method' => 'W3C::SOAP::WADL::Document::Method',
);
has_xpath_object_list representation => (
    '//wadl:representation' => 'W3C::SOAP::WADL::Document::Representation',
);
has_xpath_object_list param => (
    '//wadl:param' => 'W3C::SOAP::WADL::Document::Param',
);
has_xpath_object_list schemas => (
    '//wadl:grammars/wadl:include' => 'W3C::SOAP::WADL::XSD',
);

has module => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_module',
);
has module_base => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_module_base',
);
has file => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_file',
);
has ns_module_map => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    required  => 1,
    predicate => 'has_ns_module_map',
    default   => sub{{}},
);

finalize_class();

1;

__END__

=head1 NAME

W3C::SOAP::WADL::Document - The representation of the WADL document

=head1 VERSION

This documentation refers to W3C::SOAP::WADL::Document version 0.007.

=head1 SYNOPSIS

   use W3C::SOAP::WADL::Document;

   # create a document
   my $doc = W3C::SOAP::WADL::Document->new( file => 'file_or_url', );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item target_namespace

=item doc

=item grammars

=item resources

=item resource_type

=item method

=item representation

=item param

=item module

=item module_base

=item file

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
