package W3C::SOAP::WSDL::Document::Policy;

# Created on: 2012-07-18 11:11:32
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

extends 'W3C::SOAP::Document::Node';

our $VERSION = 0.14;

has sec_id => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_sec_id',
);
has policy_type => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_policy_type',
);

sub _sec_id {
    my ($self) = @_;
    my @attributes = $self->node->getAttributes();

    return;
}

sub _policy_type {
    my ($self) = @_;
    my @nodes = $self->document->xpc->findnodes('wsdl:operation', $self->node);

    return;
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document::Policy - Extracted policy information

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document::Policy version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document::Policy;

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

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
