package Xerarch;

use 5.006;
use strict;
use warnings;
use meta;

our $VERSION = '0.05';

sub import {
	my $caller = caller();
	my $metapkg = meta::get_package( $caller );

	my $callback = sub {
		my ($is, $key) = @_;
		return sub {
			my %symbols = $metapkg->list_symbols;
			my @items;
			for ( sort keys %symbols ) {
				next if $_ =~ m/xerarch/;
				if ($symbols{$_}->$is) {
					push @items, $key ? (split "::", $symbols{$_}->$key)[1] : $_;
				}
			}

			return \@items;
		};
	};

	$metapkg->add_named_sub( 'xerarch_methods', $callback->('is_subroutine', 'subname') );
	
	$metapkg->add_named_sub( 'xerarch_scalars', $callback->('is_scalar') );
	
	$metapkg->add_named_sub( 'xerarch_arrays', $callback->('is_array') );

	$metapkg->add_named_sub( 'xerarch_hashes', $callback->('is_hash') );

	$metapkg->add_named_sub( 'xerarch_globs', $callback->('is_glob') );

	$metapkg->add_named_sub( 'xerarch', sub {
		my %meta;
		for (qw/methods scalars arrays hashes globs/) {
			my $method = 'xerarch_' . $_;
			$meta{$_} = $caller->$method;
		}
		return \%meta;
	});
}

1;

=head1 NAME

Xerarch - Introspection

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	package My::Package;

	use Xerarch;

	...

	1;

	my $pkg = My::Package->new();

	$pkg->xerarch();

	$pkg->xerarch_methods();
	$pkg->xerarch_scalars();
	$pkg->xerarch_arrays();
	$pkg->xerarch_hashes();
	$pkg->xerarch_globs();    	

=head1 EXPORT

=head2 xerarch

List all methods, scalars, arrays, hashes and globs defined in the package.

	My::Package::xerarch();

=cut

=head2 xerarch_methods

List all methods defined in the package.

	My::Package::xerarch_methods();

=cut

=head2 xerarch_scalars

List all scalars defined in the package.

	My::Package::xerarch_scalars();

=cut

=head2 xerarch_arrays

List all arrays defined in the package.

	My::Package::xerarch_arrays();

=cut

=head2 xerarch_hashes

List all hashes defined in the package.

	My::Package::xerarch_hashes();

=cut

=head2 xerarch_globs

List all globs for the package.

	My::Package::xerarch_globs();

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xerarch at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Xerarch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Xerarch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Xerarch>

=item * Search CPAN

L<https://metacpan.org/release/Xerarch>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Xerarch
