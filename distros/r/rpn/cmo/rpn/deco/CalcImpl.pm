package cmo::rpn::deco::CalcImpl;

use Moose;
with 'cmo::rpn::deco::ICalc';

sub evaluate {
	my ( $self, $token ) = @_;
	my $err = "This operator [" . $token->opSymbol() .
	  "] is not supported";
	die $err;
}

return 1;
