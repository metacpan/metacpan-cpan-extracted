=head1 PURPOSE

Test L<Tie::Moose::ReadOnly>.

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
tie my %hash, "Tie::Moose"->with_traits("ReadOnly"), $object;

is($hash{foo}, undef);
is($hash{bar}, 123);
is($hash{baz}, 456);

my $E = qr{^Read-only tied hash};

like( exception { $hash{foo} = 789 }, $E );
like( exception { $hash{bar} = 789 }, $E );

like( exception { delete $hash{foo} }, $E );
like( exception { delete $hash{bar} }, $E );
like( exception { delete $hash{baz} }, $E );

like( exception { $hash{xyz} = 999 }, $E );

done_testing;
