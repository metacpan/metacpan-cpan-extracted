package Test::Class::Tie::Parent;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;

#run prior and once per suite
sub startup : Test(startup => 1) {

	use_ok('Tie::Parent');

    return 1;
}

sub basic_use : Test(1) {
    my ($self) = @_;
	
	my $scalar;
	my $tied_scalar;

    ok(tie $tied_scalar, 'Tie::Parent', $scalar);

    return 1;
}

1;
