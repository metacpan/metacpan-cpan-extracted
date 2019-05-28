package Zonemaster::LDNS::Packet;

use strict;
use warnings;

use Zonemaster::LDNS;

use MIME::Base64;

sub TO_JSON {
    my ( $self ) = @_;

    return {
        'Zonemaster::LDNS::Packet' => {
            data       => encode_base64( $self->wireformat, '' ),
            answerfrom => $self->answerfrom,
            timestamp  => $self->timestamp,
            querytime  => $self->querytime,
        }
    };
}

sub data {
    my ( $self ) = @_;

    return $self->wireformat;
}

1;

=head1 NAME

Zonemaster::LDNS::Packet - objects representing DNS packets

=head1 SYNOPSIS

    my $p = $resolver->query('www.iis.se');
    foreach my $rr ($p->answer) {
        say $rr->string if $rr->type eq 'A';
    }

=head1 CLASS METHODS

=over

=item new($name, $type, $class)

Create a new packet, holding nothing by a query record for the provided triplet. C<$type> and C<$class> are optional, and default to A and IN
respectively.

=item new_from_wireformat($data)

Creates a new L<Zonemaster::LDNS::Packet> object from the given wireformat data, if possible. Throws an exception if not.

=back

=head1 INSTANCE METHODS

=over

=item rcode([$string])

Returns the packet RCODE. If given an argument, tries to set the RCODE to the
relevant value. If the given string isn't recognized as an RCODE, an exception
will be thrown.

=item opcode([$string])

Returns the packet OPCODE. If given an argument, tries to set the OPCODE to the
relevant value. If the given string isn't recognized as an OPCODE, an exception
will be thrown.

=item id([$value])

Returns the packet id number. If given an argument, sets the ID value to that
value.

=item qr()

=item aa()

=item tc()

=item rd()

=item cd()

=item ra()

=item ad()

=item do()

Reads and/or sets the equivalently named flags.

=item size()

Returns the length of the packet's wireformat form in octets.

=item edns_size()

Gets and/or sets the EDNS0 UDP size.

=item edns_rcode()

Gets and/or sets the EDNS0 Extended RCODE field.

=item ends_z()

Gets and/or sets the EDNS0 Z bits.

=item edns_data()

Gets and/or sets the EDNS0 RDATA. See LDNS.xs for more details.

=item needs_edns()

This method returns true if the packet has the DO flag set, an EDNS0 size set,
and EDNS0 extended RCODE set or if the OPT pseudo-RR has one or more RDATA
fields. It can fail to correctly flag a packet with an OPT pseudo-RR as having
EDNS, if the pseudo-RR specifies an UDP size of zero, an extended RCODE of zero
and the DO flag is unset. Since any UDP size less than 512 must be interpreted
as 512, packets like that should be very rare in practice if they exist at all.

Note that the OPT pseudo-RR is not visible as an RR in the packet, nor is it
included in the RR count header fields.

=item has_edns()

An alias for needs_edns().

=item edns_version($version)

Get or set the EDNS version in the packet. For incoming packets, returns 0 if
the packet does not have an OPT pseudo-RR and 0 if it's an EDNS0 packet. It's
thus rather pointless until such time as EDNS1 is defined.

=item set_edns_present

Set edns_present flag to true.

This flag can be set when creating a packet with EDNS corner cases data that
could not be detected by need_edns/has_edns methods.

When set, need_edns/has_edns methods return true value.

=item unset_edns_present

Set edns_present flag to false.

=item querytime([$value])

Returns the time the query this packet is the answer to took to execute, in
milliseconds. If given a value, sets the querytime to that value.

=item answerfrom($ipaddr)

Returns and optionally sets the IP address the packet was received from. If an attempt is made to set it to a string that cannot be parsed as an
IPv4 or IPv6 address, an exception is thrown.

=item timestamp($time)

The time when the query was sent or received (the ldns docs don't specify), as a floating-point value on the Unix time_t scale (that is, the same
kind of value used by L<Time::HiRes::time()>). Conversion effects between floating-point and C<struct timeval> means that the precision of the
value is probably not reliable at the microsecond level, even if you computer's clock happen to be.

=item question()

=item answer()

=item authority()

=item additional()

Returns list of objects representing the RRs in the named section. They will be of classes appropriate to their types, but all will have
C<Zonemaster::LDNS::RR> as a base class.

=item unique_push($section, $rr)

Push an RR object into the given section, if an identical RR isn't already present. If the section isn't one of "question", "answer", "authority"
or "additional" an exception will be thrown. C<$rr> must be a L<Zonemaster::LDNS::RR> subclass.

=item string()

Returns a string with the packet and its contents in common presentation format.

=item wireformat()

Returns a Perl string holding the packet in wire format.

=item type()

Returns the ldns library's guess as to the content of the packet. One of the strings C<question>, C<referral>, C<answer>, C<nxdomain>, C<nodata> or C<unknown>.

=back
