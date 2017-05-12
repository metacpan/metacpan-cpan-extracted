#-*- perl -*-
#-*- coding: utf-8 -*-

package Unicode::Precis::Nickname;

use strict;
use warnings;
use base qw(Unicode::Precis);

our $VERSION = '1.100';

sub new {
    bless shift->SUPER::new(
        AdditionalMappingRule => 'MapSpace StripSpace UnifySpace',
	CaseMappingRule       => 'Fold',
        NormalizationRule     => 'NFKC',
        StringClass           => 'FreeFormClass',
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Unicode::Precis::Nickname - PRECIS Nickname Profile

=head1 SYNOPSIS

  use Unicode::Precis::Nickname;
  
  $profile = Unicode::Precis::Nickname->new;
  
  $string = $profile->enforce($input);
  $equals = $profile->compare($inputA, $inputB);

=head1 DESCRIPTION

L<Unicode::Precis::Nickname> provides the PRECIS C<Nickname> profile.

=head1 SEE ALSO

L<Unicode::Precis>.

RFC 7700
I<Preparation, Enforcement, and Comparison of Internationalized Strings
Representing Nicknames>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji, E<lt>hatuka@nezumi.nuE<gt>

=head1 COPYRIGHT AND LICENSE

(C) 2016 Hatuka*nezumi - IKEDA Soji

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text of
the licenses at <http://dev.perl.org/licenses/>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
