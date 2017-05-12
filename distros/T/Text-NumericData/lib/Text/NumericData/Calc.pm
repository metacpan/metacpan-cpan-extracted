package Text::NumericData::Calc;

use Math::Trig;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(linear_value parsed_formula formula_function expression_function);

our $epsilon = 1e-15;

#a hack for gauss() function to use in formulae
#not fully verified yet  - and not normalized!
our $cache = undef;
sub gauss
{
	#Polar-Methode
	my $x;
	if(defined $cache)
	{
		$x = $cache;
		undef $cache;
	}
	else
	{
		my ($u1,$u2,$v);
		do
		{
			$u1 = rand();
			$u2 = rand();
			$v = (2*$u1-1)**2+(2*$u2-1)**2;
		}
		while($v >= 1);
		$cache = (2*$u2-1)*sqrt(-2*log($v)/$v);
		$x = (2*$u1-1)*sqrt(-2*log($v)/$v);
	}
	return $x;
}

# helper for floating point comparisons
sub near
{
	my ($a, $b, $eps) = @_;
	$eps = $epsilon unless defined $eps;

	return (abs($a-$b) < $eps);
}


#linear_value(x,[x1,x2],[y1,y2])
sub linear_value
{
	my ($x,$ox,$oy) = @_;
	return $ox->[0] != $ox->[1] ? ( $oy->[0] + ($oy->[1]-$oy->[0])*($x-$ox->[0])/($ox->[1]-$ox->[0]) ) : ( $x == $ox->[0] ? ($oy->[0]+$oy->[1])/2 : undef );
}

#parsed_formula(text, dataarrayname, pararrayname1, pararrayname2)
#A -> pararray1
#C -> pararray2
#[a,b] -> data[a][b]

sub parsed_formula
{
	my ($form, $data, $par1, $par2) = @_;
	my @formlines = split("\n", $form);
	my $nnf = '';

	foreach my $formula (@formlines)
	{
		my $nf = '';
		#$ord$ord is not translated correctly but is not correct syntax anyway
		{ # Parse shortcut vars.
			my %defs =
			(
				 'x',   '[0,1]'
				,'y',   '[0,2]'
				,'z',   '[0,3]'
			);
			#print STDERR "shortcut parsing: $formula\n";
			while($formula =~ /^(.*)([^a-zA-Z\$]|^)(\$?([xab]|ord))([^(a-zA-Z]|$)(.*)$/m)
			{
				#print STDERR "found $4 (def=$defs{$4})\n";
				$formula = $1.$2.$defs{$4}.$5.$6;
			}
			#print STDERR "done shortcut parsing: $formula\n";
		}
		# Match any relevant [...] and stuff before it; parse and cut from formula.
		#print STDERR "formula: $formula\n";
		while($formula =~ s/\A([^[]*[^[a-zA-Z]|)\[\s*(([^[\],]+)(\s*,\s*([^[\],]+)|)\s*)\s*\]//)
		{
			#print STDERR "results: $1 : $2 : $3 : $4 : $5\n";
			#print STDERR "formula: $formula\n";
			$nf .= $1;
			my $num1 = $3;
			my $num2 = $5;
			unless(defined $num2)
			{
				$num2 = $num1;
				$num1 = 0;
			}
			if(($num1 =~ /^\d+$/) and ($num1 < 0))
			{
				print STDERR "File index $num1 < 0 !\n";
				return undef;
			}
			if($num2 =~ /^\d+$/)
			{
				--$num2;
				if($num2 < 0)
				{
					print STDERR "Dataset index $num2 < 0 !\n";
					return undef;
				}
			}
			else{ $num2 = "($num2)-1"; }
			$nf .= '$'.$data."[$num1][$num2]";		
			#print STDERR "nf:      $nf\n";
		}

		$nf .= $formula;
		$nf =~ s/(^|[^\$a-zA-Z])A(\d+)/$1\$$par1\[$2\]/g;	
		$nf =~ s/(^|[^\$a-zA-Z])C(\d+)/$1\$$par2\[$2\]/g;
		if($nnf ne ''){ $nnf .= "\n"; }
		$nnf .= $nf;
	}
	return $nnf;
}

#(formula [, config])
sub formula_function
{
	my ($formula,$cfg) = @_;
	my $config = defined $cfg
		? $cfg
		: {verbose=>0, plainperl=>0};
	my $pf = $config->{plainperl}
		? $formula
		: parsed_formula($formula, 'fd->', 'A->', 'C->');
	unless(defined $pf)
	{
		$@ = "Text::NumericData::Calc: Error parsing the formula!";
		return undef;
	}
	my $ffc = 'sub { my ($fd, $A, $C) = @_; '.$pf.' ; return 0; }';
	if(defined $config->{verbose})
	{
		print STDERR "Formula code: ".$pf."\n"
			if $config->{verbose};
		print STDERR "Formula function code: ".$ffc."\n"
			if $config->{verbose} > 1;
	}
	return eval $ffc;
}

# same as above, code differs in that it returns the expression indicated by formula
sub expression_function
{
	my ($formula,$verb) = @_;
	my $pf = parsed_formula($formula, 'fd->', 'A->', 'C->');
	unless(defined $pf)
	{
		$@ = "Text::NumericData::Calc: Error parsing the formula!";
		return undef;
	}
	print STDERR "Formula code: ",$pf,"\n" if $verb;
	return eval 'sub { my ($fd, $A, $C) = @_; return '.$pf.' ; }';
}

1;
__END__

=head1 NAME

Text::NumericData::Calc -  helper package for some calculations

=head1 SYNOPSIS

	use Text::NumericData::Calc qw(linear_value formula_function);
		
	#inter- or extrapolation with known data points ($x1,$y1) and ($x2,$y2)
	$y = linear_value($x,[$x1,$x2],[$y1,$y2]);
	my $ff = formula_function($textualformula);
	my $value = &$ff(\@datasets);

or, using plain Perl syntax in formula,

	my $ff = formula_function($perlformula, {plainperl=>1});

and with verbosity to print the parsed formula

	my $ff = formula_function($perlformula, {verbose=>1});

=head1 DESCRIPTION

This is a little library for Text::NumericData; it contains routines that in fact are too general to strictly belong to Text::NumericData... but here they are.

=head2 Functions

=over 4

=item * linear_value($x,[$x1,$x2],[$y1,$y2]) -> $y

does simple linear inter-/extrapolation of the $y for a given $x based on two known points. It is needed by the Text::NumericData::File class for, well, interpolation.

=item * formula_function($formula,$plainperl) -> \&function

This takes some formula as text and constructs a function that evaluates this formula. The created function takes three arrays (references) as arguments: A two-dimensional array and two one-dimensional arrays with some data needed for calculation.

A shortcut syntax is provided to be able to quickly write simple formulae
without too much noise around it. [n] maps to the value of column n, the first
being column 1. [m,n] maps to column n in file m, file 0 being the primary data
set, file 1 the first auxilliary one.
The extra one-dimensional arrays are accessed via Ci for $C->[i] and Ai for
$A->[i].

In short, the formula

	[2]*=[1,2] + C0; A0+=[2]

is equivalent to

	$fd->[0][1]*=$fd->[1][1] + $C->[0]; $A->[0]+=$fd->[0][1]

in plain Perl, with $fd referring to the value matrix and @{$C} for the
constants, @{$A} for the auxilliary values.

Perhaps now you understand why I wanted to abbreviate things to make
this workable for shell one-liners. You are always free to write your
formula in plain Perl using the indicated variables when setting the second
argument to some true value. Generally, the simplified syntax works well for
quick one-liners.

There are further shortcuts that translate barewords to data array entries,
x for[1], y for [2] and z for [3].

Note that there are no real boundaries to what the generated routine may do.
It is implied that you can trust the user input. Think twice before including
this functionality unguarded in public web service! You should only
allow preconstructed verified input in such a case. But, well, what am I
talking about in the age of SQL injection ...

Limiting the scope of operations in the formula to enforce security is not
really an option. It would loose functionality. Just think about loops.

=item * parsed_formula($formula, $dataname, $par1name, $par2name) -> $perl_code

is the parser for the $formula that just replaces the different short forms for data and constants with proper PERL code using the last three parameters for the array names. It's used internally by formula_function. If you really want to use it explicitly, then it shouldn't be hard to figure the usage out by looking at the source of formula_function.

=back

=head1 TODO

I'd like to add shortcuts for Fortran-like array operations.

	[2:] += 1

to increment all columns from the second one,

	[2:] *= [1,2:]

to multiply all corresponding columns with factors in second data set (matrix
row). This needs more smarts in making things match up. For now, you have to
either resort to plain Perl (in case Perl's array syntax does the trick) or
something like

	for $i (0..4){ [$i] = 2 }

wich translates to

	for $i (0..4){ $fd->[0][($i)-1] = 2 }

When you want to do complicated things, the full power of Perl is at your
disposal. You're not really afraid of sigils, are you?

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2012, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.
