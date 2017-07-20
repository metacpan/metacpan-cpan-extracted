package WWW::Eksisozluk;
$WWW::Eksisozluk::VERSION = '0.27';
use warnings;
use strict;

use WWW::Eksi;
 
BEGIN {
    push our @ISA, 'WWW::Eksi';
}

1;

__END__

=head1 NAME

WWW::Eksisozluk - an alias to WWW::Eksi

=head1 DESCRIPTION

This module is renamed as L<WWW::Eksi>. You can still use L<WWW::Eksisozluk> as an alias.

=head1 SEE ALSO
 
L<WWW::Eksi>
