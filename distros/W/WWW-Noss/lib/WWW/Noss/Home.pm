package WWW::Noss::Home;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use Exporter 'import';
our @EXPORT_OK = qw(home);

my $HOME = $^O eq 'Win32' ? $ENV{ USERPROFILE } : (<~>)[0];
undef $HOME if defined $HOME and ! -d $HOME;

sub home { $HOME // die "Could not determine home directory\n" }

1;

=head1 NAME

WWW::Noss::Home - Find user's home directory

=head1 USAGE

  use WWW::Noss::Home qw(home);

  my $home = home;

=head1 DESCRIPTION

B<WWW::Noss::Home> is a module that provides the C<home()> subroutine for
locating the running user's home directory. This is a private module, please
consult the L<noss> manual for user documentation.

=head1 SUBROUTINES

Subroutines are not exported automatically.

=over 4

=item $home = home()

Returns the path to the running user's home directory. Dies on failure.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<noss>

=cut

# vim: expandtab shiftwidth=4
