package Text::NumericData::App::txdconstruct;

use Math::Trig;
use Text::NumericData;
use Text::NumericData::Calc qw(formula_function);
use Text::NumericData::App;

use strict;


#the infostring says it all
my $infostring = 'text data construction

I will produce some TextData following the formula you give me. Syntax is like that of txdcalc with only the STDOUT data; which means: You access the current data set via variables [1].. [x] (or [0,1]..[0,x] if you really want) and the global arrays A and C via A0..Ax and C0..Cx. You can initialze A and are encouraged to work with that array for custom operations. C has at the moment the only function to provide the data set number with C0 (set it to -1 to stop).
A data set is printed to STDOUT only when there is actually some data - so you can check for a condition in the formula and end the construction without creating a last futile line. You can, though, enable easy recursive calculation by initializing the data array (via --data parameter) in which case the data fields will always hold their last values when entering the formula.

Variables: A is for you, C is special: C0 is used for the data set number, C1 for the number of data sets to create, C2 for (C0-1)/(C1-1); (and maybe other stat stuff in C following in future...)

The formula can also be given as stand-alone command line argument (this overrides the other setting).

Example:

	txdconstruct -n=200 -i="0,1/3" "[1] += 1; [2] = 4*[2]*(1-[2]);"

gives a trajectory (some steps of iteration) for the logistic map.';

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
#		'header','','H','use this header (\n becomes an appropriate line end, end of string by itself)',
		 'formula','[1] = C0','f','specify formula here'
		,'vars','','v','initialize the additional variable array A (comma-separeted for eval)'
		,'debug',0,'D','give some info that may help debugging'
		,'number',10,'n','number of datasets to create (when < 0: until _you_ set C0 to -1)'
		,'init','','i','initialize data - comma-separated for eval... this enables easy recursive calculations by always preserving the last values'
		,'plainperl',0,'',
			'Use plain Perl syntax for formula for full force without confusing the intermediate parser.'
	);

	return $class->SUPER::new
	({
		 parconf=>{ info=>$infostring # default version
		# default author
		# default copyright
	}, pardef=>\@pars});
}

sub main
{
	my $self = shift;
	my $param = $self->{param};
	my $out = $self->{out};
	my $txd = Text::NumericData->new($self->{param});
	if(@{$self->{argv}}){ $param->{formula} = shift(@{$self->{argv}}); }
	my $ff = formula_function( $param->{formula},
	{
	  verbose=>$param->{debug}
	, plainperl=>$param->{plainperl}
	} );
	die "Cannot parse your formula, try --debug\n" unless defined $ff;

	my @C = (0, $param->{number}, 0);
	my @A = eval '('.$param->{vars}.')';

	# Dangerous ... change that!
	my $odata = eval '[('.$param->{init}.')]';
	my $recursive = @{$odata} ? 1 : 0;

	print $out ${$txd->data_line($odata)} if $recursive;

	while(++$C[0] and $param->{number} >= 0 ? $C[0] <= $param->{number} : 1)
	{
		my @data = $recursive ? ($odata) : ([]);
		$C[2] = $C[1] > 1 ? ($C[0]-1)/($C[1]-1) : 0;
		&$ff(\@data,\@A,\@C);
		print $out ${$txd->data_line($data[0])} if @{$data[0]};
		$odata = $data[0] if $recursive;
	}

	return 0;
}

1;

