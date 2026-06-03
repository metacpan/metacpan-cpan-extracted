
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Argument::Array v1.0.3 {
	use parent q (Test::YAFT::Argument);

	sub set_argument {
		my ($self, $arguments) = @_;

		push @{ $arguments->{$self->argument_name} //= [] }, $self;
	}

	1;
}

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Argument::Array - Internals behind block arguments

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut

