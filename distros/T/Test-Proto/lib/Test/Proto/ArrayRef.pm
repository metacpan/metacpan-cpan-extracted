package Test::Proto::ArrayRef;
use 5.008;
use strict;
use warnings;
use Moo;
extends 'Test::Proto::Base';
with( 'Test::Proto::Role::Value', 'Test::Proto::Role::ArrayRef' );

=head1 NAME

Test::Proto::ArrayRef - Prototype with methods for arrayrefs

=head1 SYNOPSIS

	use Test::Proto::ArrayRef;
	my $pAr = Test::Proto::ArrayRef->new();
	$pAr->in_groups_of(2, [['a','b'],['c','d']]);
	$pAr->ok([qw(a b c d)]);

Use this class for validating arrays, arrayrefs and lists. If you have arrays or lists, you must put them in a reference first.

=head1 METHODS

All methods are provided by L<Test::Proto::Base> or L<Test::Proto::Role::ArrayRef>.

=head1 CAUTION

Remember that you are dealing with array references here:

	pArray->num_gt(1)->validate( [] )

will not test the number of elements, it will do 

	[] > 1

not 
	@{[]} > 1

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

1;
