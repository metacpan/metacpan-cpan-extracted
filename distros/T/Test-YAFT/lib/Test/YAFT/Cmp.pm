
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Cmp v1.0.3 {
	use parent qw (Test::Deep::Cmp);

	require overload;
	require Safe::Isa;

	require Test::YAFT::Cmp::Complement;

	BEGIN {
		Test::Deep::Cmp->overload::OVERLOAD (
			q (+)   => \& Test::Deep::Cmp::make_all,
			q (-)   => \& _overload_binary_minus,
			q (!)   => \& _overload_complement,
			q (~)   => \& _overload_complement,
			q (neg) => \& _overload_complement,
		);
	}

	sub _create_complement {
		my ($self) = @_;

		return Test::YAFT::Cmp::Complement::->new ($self);
	}

	sub _overload_binary_minus {
		my ($lhs, $rhs, $swap) = @_;

		if ($swap) {
			$rhs = expect_value ($rhs);
			($lhs, $rhs) = ($rhs, $lhs);
		}

		return $lhs + ! $rhs;
	}

	sub _overload_complement {
		my ($expectation) = @_;

		my $builder = $expectation->can (q (_create_complement))
			// \ &_create_complement
			;

		$builder->($expectation);
	}

	sub init {
		my ($self, $val) = @_;

		$self->{val} = $val
			if @_ > 1
			;
	}

	sub _val {
		$_[0]->{val};
	}

	sub _render_value {
		my ($self, $value) = @_;

		Test::Deep::render_val ($value);
	}

	sub complementary {
		my ($self, @values) = @_;

		my $class = ref ($self) || $self;

		my $instance = $class->new (@values);
		$instance->{_complement} = $self->is_complement ? 0 : 1;

		return $instance;
	}

	sub descend {
		my ($self, $got) = @_;

		Test::Deep::descend ($got, $self->_val);
	}

	sub is_complement {
		my ($self) = @_;

		return $self->{_complement};
	}

	sub renderGot {
		my ($self, $got) = @_;

		$self->_render_value ($got);
	}

	sub renderExp {
		my ($self) = @_;

		$self->_render_value ($self->_val);
	}

	1;
};

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Test::Deep::Cmp - Intermediate class for single param comparators

=head1 SYNOPSIS

	package My::Comparator {
		use parent qw (Test::YAFT::Test::Deep::Cmp);

		sub descend {
			my ($self, $got) = @_;

			return $self->_val eq $got;
		}
	}

=head1 DESCRIPTION

Most of C<Test::Deep> comparators uses only single expected value so
little bit of abstraction saves few lines of code.

=head2 Constructor

	Comparator->new ('Foo')

=head2 Methods

=head3 _val

Returns expected value provided earlier to constructor

=head3 _render_value

Provides additional abstraction to rendering value allowing also C<$got> transformations.

In comparison to default L<Test::Deep::Cmp> implementation this approach allows
to write context expectations.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut

