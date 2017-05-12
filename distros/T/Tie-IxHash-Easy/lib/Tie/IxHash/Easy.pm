package Tie::IxHash::Easy;

use base 'Tie::IxHash';
use strict;
use warnings;

our $VERSION = '0.01';

sub STORE {
  my ($self, $key, $value) = @_;
  tie %$value, 'Tie::IxHash::Easy' if ref($value) eq "HASH";
  $self->SUPER::STORE($key, $value);
}

1;

__END__

=head1 NAME

Tie::IxHash::Easy - Auto-tie()s internal hashes in a tied hash

=head1 SYNOPSIS

  use Tie::IxHash::Easy;
  tie %x, 'Tie::IxHash::Easy';

=head1 DESCRIPTION

This module automatically ties any hash reference in the tied hash to
the same class, making all of them behave like Tie::IxHash hashes.

=head1 SEE ALSO

See L<Tie::IxHash> for what that module does.

See L<Tie::Autotie> for a generalization of this module.

=head BUGS

See L<Tie::Autotie> for two bugs that this module also exhibits.

=head1 AUTHOR

Jeff C<japhy> Pinyan, E<lt>japhy@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by japhy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
