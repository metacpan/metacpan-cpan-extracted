
use v5.14;
use warnings;

package Test::YAFT::Cmp::Complement;
$Test::YAFT::Cmp::Complement::VERSION = '1.0.1';
use parent 'Test::YAFT::Cmp';

require Test::Deep;
require overload;

require Safe::Isa;

BEGIN {
	Test::Deep::Cmp->overload::OVERLOAD (
		'!' => \& _build_isnt,
		'~' => \& _build_isnt,
	);
}

sub _build_isnt {
	my ($expect) = @_;

	return $expect->_val
		if $expect->$Safe::Isa::_isa (__PACKAGE__);

	__PACKAGE__->new ($expect);
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

	return "Different value than: " . $self->_val->renderExp;
}

1;
