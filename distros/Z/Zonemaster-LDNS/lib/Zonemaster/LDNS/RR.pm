package Zonemaster::LDNS::RR;

use Zonemaster::LDNS::RR::A;
use Zonemaster::LDNS::RR::A6;
use Zonemaster::LDNS::RR::AAAA;
use Zonemaster::LDNS::RR::AFSDB;
use Zonemaster::LDNS::RR::APL;
use Zonemaster::LDNS::RR::ATMA;
use Zonemaster::LDNS::RR::CAA;
use Zonemaster::LDNS::RR::CDS;
use Zonemaster::LDNS::RR::CERT;
use Zonemaster::LDNS::RR::CNAME;
use Zonemaster::LDNS::RR::DHCID;
use Zonemaster::LDNS::RR::DLV;
use Zonemaster::LDNS::RR::DNAME;
use Zonemaster::LDNS::RR::DNSKEY;
use Zonemaster::LDNS::RR::DS;
use Zonemaster::LDNS::RR::EID;
use Zonemaster::LDNS::RR::EUI48;
use Zonemaster::LDNS::RR::EUI64;
use Zonemaster::LDNS::RR::GID;
use Zonemaster::LDNS::RR::GPOS;
use Zonemaster::LDNS::RR::HINFO;
use Zonemaster::LDNS::RR::HIP;
use Zonemaster::LDNS::RR::IPSECKEY;
use Zonemaster::LDNS::RR::ISDN;
use Zonemaster::LDNS::RR::KEY;
use Zonemaster::LDNS::RR::KX;
use Zonemaster::LDNS::RR::L32;
use Zonemaster::LDNS::RR::L64;
use Zonemaster::LDNS::RR::LOC;
use Zonemaster::LDNS::RR::LP;
use Zonemaster::LDNS::RR::MAILA;
use Zonemaster::LDNS::RR::MAILB;
use Zonemaster::LDNS::RR::MB;
use Zonemaster::LDNS::RR::MD;
use Zonemaster::LDNS::RR::MF;
use Zonemaster::LDNS::RR::MG;
use Zonemaster::LDNS::RR::MINFO;
use Zonemaster::LDNS::RR::MR;
use Zonemaster::LDNS::RR::MX;
use Zonemaster::LDNS::RR::NAPTR;
use Zonemaster::LDNS::RR::NID;
use Zonemaster::LDNS::RR::NIMLOC;
use Zonemaster::LDNS::RR::NINFO;
use Zonemaster::LDNS::RR::NS;
use Zonemaster::LDNS::RR::NSAP;
use Zonemaster::LDNS::RR::NSEC;
use Zonemaster::LDNS::RR::NSEC3;
use Zonemaster::LDNS::RR::NSEC3PARAM;
use Zonemaster::LDNS::RR::NULL;
use Zonemaster::LDNS::RR::NXT;
use Zonemaster::LDNS::RR::PTR;
use Zonemaster::LDNS::RR::PX;
use Zonemaster::LDNS::RR::RKEY;
use Zonemaster::LDNS::RR::RP;
use Zonemaster::LDNS::RR::RRSIG;
use Zonemaster::LDNS::RR::RT;
use Zonemaster::LDNS::RR::SINK;
use Zonemaster::LDNS::RR::SOA;
use Zonemaster::LDNS::RR::SPF;
use Zonemaster::LDNS::RR::SRV;
use Zonemaster::LDNS::RR::SSHFP;
use Zonemaster::LDNS::RR::TA;
use Zonemaster::LDNS::RR::TALINK;
use Zonemaster::LDNS::RR::TKEY;
use Zonemaster::LDNS::RR::TLSA;
use Zonemaster::LDNS::RR::TXT;
use Zonemaster::LDNS::RR::TYPE;
use Zonemaster::LDNS::RR::UID;
use Zonemaster::LDNS::RR::UINFO;
use Zonemaster::LDNS::RR::UNSPEC;
use Zonemaster::LDNS::RR::URI;
use Zonemaster::LDNS::RR::WKS;
use Zonemaster::LDNS::RR::X25;

use Carp;

use overload '<=>' => \&do_compare, 'cmp' => \&do_compare, '""' => \&to_string;

sub new {
    my ( $class, $string ) = @_;

    if ( $string ) {
        return $class->new_from_string( $string );
    }
    else {
        croak "Must provide string to create RR";
    }
}

sub name {
    my ( $self ) = @_;

    return $self->owner;
}

sub do_compare {
    my ( $self, $other, $swapped ) = @_;

    return $self->compare( $other );
}

sub to_string {
    my ( $self ) = @_;

    return $self->string;
}

1;

=head1 NAME

Zonemaster::LDNS::RR - common baseclass for all classes representing resource records.

=head1 SYNOPSIS

    my $rr = Zonemaster::LDNS::RR->new('www.iis.se IN A 91.226.36.46');

=head1 OVERLOADS

This class overloads stringify and comparisons ('""', '<=>' and 'cmp').

=head1 CLASS METHOD

=over

=item new($string)

Creates a new RR object of a suitable subclass, given a string representing an RR in common presentation format.

=back

=head1 INSTANCE METHODS

=over

=item owner()

=item name()

These two both return the owner name of the RR.

=item ttl()

Returns the ttl of the RR.

=item type()

Return the type of the RR.

=item class()

Returns the class of the RR.

=item string()

Returns a string with the RR in presentation format.

=item do_compare($other)

Calls the XS C<compare> method with the arguments it needs, rather than the ones overloading gives.

=item to_string

Calls the XS C<string> method with the arguments it needs, rather than the ones overloading gives. Functionally identical to L<string()> from the
Perl level, except for being a tiny little bit slower.

=item rd_count()

The number of RDATA objects in this RR.

=item rdf($postion)

The raw data of the RDATA object in the given position. The first item is in
position 0. If an attempt is made to fetch RDATA from a position that doesn't
have any, an exception will be thrown.

=back
