use strict;
use warnings;
use utf8;

package Ukigumo::Helper;
use parent qw(Exporter);
use Ukigumo::Constants;

our @EXPORT = qw(status_str status_color normalize_path);

sub status_str {
    my $status = shift;
    +{
        STATUS_SUCCESS() => 'SUCCESS',
        STATUS_FAIL()    => 'FAIL',
        STATUS_NA()      => 'NA',
        STATUS_SKIP()    => 'SKIP',
        STATUS_PENDING() => 'PENDING',
        STATUS_TIMEOUT() => 'TIMEOUT',
    }->{$status} || "Unknown: $status";
}

sub status_color {
    my $status = shift;
    +{
        STATUS_SUCCESS() => 'green',
        STATUS_FAIL()    => 'red',
        STATUS_NA()      => 'yellow',
        STATUS_SKIP()    => 'gray',
        STATUS_PENDING() => 'yellow',
        STATUS_TIMEOUT() => 'red',
    }->{$status} || "cyan";
}

sub normalize_path {
    my $path = shift;
    $path =~ s/[^a-zA-Z0-9-_]/_/g;
    return $path;
}

1;
__END__

=head1 NAME

Ukigumo::Helper - helper functions for Ukigumo

=head1 FUNCTIONS

=over 4

=item status_str($status: Str) : Str

Get a string representation for status code.

=item status_color($status: Str) : Str

Get a color for the status code.

    STATUS_SUCCESS => green
    STATUS_FAIL    => red
    STATUS_NA      => yellow
    STATUS_SKIP    => gray

=back
