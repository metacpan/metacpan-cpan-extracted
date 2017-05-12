package WebService::DMM::Label;
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

WebService::DMM::Label - Label class

=head1 INTERFACE

=head2 Accessor

=over

=item id : String

Label ID

=item name : String

Label name

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
