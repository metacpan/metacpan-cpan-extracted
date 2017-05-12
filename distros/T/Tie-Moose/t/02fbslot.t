=head1 PURPOSE

Test L<Tie::Moose::FallbackSlot>.

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
	has fb  => (is => 'rw', default => sub { +{} });
	__PACKAGE__->meta->make_immutable;
	no Moose;
}

my $object = Loose->new(bar => 123, baz => 456);
tie my %hash, "Tie::Moose"->with_traits("FallbackSlot"), $object, fallback => "fb";

is($hash{foo}, undef);
is($hash{bar}, 123);
is($hash{baz}, 456);

is( exception { $hash{foo} = 789 }, undef );
like( exception { $hash{bar} = 789 }, qr{^No writer for attribute 'bar' in tied object} );

like( exception { delete $hash{foo} }, qr{^No clearer for attribute 'foo' in tied object} );
like( exception { delete $hash{bar} }, qr{^No clearer for attribute 'bar' in tied object} );
is( exception { delete $hash{baz} }, undef );

is( exception { $hash{xyz} = 999 }, undef );

is($object->fb->{xyz}, 999);

is( exception { delete $hash{xyz} }, undef );

ok(!exists $object->fb->{xyz});

$object->fb([]);

like(
	exception { my $xyz = $hash{xyz} },
	qr{^Value of tied object's 'fb' attribute is not hashref-like},
);

done_testing;
