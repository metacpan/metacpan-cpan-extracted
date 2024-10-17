use strict;
use warnings;

package Test::Deep::PDL;
$Test::Deep::PDL::VERSION = '0.21';
# ABSTRACT: Test ndarrays inside data structures with Test::Deep


use Test::Deep::Cmp;
require Test::PDL;


sub init
{
	my $self = shift;
	my $expected = shift;
	die "Supplied value is not an ndarray" unless eval { $expected->isa('PDL') };
	$self->{expected} = $expected;
}

sub descend
{
	my $self = shift;
	my $got = shift;
	( my $ok, $self->data->{diag} ) = Test::PDL::eq_pdl( $got, $self->{expected} );
	return $ok;
}

sub diag_message
{
	my $self = shift;
	my $where = shift;
	return "Comparing $where as an ndarray:\n" . $self->data->{diag};
}

sub renderExp
{
	my $self = shift;
	return $self->renderGot( $self->{expected} );
}

sub renderGot
{
	my $self = shift;
	my $val = shift;
	my $fmt = '%-8T %-12D (%-5S) ';
	return eval { $val->isa('PDL') } ? ($val->info($fmt) . $val) : ("(" . Test::Deep::render_val($val) . ")");
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::PDL - Test ndarrays inside data structures with Test::Deep

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This is just an implementation class. Look at the documentation for test_pdl()
in L<Test::PDL>.

=for Pod::Coverage init descend diag_message renderExp renderGot

=head1 BUGS

The implementation of this class depends on undocumented subroutines in
L<Test::Deep>. This may break if L<Test::Deep> gets refactored.

=head1 SEE ALSO

L<PDL>, L<Test::PDL>, L<Test::Deep>

=head1 AUTHOR

Edward Baudrez <ebaudrez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Edward Baudrez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
