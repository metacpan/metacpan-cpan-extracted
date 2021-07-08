=pod

=head1 NAME

Cli::Human - A collection of utility functions to make things more human friendly

=head1 METHODS

=cut
package Wireguard::WGmeta::Cli::Human;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';
use Scalar::Util qw(looks_like_number);
use base 'Exporter';
our @EXPORT = qw(disabled2human bits2human return_self timestamp2human);


sub disabled2human($state) {
    if ($state == 1) {
        return "no";
    }
    return "yes";
}

=head3 bits2human($n_bits)

Takes a number of bits and coverts it to a human readable amount of MiB

B<Parameters>

=over 1

=item

C<$n_bits> A number of bits

=back

B<Returns>

$n_bits * 1_000_000 . "MiB"

=cut
sub bits2human($n_bits) {
    if (looks_like_number($n_bits)){
        # this calculation is probably not correct, however, I found no reference on what is actually the unit of the wg show dump...
        return sprintf("%.2f %s", $n_bits / 1_000_000, "MiB");
    }
    return "0.0 MiB";

}

=head3 timestamp2human($timestamp)

Takes a unix timestamp and puts it in a human relatable form (delta from now)

B<Parameters>

=over 1

=item

C<$timestamp> Int or string containing a unix timestamp

=back

B<Returns>

A string describing how long ago this timestamp was

=cut
sub timestamp2human($timestamp) {
    if (not looks_like_number($timestamp) or $timestamp == 0) {
        return "never"
    }
    my $int_timestamp = int($timestamp);
    my $delta = time - $int_timestamp;
    if ($delta > 2592000) {
        return ">month ago";
    }
    if ($delta > 604800) {
        return ">week ago";
    }
    if ($delta > 86400) {
        return ">day ago";
    }
    if ($delta < 86400) {
        return sprintf("%.2f mins ago", $delta / 60);
    }
    return $delta;
}

=head3 return_self($x)

The famous C<id()> function

B<Parameters>

=over 1

=item

C<$x> Some value or object

=back

B<Returns>

C<$x>

=cut
sub return_self($x) {
    return $x;
}

1;