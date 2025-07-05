package WWW::Noss::Dir;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use Exporter qw(import);
our @EXPORT_OK = qw(dir);

use File::Spec;

sub dir {

	my ($dir, %param) = @_;
	my $hidden = $param{ hidden } // 0;

	opendir my $dh, $dir
		or die "Failed to open $dir as a directory: $!\n";
	my @f = sort grep { ! /^\.\.?$/ } readdir $dh;
	closedir $dh;

	unless ($hidden) {
		@f = grep { ! /^\./ } @f;
	}

	return map { File::Spec->catfile($dir, $_) } @f;

}

1;

=head1 NAME

WWW::Noss::Dir - dir subroutine

=head1 USAGE

  use WWW::Noss::Dir qw(dir);

  my @files = dir('/');

=head1 DESCRIPTION

B<WWW::Noss::Dir> is a module that provides the C<dir()>, subroutine, which
returns a list of files present in the given directory. This is a private
module, please consult the L<noss> manual for user documentation.

=head1 SUBROUTINES

Subroutines are not exported automatically.

=over 4

=item @files = dir($dir, [ %param ])

Returns a list of files present in the directory C<$dir>. C<%param> is an
optional argument of additional parameters.

The following are valid fields in C<%param>:

=over 4

=item hidden

Boolean determining whether to include hidden files or not. Defaults to false.

=back

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
