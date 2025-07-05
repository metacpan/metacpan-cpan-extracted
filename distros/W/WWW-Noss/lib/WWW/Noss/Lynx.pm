package WWW::Noss::Lynx;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use Exporter qw(import);
our @EXPORT_OK = qw(lynx_dump);

my @DUMP_OPTS = qw(
	-dump
	-force_html
	-nolist
	-display_charset=utf8
);

sub lynx_dump {

	my ($file, %param) = @_;
	my $width = $param{ width } // 80;

	my $cmd =
		sprintf "lynx @DUMP_OPTS %s '%s'",
		"-width '$width'",
		$file;

	my $dump = qx/$cmd/;

	if ($? == -1) {
		die "Failed to execute lynx, is it installed?\n";
	}

	if ($? >> 8 != 0) {
		die "Failed to dump $file with lynx\n";
	}

	return $dump;

}

=head1 NAME

WWW::Noss::Lynx - lynx interface

=head1 USAGE

  use WWW::Noss::Lynx qw(lynx_dump);

  my $dump = lynx_dump($html_file);

=head1 DESCRIPTION

B<WWW::Noss::Lynx> is a module that provides an interface to the L<lynx(1)>
command for formatting HTML. This is a private module, please consult the
L<noss> manual for user documentation.

=head1 SUBROUTINES

Subroutines are not exported automatically.

=over 4

=item $dump = lynx_dump($html, [ %param ])

Dumps the HTML file C<$html> using L<lynx(1)>'s C<-dump> option. Returns the
formatted text. Dies on failure.

C<%param> is an optional hash argument for providing additional parameters to
C<lynx_dump()>. The follow are a list of valid fields:

=over 4

=item width

Line width to use for formatted text dump. Defaults to C<80>.

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

L<lynx(1)>, L<noss>

=cut

1;

# vim: expandtab shiftwidth=4
