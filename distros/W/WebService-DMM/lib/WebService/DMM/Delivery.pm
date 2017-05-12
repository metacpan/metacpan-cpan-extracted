package WebService::DMM::Delivery;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/type price/],
);

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Delivery - Delivery class

=head1 INTERFACE

=head2 Accessor

=over

=item type : String

Delivery type, such as I<download>

=item price : Int

This delivery price.

=back

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 - Syohei YOSHIDA

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
