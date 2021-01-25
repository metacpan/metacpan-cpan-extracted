=head1 NAME

WGmeta::Validator - A place for all input validation functions

=cut

package Wireguard::WGmeta::Validator;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use Scalar::Util qw(looks_like_number);

use base 'Exporter';
our @EXPORT = qw(accept_any is_number);

use constant FALSE => 0;
use constant TRUE => 1;


sub accept_any($input) {
    return TRUE;
}

sub is_number($input) {
    return looks_like_number($input);
}

1;