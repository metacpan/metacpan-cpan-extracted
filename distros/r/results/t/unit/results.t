=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<results>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $ENV{PERL_STRICT} = 1 };

use Test2::V0 -target => 'results';
use Test2::Tools::Spec;
use Data::Dumper;

use results ();

describe "function `err`" => sub {

	tests 'it returns a result which is_err()' => sub {
	
		my $r = results::err( 42 );
		ok( $r->is_err() );
		my $dummy = $r->unwrap_err();
	};
};

package Local::Foo1 { sub DOES { 0; } };
package Local::Foo2 { sub DOES { 1; } };

describe "function `is_result`" => sub {

	tests 'it correctly identifies objects which do the Result::Trait role' => sub {

		ok !results::is_result( undef );
		ok !results::is_result( {} );
		ok !results::is_result( bless {}, 'Local::Foo1' );
		ok  results::is_result( bless {}, 'Local::Foo2' );
	};
};

describe "function `ok`" => sub {

	tests 'it returns a result which is_ok()' => sub {
	
		my $r = results::ok( 42 );
		ok( $r->is_ok() );
		my $dummy = $r->unwrap();
	};
};

describe "function `ok_list`" => sub {

	tests 'it returns a result which is_ok()' => sub {
	
		my $r = results::ok_list( 42 );
		ok( $r->is_ok() );
		my @dummy = $r->unwrap();
	};
};

sub foobar : Result {
	my $in = shift;
	if ( $in > 0 ) {
		return results::ok( $in );
	}
	if ( $in < 0 ) {
		return results::err( $in );
	}
	return 0;  # BAD
}

describe "attribute `:Result`" => sub {

	tests 'it works' => sub {

		is( foobar(2)->unwrap, 2 );
		is( foobar(-3)->unwrap_err, -3 );

		my $e = dies { foobar(0) };
		like( $e, qr/^Function 'foobar' declared to return a Result, but returned: 0/ );
	};
};

done_testing;
