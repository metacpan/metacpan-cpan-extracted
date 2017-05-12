package W3C::SOAP::Header::Security;

# Created on: 2012-05-23 14:35:51
# Create by:  dev
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;


our $VERSION = 0.14;

sub to_xml {
    my ($self, $xml) = @_;

    my $sec = $xml->createElement('wsse:Security');
    $sec->setAttribute('xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
    $sec->setAttribute('soapenv:mustUnderstand' => 1);

    # Moose 2 syntax
    #my $child = inner();
    #$sec->appendChild($child) if $child;

    return $sec;
}

1;

__END__

=head1 NAME

W3C::SOAP::Header::Security - Creates a SOAP Header WS-Security object

=head1 VERSION

This documentation refers to W3C::SOAP::Header::Security version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::Header::Security;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION


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
