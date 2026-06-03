
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Argument::Arrange v1.0.3 {
	use parent q (Test::YAFT::Argument::Array);

	use mro;

	use Context::Singleton;

	use constant argument_name => q (arrange);

	sub resolve {
		my ($self) = @_;

		$self->{resolved} //= [ proclaim $self->next::method ];
	}

	sub DESTROY {
		my ($self) = @_;

		$self->resolve;
	}

	1;
};

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

