
use v5.14;
use warnings;

package Test::YAFT::Cmp {
	use parent qw[ Test::Deep::Cmp ];

	sub init {
		my ($self, $val) = @_;

		$self->{val} = $val;
	}

	sub _val {
		$_[0]->{val};
	}

	sub _render_value {
		my ($self, $value) = @_;

		Test::Deep::render_val ($value);
	}

	sub descend {
		my ($self, $got) = @_;

		Test::Deep::descend ($got, $self->_val);
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
}
$Test::YAFT::Cmp::VERSION = '1.0.2';;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Test::Deep::Cmp - Intermediate class for single param comparators

=head1 SYNOPSIS

	package My::Comparator {
		use parent qw[ Test::YAFT::Test::Deep::Cmp ];

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

