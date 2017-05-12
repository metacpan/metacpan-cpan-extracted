package Test::Proto::HashRef;
use 5.008;
use strict;
use warnings;
use Moo;
extends 'Test::Proto::Base';
with( 'Test::Proto::Role::Value', 'Test::Proto::Role::HashRef' );

=head1 NAME

Test::Proto::HashRef - Prototype with methods for hashrefs

=head1 SYNOPSIS

	use Test::Proto::HashRef;
	my $pHr = Test::Proto::HashRef->new();
	$pHr->enumerate(2, [['a','b'],['c','d']]);
	$pHr->ok({a=>'b', c=>'d'});

Use this class for validating hashes and hashrefs. If you have hashes, you must put them in a reference first.

=head1 METHODS

All methods are provided by L<Test::Proto::Base> or L<Test::Proto::Role::HashRef>.

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

1;
