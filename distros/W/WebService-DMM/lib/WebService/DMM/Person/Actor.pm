package WebService::DMM::Person::Actor;
use strict;
use warnings;

use parent qw/WebService::DMM::Person/;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/aliases/],
);

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Person::Actor - Actor class

=head1 INTERFACE

=head2 Accessor

=over

=item id(:String)

Actress ID in DMM.com and DMM.co.jp.

=item name(:String)

Actor name.

=item ruby(:String)

Ruby of actor name, this may be Japanese Hiragana.

=item aliases(:Array[Hash{name=>Str, ruby=>Str}])

This parameter is set, if actor had other names in past.
This type is Array of HashRef which has C<name> and C<ruby> keys.

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
