
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Cmp::Complement v1.0.3 {
	use parent qw (Test::YAFT::Cmp);

	require Test::Deep;
	require overload;

	require Safe::Isa;

	sub _create_complement {
		my ($self) = @_;

		return $self->_val;
	}

	sub init {
		my ($self, $value) = @_;

		$value = Test::YAFT::Cmp->new ($value)
			unless $value->$Safe::Isa::_isa (Test::Deep::Cmp::);

		return $self->SUPER::init ($value);
	}

	sub descend {
		my ($self, $got) = @_;

		return ! $self->_val->descend ($got);
	}

	sub renderExp {
		my ($self) = @_;

		return q (Different value than: ) . $self->_val->renderExp;
	}

	sub __dump_yaft {
		my ($self, $dumper, $name) = @_;

		return $dumper->_dump ($self->_val, $name)
			=~ s (^ (?! [!])) ( )rx
			=~ s (^) (!)r
			;
	}

	1;
}
