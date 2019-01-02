=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Nano can be used with L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Requires 'Moo';
use Test::Fatal;

{
	package My::Class;
	use Moo;
	use Type::Nano qw( Int );
	has attr => (is => 'rw', isa => Int);
}

my $e1 = exception { My::Class->new(attr => undef) };

like $e1, qr/did not pass type constraint/;

my $obj = My::Class->new(attr => 1);
$obj->attr(2);

is $obj->attr, 2;

my $e2 = exception { $obj->attr('hello world') };

like $e2, qr/did not pass type constraint/;

done_testing;
