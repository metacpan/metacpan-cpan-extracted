use 5.008003;
use strict;
use warnings;

package no::warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001000';

sub no::warnings {
	my $code = pop;
	my $next = $SIG{__WARN__};
	my $handler = sub {};
	
	if ( @_ ) {
		my @ignore = @_;
		require match::simple;
		$handler = sub {
			my $warning = shift;
			return if match::simple::match( $warning, \@ignore );
			$next ? $next->( $warning ) : warn( $warning );
		};
	}
	
	local $SIG{__WARN__} = $handler;
	return $code->();
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

no::warnings - suppress certain warnings for a dynamic scope

=head1 SYNOPSIS

Load the module:

  use no::warnings;

Disable all warnings for a dynamic scope:

  my $result = no::warnings sub {
    ...;
  };

Disable specific warnings for a dynamic scope:

  my $result = no::warnings qr/.../, qr/.../, sub {
    ...;
  };

=head1 DESCRIPTION

This module provides a function called C<< no::warnings >> which takes
a coderef optionally preceded by a list of things to match.

If no list is provided, it will run the coderef, ignoring any warnings
that would have otherwise been printed to STDERR, and returns the result
of the coderef.

If a list of warnings to ignore is provided, it will run the coderef,
ignoring any warnings that match the list (see L<match::simple>), and
returns the result of the coderef.

This differs from the standard C<< no warnings >> pragma in that it
acts dynamically instead of lexically, allowing you to suppress the
printing of warnings which come from third-party modules, etc.
Internally, it uses C<< $SIG{__WARN__} >> but if you already have a
handler for C<__WARN__>, this module should be smart enough to work 
alongside it unless you're doing something especially odd.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-no-warnings/issues>.

=head1 SEE ALSO

L<warnings>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

