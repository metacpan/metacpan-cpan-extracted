
	package Test::More::Color;

	use strict;
	use warnings;

	our $VERSION = 0.040_000;

=head1 NAME

Test::More::Color - Very stupid TAP colorer

=head1 SYNOPSIS

  use Test::More;
  eval 'use Test::More::Color';
  eval 'use Test::More::Color "foreground"';

  use_ok('Test::More::Color');

=cut

	my ( $fg, $old_print ) = ( $ENV{TM_COLOR_FG} || 0 );

	sub DEBUG	{ $ENV{DEBUG_TM_COLOR} || 0 }

	# If exists color lib
	eval { require Term::ANSIColor };
	unless ( $@ ) {
		DEBUG && warn __PACKAGE__, " \&Test::Builder::_print attacks";
		no strict 'refs';
		no warnings 'redefine';
		$old_print = \&Test::Builder::_print;
		*Test::Builder::_print = \&color_print;
		*c = \&Term::ANSIColor::color;
	}

	sub OK		{ $fg ? c("green")	: c("black").c("on_green")	}
	sub NOT_OK	{ $fg ? c("red")	: c("black").c("on_red");	}
	sub RESET	{ c("reset");									}

	sub import {
		shift;
		map { /^foreground$/ and $fg = 1 } @_;
	}

	sub foreground { $fg = 1; }

	sub color_print {
		DEBUG && warn __PACKAGE__, "::bgcolor_print ", $_[1];

		# Colorer if don't pipe
		$_[1] =~ s/^((not)?\s*ok\s*\d+)/( $2 ? NOT_OK : OK ) . $1 . RESET/e
			unless -p $_[0]->output;
		$old_print->(@_);
	}

=head1 AUTHOR

coolmen, C<< <coolmen78 at google.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-more-color at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-More-Color>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::More::Color


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-More-Color>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-More-Color>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-More-Color>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-More-Color/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 coolmen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::More::Color

