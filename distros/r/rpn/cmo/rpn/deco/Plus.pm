package cmo::rpn::deco::Plus;

use Moose;

with 'cmo::rpn::deco::CalcDeco';

sub doMyEval {
	my ( $self, $token ) = @_;
	my $op2 = $token->pop();
	my $op1 = $token->pop();
	my $ans = $op1 + $op2;
	$token->push($ans);
}

sub getOpSymbol {
	return "+";
}

sub getOpNum() {
	return 2;
}

sub toString(){
	return 'Plus';
}
