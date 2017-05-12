package WebService::DMM::Person::Director;
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

WebService::DMM::Person::Director - Director class

=head1 INTERFACES

=head2 Accessor

=over

=item id

Directory ID in DMM.com or DMM.co.jp.

=item name

Director name.

=item ruby

Ruby of director name, this may be Japanese Hiragana.

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
