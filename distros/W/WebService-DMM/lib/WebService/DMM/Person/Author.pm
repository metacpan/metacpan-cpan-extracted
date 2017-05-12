package WebService::DMM::Person::Author;
use strict;
use warnings;

use parent qw/WebService::DMM::Person/;

use Class::Accessor::Lite (
    new => 1,
);

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Person::Author - Author class.

=head1 INTERFACE

=head2 Accessor

=over

=item id

Author ID.

=item name

Author name.

=item ruby

Ruby of author name, this may be Japanese Hiragana.

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
