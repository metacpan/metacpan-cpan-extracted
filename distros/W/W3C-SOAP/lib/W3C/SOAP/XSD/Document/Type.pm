package W3C::SOAP::XSD::Document::Type;

# Created on: 2012-06-06 14:00:31
# Create by:  dev
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

extends 'W3C::SOAP::XSD::Document::Node';

our $VERSION = 0.14;

has documentation => (
    is     => 'rw',
    isa    => 'Str',
    builder => '_documentation',
    lazy => 1,
);

sub _documentation {
    my ($self) = @_;
    my ($documentation) = $self->document->xpc->findnodes('xsd:annotation/xsd:documentation', $self->node);

    return '' unless $documentation;

    $documentation = $documentation->textContent;
    $documentation =~ s/^\s+|\s+$//g;

    return $documentation;
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document::Type - Represents type elements of XSD documents

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document::Type version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document::Type;

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

Please report problems to Ivan Wills - (ivan.wills@gmail.com)

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
