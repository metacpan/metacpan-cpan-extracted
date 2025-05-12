
use v5.14;
use warnings;

use Syntax::Construct 'package-block';

package Test::YAFT::Arrange {
	use Context::Singleton;

	sub new {
		my ($class, $code) = @_;

		bless {
			code => $code,
			resolved => 0,
		}, $class;
	}

	sub resolve {
		my ($self) = @_;

		return if $self->{resolved};

		$self->{resolved} = 1;
		proclaim $self->{code}->();
	}

	sub DESTROY {
		my ($self) = @_;

		$self->resolve;
	}

	1;
}
$Test::YAFT::Arrange::VERSION = '1.0.2';;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Arrange - Internals under arrange { } block

=head1 SYNOPSIS

	use Test::YAFT;

	arrange { foo => 'bar' };

	it "should ..."
		=> arrange { foo => 'bar2' }
		=> got { ... how to build test value ... }
		=> throws => 'My::Project::X::Something::Went::Wrong',
		;

=head1 DESCRIPTION

Block is evaluated in list context and its result value
is passed to L<Context::Singleton/proclaim>.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut

