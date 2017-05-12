#!perl

use constant HAS_STATE => eval q{ use feature 'state'; 1 };

use strict;
use Test::More tests => 15;
use Test::Warn;
use constant WARN_PAT => qr/Unused variable (?:my|state) [\$\@\%]\w+/;

BEGIN{
	# avoid unused warnings under Devel::Cover
	require Errno;
	require Tie::Handle;
}

use warnings::unused;
use warnings;

warning_like { eval q{ my $var; } } WARN_PAT, 'unused var';
warning_like { eval q{ my $var; $var++ } } [], 'used var';

warning_like{ eval q{ my $var; { my $var; $var++;}; } } WARN_PAT, 'shadowing';
warning_like{ eval q{ my $var; { my $var; $var++; $var++;}; } } WARN_PAT, 'shadowing (double reference)';

warning_like{ eval q{ my $var; return sub{ $var } } } [], 'closure';

warning_like { eval q{ my @ary; } } WARN_PAT, 'unused var';
warning_like { eval q{ my @ary; push @ary, 1 } } [], 'used var';


warning_like { eval q{ my %hash; } } WARN_PAT, 'unused hash ';
warning_like { eval q{ my %hash; $hash{hoge}++ } } [], 'used hash';

warning_like { eval q{
	my $foo;
	sub bar{
		my($self, $var) = @_;
		$var++;
	}
	$foo++;
}} WARN_PAT, 'in sub';

warning_like { eval q{
	
	my $foo;
	if($foo){
		my($x, $y);
		$y++;
	}
	my $bar;
	$bar++;
}} WARN_PAT, 'unused: deep scoped';

warning_like { eval q{
	
	my $foo;
	if($foo){
		my($x, $y);
		$x++;
		$y++;
	}
	my $bar;
	$bar++;
}} [], 'used: deep scoped';

warning_like { eval q{ our $var; } } [], 'our var';

SKIP:{
	skip q{use feature 'state'}, 1 unless HAS_STATE;
	warning_like { eval q{ use feature 'state'; state $var; } } WARN_PAT, 'unused state var';
}

warning_like {
	eval q{ no warnings 'once'; my $unused_but_not_complained; }
} [], 'unused but not complained';
