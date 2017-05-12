package W3C::SOAP::WSDL::Document::Message;

# Created on: 2012-05-27 19:25:15
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
use W3C::SOAP::Utils qw/split_ns xml_error cmp_ns/;

extends 'W3C::SOAP::Document::Node';

our $VERSION = 0.14;

has element => (
    is         => 'rw',
    isa        => 'Maybe[W3C::SOAP::XSD::Document::Element]',
    builder    => '_element',
    lazy       => 1,
);
has type => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    builder    => '_type',
    lazy       => 1,
);

sub _element {
    my ($self) = @_;
    my ($part) = $self->document->xpc->findnodes("wsdl:part", $self->node);
    return unless $part;
    my $element = $part->getAttribute('element');
    return unless $element;

    my ($ns, $el_name) = split_ns($element);
    my $nsuri = $self->document->get_nsuri($ns);
    my @schemas = @{ $self->document->schemas };

    for my $schema (@schemas) {
        push @schemas, @{ $schema->imports };
        push @schemas, @{ $schema->includes };

        if ( cmp_ns($schema->target_namespace, $nsuri) ) {
            for my $element (@{ $schema->elements }) {
                return $element if $element->name eq $el_name;
            }
        }
    }

    return;
}

sub _type {
    my ($self) = @_;
    my ($part) = $self->document->xpc->findnodes("wsdl:part", $self->node);
    return unless $part;
    my $type = $part->getAttribute('type');
    return unless $type;

    return $type;
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document::Message - Representation of SOAP messages in a WSDL document

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document::Message version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document::Message;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A C<W3C::SOAP::WSDL::Document::Message> object represents the messages tags
in a WSDL document.

=head1 SUBROUTINES/METHODS

=over 4

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
