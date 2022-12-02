=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Result::Trait>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'Result::Trait';
use Test2::Tools::Spec;
use Data::Dumper;

use results ();
use Type::Nano qw( HashRef ArrayRef Str );

describe "method `and`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( 2 );
			my $y = results::err( "late error" );
			is( $x->and( $y )->unwrap_err(), "late error" );
		}

		{
			my $x = results::err( "early error" );
			my $y = results::ok( "foo" );
			is( $x->and( $y )->unwrap_err(), "early error" );
			$y->unwrap();
		}

		{
			my $x = results::err( "not a 2" );
			my $y = results::err( "late error" );
			is( $x->and( $y )->unwrap_err(), "not a 2" );
			$y->unwrap_err();
		}

		{
			my $x = results::ok( 2 );
			my $y = results::ok( "different result type" );
			is( $x->and( $y )->unwrap(), "different result type" );
		}
	};
};

describe "method `and_then`" => sub {

	tests 'examples from Rust documentation' => sub {

		my $square = sub {
			my ( $x ) = @_;
			return results::err( "not a number" )
				unless $x =~ /^[0-9]+(\.[0-9]+)?/;
			return results::ok( $x * $x );
		};

		is( results::ok( 2 )->and_then( $square )->unwrap(), 4 );
		is( results::ok( "ok" )->and_then( $square )->unwrap_err(), "not a number" );
		is( results::err( "err" )->and_then( $square )->unwrap_err(), "err" );
	};
};

describe "method `err`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( 2 );
			is( $x->err(), undef );
		}

		{
			my $x = results::err( "nothing here" );
			is( $x->err(), "nothing here" );
		}
	};
};

describe "method `expect`" => sub {

	tests 'examples from Rust documentation' => sub {

		my $x = results::err( "emergency failure" );
		my $e = dies {
			$x->expect( "Testing expect" );
		};
		like $e, qr/Testing expect/;
	};

	tests 'further tests' => sub {
		my $x = results::ok( 42 );
		is( $x->expect( "Testing expect" ), 42 );
	};
};

describe "method `expect_err`" => sub {

	tests 'examples from Rust documentation' => sub {

		my $x = results::ok( 10 );
		my $e = dies {
			$x->expect_err( "Testing expect_err" );
		};
		like $e, qr/Testing expect_err/;
	};

	tests 'further tests' => sub {
		my $x = results::err( "emergency failure" );
		is( $x->expect_err( "Testing expect_err" ), "emergency failure" );
	};
};

describe "method `flatten`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( results::ok("hello") );
			is( $x->flatten()->unwrap(), "hello" );
		}

		{
			my $x = results::ok( results::err(6) );
			is( $x->flatten()->unwrap_err(), 6 );
		}

		{
			my $x = results::err(6);
			is( $x->flatten()->unwrap_err(), 6 );
		}
	};

	tests 'further tests' => sub {
		my $x = results::ok( 6 );
		my $e = dies { $x->flatten() };
		like $e, qr/Result did not contain a Result/;
	};
};

describe "method `inspect`" => sub {

	tests 'original tests' => sub {

		{
			my $got;
			my $x = results::ok( 99 );
			$x->inspect( sub { $got = $_ } );
			ok( !$x->_handled );
			is( $x->unwrap, 99 );
			is( $got, 99 );
		}

		{
			my $x = results::err( 99 );
			$x->inspect( sub { fail(); } );
			ok( !$x->_handled );
			is( $x->unwrap_err, 99 );
		}
	};
};

describe "method `inspect_err`" => sub {

	tests 'original tests' => sub {

		{
			my $x = results::ok( 99 );
			$x->inspect_err( sub { fail(); } );
			ok( !$x->_handled );
			is( $x->unwrap, 99 );
		}

		{
			my $got;
			my $x = results::err( 99 );
			$x->inspect_err( sub { $got = $_ } );
			ok( !$x->_handled );
			is( $x->unwrap_err, 99 );
			is( $got, 99 );
		}
	};
};

describe "method `is_err`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( -3 );
			ok( !$x->is_err() );

			ok( !$x->_handled );
			$x->unwrap();
		}

		{
			my $x = results::err( "Some error message" );
			ok( $x->is_err() );

			ok( !$x->_handled );
			$x->unwrap_err();
		}
	};
};

describe "method `is_ok`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( -3 );
			ok( $x->is_ok() );

			ok( !$x->_handled );
			$x->unwrap();
		}

		{
			my $x = results::err( "Some error message" );
			ok( !$x->is_ok() );

			ok( !$x->_handled );
			$x->unwrap_err();
		}
	};
};


describe "method `map`" => sub {

	tests 'original tests' => sub {

		my $map = sub { $_ * 2 };

		is( results::ok( 9 )->map( $map )->unwrap(), 18 );
		is( results::err( 9 )->map( $map )->unwrap_err(), 9 );
	};
};

describe "method `map_err`" => sub {

	tests 'original tests' => sub {

		my $map = sub { $_ * 2 };

		is( results::ok( 9 )->map_err( $map )->unwrap(), 9 );
		is( results::err( 9 )->map_err( $map )->unwrap_err(), 18 );
	};
};

describe "method `map_or`" => sub {

	tests 'original tests' => sub {

		my $map = sub { $_ * 2 };
		my $default = 42;

		is( results::ok( 9 )->map_or( $default, $map ), 18 );
		is( results::err( 9 )->map_or( $default, $map ), 42 );
	};
};

describe "method `map_or_else`" => sub {

	tests 'original tests' => sub {

		my $map = sub { $_ * 2 };
		my $default = sub { "[[$_]]" };

		is( results::ok( 9 )->map_or_else( $default, $map ), 18 );
		is( results::err( 9 )->map_or_else( $default, $map ), "[[9]]" );
	};
};

package Local::Foo {
	sub new {
		bless [], shift;
	}
	sub err_kind {
		'Foo';
	}
	sub DOES {
		1;
	}
	sub value {
		999;
	}
}

describe "method `match`" => sub {

	tests 'original tests' => sub {

		is(
			results::ok( 2 )->match(
				ok       => sub { 40 + $_ },
				err      => sub { fail() },
				err_Foo  => sub { fail() },
			),
			42,
		);

		is(
			results::err( 2 )->match(
				ok       => sub { fail() },
				err      => sub { 40 + $_ },
				err_Foo  => sub { fail() },
			),
			42,
		);

		is(
			results::err( 'Local::Foo'->new )->match(
				ok       => sub { fail() },
				err      => sub { fail() },
				err_Foo  => sub { $_->value },
			),
			999,
		);

	};
};

describe "method `ok`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( 2 );
			is( $x->ok(), 2 );
		}

		{
			my $x = results::err( "nothing here" );
			is( $x->ok(), undef );
		}
	};
};

describe "method `or`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok(2);
			my $y = results::err("late error");
			is( $x->or( $y )->unwrap, 2 );
			$y->unwrap_err;
		}

		{
			my $x = results::err("early error");
			my $y = results::ok(2);
			is( $x->or( $y )->unwrap, 2 );
		}

		{
			my $x = results::err("not a 2");
			my $y = results::err("late error");
			is( $x->or( $y )->unwrap_err, "late error" );
		}

		{
			my $x = results::ok(2);
			my $y = results::ok(100);
			is( $x->or( $y )->unwrap, 2 );
			$y->unwrap;
		}
	};
};

describe "method `or_else`" => sub {

	tests 'examples from Rust documentation' => sub {

		my $sq  = sub { results::ok( $_ ** 2 ) };
		my $err = sub { results::err( $_ ) };

		is( results::ok( 2 )->or_else( $sq )->or_else( $sq )->unwrap, 2 );
		is( results::ok( 2 )->or_else( $err )->or_else( $sq )->unwrap, 2 );
		is( results::err( 3 )->or_else( $sq )->or_else( $err )->unwrap, 9 );
		is( results::err( 3 )->or_else( $err )->or_else( $err )->unwrap_err, 3 );
	};
};

describe "method `type`" => sub {

	tests 'original tests' => sub {

		is( results::ok( "hello" )->type( Str )->unwrap, "hello" );

		like(
			results::ok( "hello" )->type( ArrayRef )->unwrap_err,
			qr/did not pass type constraint/,
		);
	};
};

describe "method `type_or`" => sub {

	tests 'original tests' => sub {

		is( results::ok( "hello" )->type_or( "world", Str )->unwrap, "hello" );

		is( results::ok( "hello" )->type_or( "world", ArrayRef )->unwrap, "world" );
	};
};

describe "method `type_or_else`" => sub {

	tests 'original tests' => sub {

		my $to_string = sub { results::ok( "$_" ) };

		is( results::ok( "hello" )->type_or_else( $to_string, Str )->unwrap, "hello" );

		like( results::ok( [] )->type_or_else( $to_string, Str )->unwrap, qr/^ARRAY\(\S+\)$/ );
	};
};

describe "method `unwrap`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( 2 );
			is( $x->unwrap(), 2 );
		}

		{
			my $x = results::err( "emergency failure" );
			my $e = dies {
				$x->unwrap();
			};
			like $e, qr/^emergency failure/;
		}
	};
};

describe "method `unwrap_err`" => sub {

	tests 'examples from Rust documentation' => sub {

		{
			my $x = results::ok( 2 );
			my $e = dies {
				$x->unwrap_err();
			};
			like $e, qr/^2/;
		}

		{
			my $x = results::err( "emergency failure" );
			is( $x->unwrap_err(), "emergency failure" );
		}
	};
};

describe "method `unwrap_or`" => sub {

	tests 'examples from Rust documentation' => sub {

		my $default = 2;

		{
			my $x = results::ok( 9 );
			is( $x->unwrap_or( $default ), 9 );
		}

		{
			my $x = results::err( "error" );
			is( $x->unwrap_or( $default ), $default );
		}
	};
};

describe "method `unwrap_or_else`" => sub {

	tests 'examples from Rust documentation' => sub {

		my $count = sub { length($_) };

		is( results::ok( 2 )->unwrap_or_else( $count ), 2 );
		is( results::err( "foo" )->unwrap_or_else( $count ), 3 );
	};
};

describe "method `DESTROY`" => sub {

	tests 'original tests' => sub {

		{
			my $x = results::ok(2);
			my $e = dies { $x->DESTROY };
			like $e, qr/^ok\(2\) went out of scope/;
		}

		{
			my $x = results::err(2);
			my $e = dies { $x->DESTROY };
			like $e, qr/^err\(2\) went out of scope/;
		}
	};
};

done_testing;
