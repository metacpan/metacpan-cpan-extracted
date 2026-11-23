package VPNDetection::Result;

use strict;
use warnings;

use Carp ();

our $VERSION = '3.18.1';

our @FLAGS = qw(
    is_vpn is_hosting is_relay is_tor is_cdn is_bot is_resproxy is_dcproxy is_mobproxy
    is_pubproxy is_anycast is_carrier is_satellite is_ssh is_smtp is_web is_dns_resolver
    is_bittorrent
);
# Each flag's detail: an object, or for `web` a list of the ports that answered.
# `is_anycast` has none.
our @DETAILS = qw(
    vpn hosting relay tor cdn bot resproxy dcproxy mobproxy pubproxy carrier satellite ssh
    smtp web dns_resolver bittorrent
);
# Where the address is and the AS announcing it, on every answer, with or without
# a key, each with every member present: an empty string, or AS 0, where nothing
# is known. The reverse DNS hostname is on every answer too, and company and abuse
# on a paid plan's.
our @OBJECTS = qw(location asn company hostname abuse);
# The members of each object. Those after flag_unicode in location, and after
# prefix in asn, are absent from an answer whose plan leaves them out.
our @LOCATION = qw(
    continent continent_name country country_name timezone currency_code currency_name
    currency_symbol flag_emoji flag_unicode region region_code city postal_code latitude
    longitude accuracy_radius geoname_id dma_code last_changed
);
our @ASN = qw(asn name domain type prefix country rpki_status);
our @COMPANY = qw(name domain type country);
our @ABUSE = qw(email name phone address country network validated unvalidated_since);
# On answers to a key on the free plan only, and so never on a bogon's: false
# while its organization's trial of every field lasts, true once the answer has
# Unlimited's. cap_reached is the
# same on a paid plan's answers: false while the answer has every field, true
# once its organization's overage cap is reached.
our @MARKERS = qw(trial_expired cap_reached);

my %KNOWN = map { $_ => 1 } 'ip', 'is_bogon', @FLAGS, @DETAILS, @OBJECTS, @MARKERS;

# The one place a wire body becomes a result. Every field is copied on key
# PRESENCE and never on truthiness: a plan that includes `is_hosting` and
# answers false must keep it, and a plan that does not include it must not gain
# it. In Perl those two are one careless `if` apart, since undef, 0, '' and a
# missing key are all false.
sub from_wire {
    my ($class, $body) = @_;
    my %answer = (ip => $body->{ip}, is_bogon => $body->{is_bogon} ? 1 : 0);
    # A served null stays undef, as a detail's does: read as 0 it would say the
    # address is no hosting server, or that the trial lasts, when nothing was said.
    for my $flag (@FLAGS, @MARKERS) {
        next unless exists $body->{$flag};
        $answer{$flag} = defined $body->{$flag} ? ($body->{$flag} ? 1 : 0) : undef;
    }
    for my $detail (@DETAILS, @OBJECTS) {
        $answer{$detail} = $body->{$detail} if exists $body->{$detail};
    }
    return $class->_new(\%answer, $body);
}

# Whether your plan carries this field at all, which is a different question
# from what the field says. `has` is the only honest answer to "is this address
# hosting?" when the field may not have been served: absent is not false.
sub has {
    my ($self, $field) = @_;
    Carp::croak("VPNDetection::Result::has: unknown field '$field'") unless $KNOWN{$field};
    return exists $self->{$field} ? 1 : 0;
}

# The fields this answer actually carried, in wire order. Useful for seeing what
# a key is entitled to without reading the plan table.
sub fields {
    my ($self) = @_;
    return grep { exists $self->{$_} } @FLAGS, @DETAILS, @OBJECTS, @MARKERS;
}

# The response exactly as it came off the wire, with its original names and its
# JSON booleans intact. Empty for a bogon, which was never served.
sub raw {
    return $_[0]->{_raw};
}

sub _new {
    my ($class, $answer, $raw) = @_;
    $answer->{_raw} = $raw;
    return bless $answer, $class;
}

# One reader per field rather than AUTOLOAD, so a typo is a compile-adjacent
# "Can't locate object method" rather than a silent undef.
for my $field ('ip', 'is_bogon', @FLAGS, @DETAILS, @OBJECTS, @MARKERS) {
    no strict 'refs';
    *{__PACKAGE__ . "::$field"} = sub { $_[0]->{$field} };
}

1;

__END__

=head1 NAME

VPNDetection::Result - what a lookup answers

=head1 SYNOPSIS

    my $result = $client->lookup('45.83.91.1');

    $result->ip;                    # '45.83.91.1'
    $result->is_vpn;                # 1
    $result->vpn->{provider};       # 'mullvad'
    $result->location->{country};   # the ISO 3166 country code
    $result->asn->{name};           # who runs the announcing network
    $result->hostname;              # the reverse DNS name, '' where it has none

    $result->is_bot;                # 1 when an automated client uses the address
    $result->bot->{provider_name};  # whose bot, on a paid plan
    $result->is_hosting;            # 1, 0, or undef when your plan omits it
    $result->is_hosting // 0;       # read an absent field as false
    $result->has('is_hosting');     # 1 if your plan carries it at all

=head1 ABSENT IS NOT FALSE

An B<absent> field is one your plan does not include. It never means "we checked
and found nothing", so C<undef> and C<0> are genuinely different answers.

This is the one place Perl makes it easy to get wrong, because C<undef>, C<0>,
C<''> and a missing hash key are all false:

    if ($result->is_hosting) { ... }        # WRONG: absent and false look alike

    if (($result->is_hosting // 0)) { ... } # right: absent reads as false
    if ($result->has('is_hosting')) { ... } # right: asks whether it was served

C<//> (defined-or) is the reader for "treat absent as false", and C<has> is the
reader for "was this served at all". A result is also a plain hash reference, so
C<exists $result-E<gt>{is_hosting}> is C<has> spelled out and
C<defined $result-E<gt>{is_hosting}> is the same test one level down.

A detail object that is present but B<empty> (C<{}>) means the flag above it is
false. A populated one always carries every one of its keys.

=head1 METHODS

=head2 ip, is_vpn, is_bogon

Always present. C<is_bogon> is C<1> for reserved space (private, loopback,
documentation and the like), which this module answers locally without a request;
a served answer carries the API's own C<is_bogon>, which this reads.

=head2 is_hosting, is_relay, is_tor, is_cdn, is_resproxy, is_dcproxy, is_mobproxy, is_pubproxy

The tier-gated flags: C<1>, C<0>, or C<undef> when your plan omits the field.
On Unlimited, the free plan, with a key or without one, C<is_tor> and C<is_relay> come
back beside C<is_vpn>; every paid plan answers every flag. C<is_pubproxy> is whether a
public proxy, one anyone can connect through, listens on the address or sends
its traffic out from it.

=head2 is_bot

On every answer, with or without a key: C<1> when an automated client uses the
address, such as a search engine's or an AI company's crawler, an uptime monitor,
an internet scanner or a webhook sender, C<0> when none does, and C<undef> on an
answer that does not carry it.

=head2 bot

The detail behind C<is_bot>, on a paid plan's answers, or C<undef> when your plan
omits it: a plain hash reference, C<{}> when C<is_bot> is false. It carries
C<provider> and C<provider_name> (the bot's operator, empty where none is known),
C<agents> (an array reference of the bots the address serves, as their user agents
name them, in the order served), C<categories> (an array reference of what those
bots do), C<verified> (whether the operator vouches for the address),
C<identity>, C<verified_by>, C<confidence>, C<first_seen> and C<last_seen>.

=head2 is_anycast, is_carrier, is_satellite, is_ssh, is_smtp, is_web, is_dns_resolver, is_bittorrent

C<is_anycast> is on every answer, with or without a key: whether the address is
announced from many places at once, as a public DNS resolver's or a CDN's edge
is. The rest are on a paid plan's answers: whether the address is a mobile
carrier's or a satellite operator's, and whether an SSH server, a mail server, a
web server, an open DNS resolver or a BitTorrent client answered on it. Each is
C<1>, C<0>, or C<undef> when your plan omits it.

=head2 vpn, hosting, relay, tor, cdn, resproxy, dcproxy, mobproxy, pubproxy

The detail objects, as plain hash references, or C<undef> when your plan omits
them. C<vpn> carries C<provider>, C<provider_name>, C<last_seen> and C<confidence>; its C<method>
is deprecated, since no plan is answered with it from 2026-10-20. C<pubproxy> carries C<entry>, C<exit>, C<protocols> (an array
reference), C<num_ports>, C<num_proxies>, C<last_seen> and C<last_usable>.
C<num_ports> is 0 when the address is only an exit and C<num_proxies> 0 when it
is only an entry; C<last_usable> is an empty string when no request through a
proxy on the address was answered.

=head2 carrier, satellite, ssh, smtp, web, dns_resolver, bittorrent

The detail behind each of those flags, on a paid plan's answers, or C<undef> when
your plan omits it. Each is a plain hash reference, C<{}> when its flag is false,
except C<web>, an array reference with one hash per port that answered, C<[]>
when C<is_web> is false. C<carrier> carries C<name>, C<mcc>, C<mnc>, C<country>
and C<confidence>; C<satellite> C<provider>, C<provider_name>, C<orbit>,
C<segment>, C<country>, C<asn> and C<confidence>; C<ssh> C<port>, C<banner>,
C<host_key_fp>, C<session_ok>, C<first_seen> and C<last_seen>; C<smtp> C<port>,
C<banner>, C<session_ok>, C<first_seen> and C<last_seen>; each row of C<web>
C<port>, C<tls_ok>, C<session_ok>, C<status_code>, C<server>, C<location>,
C<title>, C<cert_subject_cn>, C<cert_subject_o>, C<cert_issuer_dn>,
C<cert_browser_trusted>, C<tls_version>, C<first_seen> and C<last_seen>;
C<dns_resolver> C<port>, C<recursion_available>, C<rcode>, C<answer_correct>,
C<first_seen> and C<last_seen>; C<bittorrent> C<verified>, C<id_matches_ip>,
C<first_seen>, C<last_seen>, C<last_reachable>, C<days_seen>, C<num_ports>,
C<peak_num_ports>, C<indexer> and C<clients> (an array reference).

=head2 location, asn

Where the address is and the AS announcing it, as plain hash references, on every
answer, with or without a key. C<location> carries C<continent>,
C<continent_name>, C<country>, C<country_name>, C<timezone>, C<currency_code>,
C<currency_name>, C<currency_symbol>, C<flag_emoji> and C<flag_unicode>; C<asn>
carries C<asn>, C<name>, C<domain>, C<type>, C<prefix>, C<country> and
C<rpki_status>. Every key is present whenever the object is: an empty string,
and C<asn> 0, where nothing is known. A paid plan's C<location> also carries
C<region>, C<region_code>, C<city>, C<postal_code>, C<latitude>, C<longitude>,
C<accuracy_radius>, C<geoname_id>, C<dma_code> and C<last_changed>, which are
absent on a plan without them.

=head2 hostname

The name the address's reverse DNS record points to, on every answer, with or
without a key: an empty string where it has none.

=head2 company, abuse

On a paid plan's answers, as plain hash references, or C<undef> when your plan
omits them. C<company> is who uses the address: C<name>, C<domain>, C<type> and
C<country>. C<abuse> is where to report abuse from it: C<email>, C<name>,
C<phone>, C<address>, C<country>, C<network>, C<validated> and
C<unvalidated_since>. Every key is present whenever the object is: empty strings
where no record covers the address.

=head2 trial_expired

On answers to a key on the free plan only: C<0> while its organization's trial
of every field lasts, C<1> once the answer has Unlimited's, and C<undef> on any
other answer.

=head2 cap_reached

On answers to a key on a paid plan only: C<0> while the answer has every field,
C<1> once its organization's overage cap is reached and the answer has
Unlimited's, and C<undef> on any other answer. Lookups answered past the cap
are not billed.

=head2 has($field)

Whether your plan carries C<$field>. Croaks on a name that is not a field.

=head2 fields

The field names this answer carried, in wire order.

=head2 raw

The decoded response body, untouched. Treat it, and the result itself, as read
only: the cache hands the same object to every later caller of an address.

=cut
