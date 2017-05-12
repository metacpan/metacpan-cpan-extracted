package W3C::SOAP::Header::Security::Username;

# Created on: 2012-05-23 14:38:06
# Create by:  dev
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use DateTime;
use Time::HiRes qw/gettimeofday/;
use English qw/ -no_match_vars /;

extends 'W3C::SOAP::Header::Security';

our $VERSION = 0.14;
my $id = 0;

has username => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has password => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

# Moose 2
#argument to_xml => sub {
sub to_xml {
    my ($self, $xml) = @_;
    my $uname_token = $xml->createElement('wsse:UsernameToken');
    $uname_token->setAttribute('xmlns:wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');
    $uname_token->setAttribute('wsu:Id', 'UsernameToken-' . $id++);

    my $username = $xml->createElement('wsse:Username');
    $username->appendChild( $xml->createTextNode($self->username) );
    $uname_token->appendChild($username);

    my $password = $xml->createElement('wsse:Password');
    $password->appendChild( $xml->createTextNode($self->password) );
    $password->setAttribute('Type' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
    $uname_token->appendChild($password);

    my $nonce_text = '';
    $nonce_text .= ('a'..'z','A'..'Z',0..9)[rand 62] for  1 .. 24;
    my $nonce = $xml->createElement('wsse:Nonce');
    $nonce->appendChild( $xml->createTextNode($nonce_text.'==') );
    $nonce->setAttribute('EncodingType' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary');
    $uname_token->appendChild($nonce);

    my ($seconds, $microseconds) = gettimeofday;
    #TODO is the following nessesary?
    $microseconds =~ s{^(\d\d\d).*}{$1};
    my $date_text = DateTime->now->set_time_zone("Z") . ".${microseconds}Z";
    my $date = $xml->createElement('wsu:Created');
    $date->appendChild( $xml->createTextNode($date_text) );
    $uname_token->appendChild($date);

    # Moose 1
    my $sec = $self->SUPER::to_xml($xml);
    $sec->appendChild($uname_token);

    return $sec;
    # Moose 2
    #return $uname_token;
}

1;

__END__

=head1 NAME

W3C::SOAP::Header::Security::Username - Creates a WS-Security User name object

=head1 VERSION

This documentation refers to W3C::SOAP::Header::Security::Username version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::Header::Security::Username;

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
