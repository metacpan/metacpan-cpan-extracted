#-*- perl -*-
#-*- coding: utf-8 -*-

package Unicode::Precis::UsernameCasePreserved;

use strict;
use warnings;
use base qw(Unicode::Precis);

our $VERSION = '1.000';

sub new {
    bless shift->SUPER::new(
        WidthMappingRule   => 'Decomposition',
        NormalizationRule  => 'NFC',
        DirectionalityRule => 'BiDi',
        StringClass        => 'IdentifierClass',
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Unicode::Precis::UsernameCasePreserved - PRECIS UsernameCasePreserved Profile

=head1 SYNOPSIS

  use Unicode::Precis::UsernameCasePreserved;
  
  $profile = Unicode::Precis::UsernameCasePreserved->new;
  
  $string = $profile->enforce($input);
  $equals = $profile->compare($inputA, $inputB);

=head1 DESCRIPTION

L<Unicode::Precis::UsernameCasePreserved> provides the PRECIS
C<UsernameCasePreserved> profile.

=head1 SEE ALSO

L<Unicode::Precis>.

RFC 7613
I<Preparation, Enforcement, and Comparison of Internationalized Strings
Representing Usernames and Passwords>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji, E<lt>hatuka@nezumi.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Hatuka*nezumi - IKEDA Soji

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text of
the licenses at <http://dev.perl.org/licenses/>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
