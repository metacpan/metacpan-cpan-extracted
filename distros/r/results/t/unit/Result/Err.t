=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Result::Err>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'Result::Err';
use Test2::Tools::Spec;
use Data::Dumper;

use results ();

describe "class `$CLASS`" => sub {

	tests 'objects can be constructed' => sub {

		my $r = $CLASS->new();
		ok( $r->isa( $CLASS ), "isa $CLASS" );
		ok( $r->DOES( 'Result::Trait' ), "DOES Result::Trait" );

		$r->unwrap_err(); # avoid warning
	};
};

describe "method `_handled`" => sub {

	tests 'method works' => sub {

		my $r = $CLASS->new();
		ok( !$r->_handled, "false to start with" );
		$r->_handled( !!1 );
		ok( $r->_handled, "can be set to true" );
		$r->_handled( !!0 );
		ok( !$r->_handled, "can be set to false" );

		$r->unwrap_err(); # avoid warning
	};
};

describe "method `_peek_err`" => sub {

	tests 'method works' => sub {

		my $r = $CLASS->new( 5 .. 10 );
		is( scalar($r->_peek_err), 10, "in scalar context" );
		is( [$r->_peek_err], [5..10], "in list context" );
		is( do { $r->_peek_err; 1 }, 1, "in void context (doesn't throw)" );

		$r->unwrap_err(); # avoid warning
	};
};

describe "method `is_err`" => sub {

	tests 'method works' => sub {

		my $r = $CLASS->new();
		ok( $r->is_err, 'is true' );

		$r->unwrap_err(); # avoid warning
	};
};

describe "method `is_ok`" => sub {

	tests 'method works' => sub {

		my $r = $CLASS->new();
		ok( !$r->is_ok, 'is false' );

		$r->unwrap_err(); # avoid warning
	};
};

describe "method `unwrap`" => sub {

	tests 'method throws' => sub {

		my $r = $CLASS->new( 5 .. 10 );

		{
			my $e = dies {
				my $x = $r->unwrap;
			};
			like(
				$e,
				qr/^5678910/,
				'exception in scalar context',
			);
		}

		{
			my $e = dies {
				my @x = $r->unwrap;
			};
			like(
				$e,
				qr/^5678910/,
				'exception in list context',
			);
		}

		{
			my $e = dies {
				$r->unwrap; 1;
			};
			like(
				$e,
				qr/^5678910/,
				'exception in void context',
			);
		}
	};
};

describe "method `unwrap_err`" => sub {

	tests 'method works' => sub {

		my $r = $CLASS->new( 5 .. 10 );
		is( scalar($r->unwrap_err), 10, "in scalar context" );
		is( [$r->unwrap_err], [5..10], "in list context" );
		is( do { $r->unwrap_err; 1 }, 1, "in void context (doesn't throw)" );
	};
};

done_testing;
