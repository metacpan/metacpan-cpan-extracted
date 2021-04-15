=head1 NAME

WGmeta::Validator - A place for all input validation functions

=cut

package Wireguard::WGmeta::Validator;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use Scalar::Util qw(looks_like_number);

use base 'Exporter';
our @EXPORT = qw(accept_any is_number looks_like_comma_sep_ips);

use constant FALSE => 0;
use constant TRUE => 1;


sub accept_any($input) {
    return TRUE;
}

sub is_number($input) {
    return looks_like_number($input);
}

sub looks_like_comma_sep_ips($input) {
    my @ips = split /\,/, $input;
    chomp(@ips);
    for my $possible_ip (@ips) {
        my @v4 = $possible_ip =~ /(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/g;
        my @v6 = $possible_ip =~ /([a-f0-9:]+:+[a-f0-9]+)\/(\d{1,3})/g;
        return FALSE if (!@v4 && !@v6);
    }
    return TRUE;
}

1;