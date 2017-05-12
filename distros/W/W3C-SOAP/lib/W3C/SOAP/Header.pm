package W3C::SOAP::Header;

# Created on: 2012-05-23 14:32:39
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


our $VERSION = 0.14;

has security => (
    is        => 'rw',
    isa       => 'W3C::SOAP::Header::Security',
    predicate => 'has_security',
);

has message => (
   is => 'rw',
   isa   => 'W3C::SOAP::XSD',
   predicate   => 'has_message',
);

sub to_xml {
    my ($self, $xml) = @_;

    my $header = $xml->createElement('soapenv:Header');

    if ($self->has_security) {
        $header->appendChild($self->security->to_xml($xml));
    }
    if ($self->has_message) {
        for my $node ( $self->message->to_xml($xml) ) {
            $header->appendChild($node);
       }
    }

    return $header;
}

1;

__END__

=head1 NAME

W3C::SOAP::Header - Object to create SOAP headers

=head1 VERSION

This documentation refers to W3C::SOAP::Header version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::Header;

   # create the XML
   my $xml = $header->to_xml();

=head1 DESCRIPTION

This object allows the construction SOAP headers.

=head1 SUBROUTINES/METHODS

=over 4

=item C<to_xml ($xml)>

Coverts this object to XML

=back

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
