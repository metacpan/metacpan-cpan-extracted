package cmo::rpn::deco::MyStack;

use Moose;
use Data::Stack;

BEGIN {
	extends qw/Data::Stack/;
}

sub toString{
	my $self = shift();
	my $str = "";
	for(@{ $self }){
		$str = $_." ".$str;
	}
	return $str;
}

return 1;