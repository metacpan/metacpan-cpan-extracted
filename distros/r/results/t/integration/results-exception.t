=pod

=encoding utf-8

=head1 PURPOSE

Integration tests for L<results::exceptions>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Local::Test;

use Test2::V0 -target => 'results::exceptions';
use Data::Dumper;

use results::exceptions (
	qw( Foo Bar ),
	FileNotFound => {
		has        => [qw/ filename /],
		to_string  => sub { sprintf("File '%s' not found", shift->filename) },
	},
	UnAuth => {
		has        => [qw/ username /],
		to_string  => 'Unauthorized',
	},
);

is( Foo, 'Local::Test::Exception::Foo' );
is( Bar, 'Local::Test::Exception::Bar' );

my $obj = Foo->new;
ok( $obj->isa('Local::Test::Exception::Foo') );
ok( $obj->DOES($CLASS) );
is( "$obj", 'Foo' );

my $obj2 = Foo->err->unwrap_err;
ok( $obj2->isa('Local::Test::Exception::Foo') );
ok( $obj2->DOES($CLASS) );

my $four04 = FileNotFound->err( filename => 'xyz.txt' )->unwrap_err;
is( $four04->filename, 'xyz.txt' );
is( "$four04", "File 'xyz.txt' not found" );

my $intruder = UnAuth->err( username => 'abc' )->unwrap_err;
is( $intruder->username, 'abc' );
is( "$intruder", 'Unauthorized' );

UnAuth->err->match(
	ok         => sub { fail() },
	err        => sub { fail() },
	err_UnAuth => sub { pass() },
);

done_testing;
