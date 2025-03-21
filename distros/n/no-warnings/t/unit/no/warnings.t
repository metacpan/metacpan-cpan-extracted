=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<no::warnings>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'no::warnings';
use Test2::Tools::Spec;
use Data::Dumper;

describe "function `no::warnings`" => sub {

	tests 'simple case' => sub {
		my ( $got, $w );
		
		$w = warnings {
			use warnings;
			$got = no::warnings sub {
				my $x = undef;
				my $y = 7;
				return $x + $y;
			};
		};
		
		is $got, 7;
		is $w, [] or diag Dumper( $w );
	};

	tests 'regexp case, matching' => sub {
		my ( $got, $w );
		
		$w = warnings {
			use warnings;
			$got = no::warnings qr/uninitialized value/, sub {
				my $x = undef;
				my $y = 7;
				return $x + $y;
			};
		};
		
		is $got, 7;
		is $w, [] or diag Dumper( $w );
	};
	
	tests 'regexp case, not matching' => sub {
		my ( $got, $w );

		$w = warnings {
			use warnings;
			$got = no::warnings qr/^Illegal use of particle accelerator on a yacht/, sub {
				my $x = undef;
				my $y = 7;
				return $x + $y;
			};
		};
		
		is $got, 7;
		is $w, [ match qr/uninitialized value/ ] or diag Dumper( $w );
	};

	tests 'context (wantarray)' => sub {
		# void
		no::warnings sub {
			is wantarray, U();
			is wantarray, F();
		};
		# scalar
		my $x = no::warnings sub {
			is wantarray, D();
			is wantarray, F();
		};
		# list
		my @x = no::warnings sub {
			is wantarray, D();
			is wantarray, T();
		};
	};
};

done_testing;
