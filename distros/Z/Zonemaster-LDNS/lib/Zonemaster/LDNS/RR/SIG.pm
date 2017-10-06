package Zonemaster::LDNS::RR::SIG;

use parent 'Zonemaster::LDNS::RR';

1;

=head1 NAME

Zonemaster::LDNS::RR::SIG - Type SIG record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item typecovered()

Returns a string with the name of the RR type this signature covers.

=item algorithm()

Returns the algorithm number.

=item labels()

Returns the number of labels that was used to calculate the signature.

=item origttl()

Returns the original TTL value.

=item expiration()

Returns the expiration time, as a time_t.

=item inception()

Returns the inception time, as a time_t.

=item keytag()

Returns the keytag.

=item signer()

Returns the signer name.

=item signature()

Returns the cryptographic signture in binary form.

=back
