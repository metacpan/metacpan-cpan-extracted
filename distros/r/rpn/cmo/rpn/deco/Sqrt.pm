package cmo::rpn::deco::Sqrt;

use Moose;

with 'cmo::rpn::deco::CalcDeco';

sub doMyEval {
	my ( $self, $token ) = @_;
	my $op1 = $token->pop();
	my $ans = sqrt $op1;
	$token->push($ans);
}

sub getOpSymbol {
	return "r";
}

sub getOpNum() {
	return 1;
}

sub toString(){
	return 'Sqrt';
}
