# ex:ts=4:sw=4:sts=4:et
package Transmission::Utils;
# See Transmission::Client for copyright statement.

=head1 NAME

Transmission::Utils - Utilies for modules that use Transmission::*

=cut

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw/ from_numeric_status to_numeric_status /],
};

my %numeric_status = qw/
    1   queued
    2   checking
    4   downloading
    8   seeding
    16  stopped
/;

=head1 FUNCTIONS

=head2 from_numeric_status

 $str = from_numeric_status($int);

Will translate a numeric status description from Transmission to something
readable.

=cut

sub from_numeric_status {
    return $numeric_status{$_[0]} || q();
}

=head2 to_numeric_status

 $int = to_numeric_status($str);

Will translate a status description to a number used by Transmission.

=cut

sub to_numeric_status {
    my %tmp = reverse %numeric_status;
    return $tmp{$_[0]} || -1;
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
