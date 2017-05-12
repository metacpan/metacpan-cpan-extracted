package
	Foo;

use strict;
use warnings;

my $a_unused = 42;
my $a;

sub f{
	{
		my $a_unused; # shadowing
		$a_unused++;

	}

	my @bar = (2);

	my %baz = (foo => 0);

	my %b_unused;

	if($baz{foo}++){
		my $c_unused = sub{ @bar };

	}

	open my $fh, '<', __FILE__;
	print while <$fh>;

	return my @d_unused = (10);
}


my $e_unused;

if($a){
	no warnings 'once';
	my $xyz; # unused but 'unused' is disabled
}


sub g{
	our $global_var;

	my $f_unused;

	{
		no warnings 'once';
		my $f_unused; # shadowing

		use warnings 'once';

		$f_unused++;
	}

=for TODO
	# XXX: not yet implemented

	my $obj = bless \do{ my $o }; # only declaration, but used
=cut
}

eval ' my $g_unused ';

1;
