#!perl
package
	Foo;
use strict;
use warnings;
#use 5.10.0;

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 0 unless defined $ENV{PERL_MACRO_DEBUG} }

use macro say => sub{ print @_, "\n" };

{
	use macro
		mul => sub{ $_[0] * $_[1] },
		foo => sub{ 'macro(1)' },
		;

	my $hello = 'Hello, world';
	my $excr  = '!';
	say( ($hello), do{$excr}, );

	say(q{mul(1+2, 3+4) = }, mul( 1+2, 3+4 ));

	say('Which is called, subroutine or macro? -> ', foo());
}

sub foo{
	'subroutine';
}


say('Which is called, subroutine or macro? -> ', foo());

{
	use macro foo => sub{ 'macro(2)' };

	say('Which is called, subroutine or macro? -> ', foo());
}
