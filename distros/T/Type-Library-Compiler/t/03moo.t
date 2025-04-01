=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Library::Compiler works with Moo.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
do {
	package Local::Dummy;
	use Test::Requires 'Moo';
};

use FindBin '$Bin';
use lib "$Bin/lib";

{
	package Local::MyTest;
	use Moo;
	use TLC::Example ':Integer';
	has my_number => ( is => 'rw', isa => Integer );
}

ok lives {
	my $object = 'Local::MyTest'->new( my_number => 42 );
	is( $object->my_number, 42 );
	$object->my_number( 66 );
	is( $object->my_number, 66 );
};

{
	my $e = dies {
		'Local::MyTest'->new( my_number => 'Hello' );
	};
	like( $e, qr/Hello did not pass type constraint "Integer"/ );
}

{
	my $e = dies {
		my $object = 'Local::MyTest'->new( my_number => 42 );
		$object->my_number( "World" );
	};
	like( $e, qr/World did not pass type constraint "Integer"/ );
}

done_testing;
