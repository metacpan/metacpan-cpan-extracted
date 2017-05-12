=head1 PURPOSE

Test L<Tie::Moose::FallbackHash>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;

use Tie::Moose;

{
	package Loose;
	use Moose;
	has foo => (is => 'rw');
	has bar => (is => 'ro');
	has baz => (is => 'rw', clearer => '_clear_baz');
	has fb  => (is => 'ro', default => sub { +{} });
	__PACKAGE__->meta->make_immutable;
	no Moose;
}

my %fb;
my $object = Loose->new(bar => 123, baz => 456);
tie my %hash, "Tie::Moose"->with_traits("FallbackHash"), $object, fallback => \%fb;

is($hash{foo}, undef);
is($hash{bar}, 123);
is($hash{baz}, 456);

is( exception { $hash{foo} = 789 }, undef );
like( exception { $hash{bar} = 789 }, qr{^No writer for attribute 'bar' in tied object} );

like( exception { delete $hash{foo} }, qr{^No clearer for attribute 'foo' in tied object} );
like( exception { delete $hash{bar} }, qr{^No clearer for attribute 'bar' in tied object} );
is( exception { delete $hash{baz} }, undef );

is( exception { $hash{xyz} = 999 }, undef );

is($fb{xyz}, 999);

is( exception { delete $hash{xyz} }, undef );

ok(!exists $fb{xyz});

like(
	exception { tie my %hash, "Tie::Moose"->with_traits("FallbackHash"), $object, fallback => [] },
	qr{not pass the type constraint},
);

done_testing;
