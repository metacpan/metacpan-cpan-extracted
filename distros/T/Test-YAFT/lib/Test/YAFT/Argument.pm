
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Argument v1.0.3 {

	sub argument_name;
	sub set_argument;

	sub new {
		my ($class, $code) = @_;

		bless {
			code => $code,
		}, $class;
	}

	sub resolve {
		my ($self) = @_;

		$self->{code}->();
	}

	1;
}

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Argument - Internals behind block arguments

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut

