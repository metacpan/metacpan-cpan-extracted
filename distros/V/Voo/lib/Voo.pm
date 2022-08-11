package Voo;

use 5.018;
use strict;
use warnings;
use feature 'lexical_subs';

our $VERSION = '42.43';

sub import {
	use Data::Dumper; warn Dumper \@_;
  if ( my $sub = $_[1] ) {
  	$sub->();
	}
}

1;

__END__

=head1 NAME

Voo - Run functions at compile time, not runtime!

=head1 SYNOPSIS

This module uses lexical subs (enabled with C<use v5.26;> or
C<use feature 'lexical_subs';> to run a subroutine at compile time.

		die 7; # never called, runs in runtime
		
		use Voo do {
			my sub foo { die 42 };
			\&foo;
		};
		
		die 7; # never called, runs in runtime

=head1 EXPORT

We export nothing. The only UI is from the import routine which expect a lexical sub.

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-voo at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Voo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Voo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Voo>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Voo>

=item * Search CPAN

L<https://metacpan.org/release/Voo>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Evan Carroll.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
