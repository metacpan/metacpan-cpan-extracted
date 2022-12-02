=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<results::exceptions>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'results::exceptions';
use Test2::Tools::Spec;
use Data::Dumper;

describe "method `create_exception_class`" => sub {

	tests 'simple example' => sub {

		my $test = 'Local::Test1';
		$CLASS->create_exception_class( $test, 'Testing', {} );

		my $obj = $test->new;
		ok( $obj );
		isa_ok( $obj, $test );
		ok( $obj->DOES( $CLASS ) );
		is( $obj->err_kind, 'Testing' );
		is( "$obj", 'Testing' );

		my $err = $test->err;
		isa_ok( $err->unwrap_err(), $test );
	};

	tests 'complex example' => sub {

		my $test = 'Local::Test2';
		$CLASS->create_exception_class( $test, 'Testing2', {
			has        => [ qw/foo/ ],
			to_string  => sub { sprintf( '[[%s]]', shift->foo ) },
		} );

		my $obj = $test->new( foo => 1234 );
		ok( $obj );
		isa_ok( $obj, $test );
		ok( $obj->DOES( $CLASS ) );
		is( $obj->err_kind, 'Testing2' );
		is( "$obj", '[[1234]]' );
		is( $obj->foo, '1234' );

		my $err = $test->err( foo => 12345 );
		is( $err->unwrap_err()->foo, 12345 );
	};
};

describe "method `_exporter_fail`" => sub {

	tests 'disallowed example' => sub {
		my $e = dies {
			my @r = $CLASS->_exporter_fail( 'bad', {}, { into => __PACKAGE__ } );
		};
		like( $e, qr/Bad err_kind name/ );
	};

	tests 'good example' => sub {
		my @r = $CLASS->_exporter_fail( 'HelloWorld1234', {}, { into => __PACKAGE__ } );
		is( $r[0], 'HelloWorld1234' );
		is( $r[1]->(), 'main::Exception::HelloWorld1234' );
	};
};

done_testing;
