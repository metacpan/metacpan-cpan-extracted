package VPNDetection::Result;

use strict;
use warnings;

use Carp ();

our $VERSION = '1.4.0';

our @FLAGS = qw(
    is_vpn is_hosting is_relay is_tor is_cdn is_resproxy is_dcproxy is_mobproxy
);
our @DETAILS = qw(vpn hosting relay tor cdn resproxy dcproxy mobproxy);

my %KNOWN = map { $_ => 1 } 'ip', 'is_bogon', @FLAGS, @DETAILS;

# The one place a wire body becomes a result. Every field is copied on key
# PRESENCE and never on truthiness: a plan that includes `is_hosting` and
# answers false must keep it, and a plan that does not include it must not gain
# it. In Perl those two are one careless `if` apart, since undef, 0, '' and a
# missing key are all false.
sub from_wire {
    my ($class, $body) = @_;
    my %answer = (ip => $body->{ip}, is_bogon => 0);
    for my $flag (@FLAGS) {
        $answer{$flag} = $body->{$flag} ? 1 : 0 if exists $body->{$flag};
    }
    for my $detail (@DETAILS) {
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
    return grep { exists $self->{$_} } @FLAGS, @DETAILS;
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
for my $field ('ip', 'is_bogon', @FLAGS, @DETAILS) {
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

Always present. C<is_bogon> is set when the answer was computed locally rather
than served.

=head2 is_hosting, is_relay, is_tor, is_cdn, is_resproxy, is_dcproxy, is_mobproxy

The tier-gated flags: C<1>, C<0>, or C<undef> when your plan omits the field.

=head2 vpn, hosting, relay, tor, cdn, resproxy, dcproxy, mobproxy

The detail objects, as plain hash references, or C<undef> when your plan omits
them.

=head2 has($field)

Whether your plan carries C<$field>. Croaks on a name that is not a field.

=head2 fields

The field names this answer carried, in wire order.

=head2 raw

The decoded response body, untouched. Treat it, and the result itself, as read
only: the cache hands the same object to every later caller of an address.

=cut
