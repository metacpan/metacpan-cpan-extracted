package WebService::DMM::Maker;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/id name/],
);

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Maker - Maker class

=head1 INTERFACE

=head2 Accessor

=over

=item id : String

Maker ID

=item name : String

Maker name

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
