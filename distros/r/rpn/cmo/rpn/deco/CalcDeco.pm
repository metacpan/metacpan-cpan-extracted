package cmo::rpn::deco::CalcDeco;

use Moose::Role;
with 'cmo::rpn::deco::ICalc';

requires 'getOpSymbol';
requires 'doMyEval';
requires 'getOpNum';
requires 'toString';

has 'calc' => (
	is  => 'rw',
	isa => 'cmo::rpn::deco::ICalc',
);

sub evaluate {
	my ( $self, $token ) = @_;
	if ( $token->opSymbol() eq $self->getOpSymbol() ) {
		if ( $token->size() < $self->getOpNum() ) {
			my $errstr =
			    "The number of operand "
			  . "is not enough ["
			  . $self->toString()
			  . "]";
			die $errstr;#Exception->new($errstr);
		}
		$self->doMyEval($token);
		return;
	}
	$self->calc->evaluate($token);
}

return 1;
