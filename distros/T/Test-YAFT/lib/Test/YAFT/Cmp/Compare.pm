
use v5.14;
use warnings;

package Test::YAFT::Cmp::Compare {
	use parent qw[ Test::Deep::Cmp ];

	sub init {
		my ($self, $operator, $value) = @_;

		$self->{operator} = $operator;
		$self->{val} = $value;
	}

	sub _val {
		$_[0]->{val};
	}

	sub _operator {
		$_[0]->{operator};
	}

	sub _render_value {
		my ($self, $value) = @_;

		Test::Deep::render_val ($value);
	}

	sub descend {
		my ($self, $got) = @_;
		my $operator = $self->_operator;
		my $expect   = $self->_val;

		my $result;
		my $status = eval "\$result = (\$got $operator \$expect); 1";
		warn $@ unless $status;

		return $result;
	}

	sub renderGot {
		my ($self, $got) = @_;

		$self->_render_value ($got);
	}

	sub renderExp {
		my ($self) = @_;

		$self->_operator . ' ' . $self->_render_value ($self->_val);
	}

	1;
}
$Test::YAFT::Cmp::Compare::VERSION = '1.0.2';;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Cmp::Compare - Comparator similar to Test::Builder::cmp_ok

=head1 SYNOPSIS

	Test::YAFT::Cmp::Compare->new ('>', $min)

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut

