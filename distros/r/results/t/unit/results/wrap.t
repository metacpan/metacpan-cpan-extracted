=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<results::wrap>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'results::wrap';
use Test2::Tools::Spec;
use Data::Dumper;

use results ();

{
	package Local::Test;

	sub example {
		my ( $self, $success, @args ) = @_;
		$success
			? return( @args )
			: die( $args[0] );
	}
}

describe "method `AUTOLOAD`" => sub {

	tests 'it works' => sub {

		my $obj = bless {}, 'Local::Test';
		is( $obj->results::wrap::example( 1, 1234 )->unwrap(), 1234 );
		like( $obj->results::wrap::example( 0, 1234 )->unwrap_err(), qr/^1234/ );
	};
};

describe "function `results::wrap`" => sub {

	tests 'it works' => sub {

		my $obj = bless {}, 'Local::Test';
		is( $obj->results::wrap( example => 1, 1234 )->unwrap(), 1234 );
		like( $obj->results::wrap( example => 0, 1234 )->unwrap_err(), qr/^1234/ );
	};

	tests 'it works with a coderef' => sub {

		my $obj = bless {}, 'Local::Test';
		is( do {
			my $r = results::wrap { $obj->example( 1, 1234 ) };
			$r->unwrap();
		}, 1234 );
		like( do {
			my $r = results::wrap { $obj->example( 0, 1234 ) };
			$r->unwrap_err();
		}, qr/^1234/ );
	};
};

done_testing;
