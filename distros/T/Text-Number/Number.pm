package Text::Number;

# Copyright 1999 Eric Fixler <fix@fixler.com>
# All rights reserved. This program is free software; 
# you can redistribute it and/or modify it under the same terms as Perl itself. 

# $Id: Number.pm,v 1.3 1999/09/07 04:56:26 fix Exp fix $
# $Source: /www/cgi/lib/Text/RCS/Number.pm,v $

=pod

=head1 NAME

Text::Number - Overloaded class for printing numbers

=head1 SYNOPSIS

Provides a facility for transparently configuring numbers to print the
way you want them to.  Calculations are always executed using the full
precision of the number, but printing is rounded to the number of places
of your choosing.  

Extended printing operations are configurable via the C<format> method.

=head1 DESCRIPTION

C<use Text::Number;>

C<$allowance = number(value =E<gt> 5, places =E<gt> 2)>;

C<print STDOUT "My allowance is $allowance dollars."> 

E<gt> My allowance is 5.00 dollars.

C<require Text::Number;>

C<$allowance = Text::Number->new(value =E<gt> 5, places =E<gt> 2)>;

C<$allowance += 5000; print "$allowance";>

E<gt> 5005.00

C<$allowance-E<gt>format(type =E<gt> 'number'); print "$allowance";>

E<gt> 5,005.00

=head1 EXPORTS

If you import C<Text::Number> with the <use> statement, the C<number> constructor
will be imported into your namespace.  If you'd rather not import this symbol,
C<require Text::Number> instead and use either C<new Text::Number> or C<Text::Number-E<gt>number>
as your constructor. 

=head1 OPERATORS

Objects created by this module should function transparently with these operators:

C<+ - / * "" x ** ++ += -- -= *= /= E<lt> E<gt> E<lt>= E<gt>= E<lt>=E<gt>> 

abs atan2 cos exp log sin sqrt

=head1 METHODS

=cut

sub BEGIN {
	*{__PACKAGE__.'::new'} 	= \&number;
	use strict; # delayed strict so we could do the method aliasing
	use vars qw(@ISA @EXPORT $VERSION @ATTRIBUTES $POSIX $FORMATTER $DEBUG);
	$VERSION = 0.80;
	use Exporter;
	@ISA 	= 	qw(Exporter);
	@EXPORT	=	qw(number);
	eval { require POSIX; POSIX->import( qw(:ctype_h INT_MAX) ) };
	$POSIX = ($@) ? 0 : 1;
	use constant	VALUE			=> 	0;
	use constant	PLACES			=>	1;
	use constant	FORMAT			=>	2;
	use constant	FORMAT_TYPE		=> 	3;
	use constant	FORMAT_TEMPLATE	=> 	4;
	use constant	FORMAT_SUB		=> 	5;
	$DEBUG = 1;
	@ATTRIBUTES = qw(value places format format_type format_template format_sub);
	use overload (	'+' 	=> \&add,
					'-'		=> \&subtract,
					'*'		=> \&multiply,
					'/'		=> \&divide,
					'**'	=> \&power,
					'<=>'	=> \&spaceship,
					'0+'	=> \&value,
					'x'		=> \&repeat,
					'""'	=> \&as_string,
					'atan2'	=> \&_atan2,
					'cos'	=> \&_cos,
					'sin'	=> \&_sin,
					'exp'	=> \&_exp,
					'abs'	=> \&_abs,
					'log'	=> \&_log,
					'sqrt'	=> \&_sqrt, );
}

sub number {
=pod

=head2 C<new> (synonymous with C<number>)
	

C<$number = number(6);> (only if you C<use>d)

C<$number = new Text::Number(value =E<gt> 6, places =E<gt> 0)>

C<$number = Text::Number-E<gt>number(6)>

=cut
	my $class = ref($_[0]) || ($_[0] =~ /(.*?::.*)/)[0];
	$parent = $class ? shift(@_) : undef ; $class ||= __PACKAGE__ ;
	(@_ == 1) and unshift(@_,'value');
	my $params;
	if (ref($parent)) {
			$params = { value			=> 	$parent->[VALUE],
						places			=> 	$parent->[PLACES],
						format			=>	$parent->[FORMAT],
						format_template	=>	$parent->[FORMAT_TEMPLATE],
						format_sub		=>	$parent->[FORMAT_SUB],
						@_ };
	} else {$params	= {	value 	=> 0,
						places	=> 0,
						format	=> undef,
						format_template => undef,
						@_ };
	};
	my $self = [@$params{@ATTRIBUTES}];
	bless($self,$class);
	if ($self->[FORMAT]) {
		if (not(ref($parent))) { # processing command line args
			$self->format(type => $self->[FORMAT], template => $self->[FORMAT_TEMPLATE]);
		};
	};
	return $self;
}

sub places {
=pod

=head2 places

Returns the display precision of the number.

C<$precision = $number-E<gt>places>

=cut
 	my $self = shift(@_);
	return 0 unless (ref($self));
	(@_) and $self->[PLACES] = shift(@_);
	return $self->[PLACES];
}

sub value {
=pod

=head2 value

Returns the real value of the number.

C<$value = $number-E<gt>value>

=cut
	my $self = shift(@_);
	if (ref($self)) {
		(@_) and $self->[VALUE] = $_[0]; return $self->[VALUE];
	} else { return $self; };
}


sub add {
	my ($number_1, $number_2, $inverted) = @_;
	$DEBUG and $inverted and print "Addition inverted\n";
	# sneaky way of calling value so it works with of without objects
	my $value = value($number_1) + value($number_2);
	my $parent = (ref($number_1)) ? $number_1 : $number_2;
	my $result = $parent->new(value => $value, places => _max(places($number_1),places($number_2)));
	return $result;
}

sub subtract {
	my ($number_1, $number_2, $inverted) = @_;
	$DEBUG and $inverted and print "Subtraction inverted\n";
	my $value = $inverted 	?  value($number_2) - value($number_1)
							:  value($number_1) - value($number_2);
	my $parent = (ref($number_1)) ? $number_1 : $number_2;
	my $result = $parent->new(value => $value, places => _max(places($number_1),places($number_2)));
	return $result;
}

sub multiply {
	my ($number_1, $number_2, $inverted) = @_;
	$DEBUG and print "Multiply $number_1 $number_2 $inverted\n";
	$DEBUG and $inverted and print "Multiplication inverted\n";
	my $value = value($number_2) * value($number_1);
	my $parent = (ref($number_1)) ? $number_1 : $number_2;
	my $result = $parent->new(value => $value, places => _max(places($number_1),places($number_2)));
	return $result;
}


sub divide {
	my ($number_1, $number_2, $inverted) = @_;
	$DEBUG and $inverted and print "division inverted\n";
	my ($value);
	eval { $value = $inverted 	? value($number_2)/value($number_1)
								: value($number_1)/value($number_2); };
	$value = INT_MAX if ($@);
	my $parent = (ref($number_1)) ? $number_1 : $number_2;
	my $result = $parent->new(value => $value, places => _max(places($number_1),places($number_2)));
	return $result;
}


sub power {
	my ($number_1, $number_2, $inverted) = @_;
	$DEBUG and $inverted and print "power inverted\n";
	my ($value);
	$value = $inverted 	? value($number_2) ** value($number_1)
						: value($number_1) ** value($number_2); 
	my $parent = (ref($number_1)) ? $number_1 : $number_2;
	my $result = $parent->new(value => $value, places => _max(places($number_1),places($number_2)));
	return $result;
}


sub spaceship {
	my ($number_1, $number_2, $inverted) = @_;
	return $inverted ? value($number_2) <=> value($number_1)
					 : value($number_1) <=> value($number_2);
}

sub as_string {
	my $self = shift(@_);
	# my $string = sprintf("%.*f",$self->[PLACES],$self->[VALUE]);
	return $self->[FORMAT] 	? &{$self->[FORMAT_SUB]}($self->[VALUE],$self->[PLACES],1) 
							: sprintf("%.*f",$self->[PLACES],$self->[VALUE]);
}

sub repeat {
	# You lose the object here, because it's NaN
	my ($number_1, $number_2, $inverted) = @_;
	return $inverted ? "$number_2" x value($number_1) : "$number_1"  x value($number_2);

}

sub _atan2 {
	my ($result);
	eval { $result = atan2(value($_[0]),value($_[1])); };
	return $@ ? '' : $_[0]->new(value => $result);
}

sub _cos {
	return $_[0]->new(value => cos(value($_[0])));
}

sub _sin {
	return $_[0]->new(value => sin(value($_[0])) );
}

sub _exp {
	return $_[0]->new(value => exp(value($_[0])) );
}

sub _abs {
	return $_[0]->new(value => abs(value($_[0])));
}

sub _log {
	my ($result);
	eval { $result = log(value($_[0])); };
	return $@ ? '' : $_[0]->new(value => $result); 
}

sub _sqrt {
	my ($result);
	eval { $result = sqrt(value($_[0])); };
	return $@ ? '' : $_[0]->new(value => sqrt(value($_[0])) );
}

sub format {
=pod

=head2 format

Use this method to configure the number for more sophisticated printing option, i.e.,
anything other than plain old decimal point control.  If you invoke this method, you
need to have Number::Format installed on your system, as this module is used to
generate the formats.  The module is only loaded at runtime so Text::Number will work
without it, except you won't have access to these formatting options.

Number::Format is a very useful and feature-rich module.  Please see the pod for
that module for a better description of it capabilities.

C<$success = $number-E<gt>format(type =E<gt> number)> inserts commas, or the local
equivalent, into numbers E<gt> 1000.  It can also insert the localized decimal point 
character.

C<$success = $number-E<gt>format(type =E<gt> picture, template =E<gt> template )> 

Please see the Number::Format docs for more information.

C<$success = $number-E<gt>format(type =E<gt> negative,template =E<gt> template )> 

Please see the Number::Format docs for more information.

C<$success = $number-E<gt>format(type =E<gt> price)> 

Prepends the printed output with the local currency symbol.
Please see the Number::Format docs for more information.

C<$success = $number-E<gt>format(type =E<gt> bytes)> 

Prints the number as K or M. Please see the Number::Format docs for more information.

C<$success = $number-E<gt>format()> 

Will remove the advanced formatting option.

=cut
	my $self = shift(@_);
	(@_ == 1) and unshift(@_,'type');
	my $params = { 	type		=> 	undef,
					template	=>	undef,
					@_ };
	if ($params->{ type }) {
		my ($obj,$meth,$template);
		if (not($FORMATTER)) { 
			eval "require Number::Format";
			if ($@) { # if no Number::Format
				$self->[FORMAT] = 0;
				return undef;
			} else { $FORMATTER = 1; };
		};
		$meth = 'format_'.lc($params->{ type });
		$template = $params->{ template };
		$self->[FORMAT_SUB] = \&{'Number::Format::'.$meth};
		$self->[FORMAT_TEMPLATE] = $params->{ template };
		$self->[FORMAT] = 1;
	} else {
		$self->[FORMAT] = 0;
	};	
}

sub _max { ($_[0] > $_[1]) ? $_[0] : $_[1]; }

1;

__END__

$Log: Number.pm,v $
Revision 1.3  1999/09/07 04:56:26  fix
Some POD changes

Revision 1.2  1999/09/07 04:53:06  fix
Added transcendent functions.
Added clone ability to new interface to make object return easier
with formatting options.


=pod

=head1 CAVEATS and NOTES

=head2 Performance Issues

I wrote this to help me transparently configure number printing formats for 
figures that get passed around between objects that print.  In this capacity it works 
pretty decently for me.  B<However>, using these objects in place of numeric
scalars adds a fair bit of memory and processor consumption, so I'd recommend
only using them when you need to print numbers, and for the occasional calculation.

If you have many calculations to do, you can do the calculations first, and then 
stuff the value into a Text::Number object. 

=head2 Exception Handling

All calculations that can throw exceptions are wrapped in evals.  If your
calculation threw an exception (say, divided bt zero), the return value
will be an empty string.  I was considering returning an instance of the object with
the value set to zero, but this seemed confusing, since you wouldn't necessarily
know if the value was the result of math or of the exception.  I also considered
undef.

I'm open to suggestion on this -- if anyone is using this object and has suggestions,
please send them to me <fix@fixler.com> 

=head1 REQUIRES

Perl 5.005

POSIX

Number::Format (optional)

=head1 AUTHOR

Eric Fixler <fix@fixler.com>

Copyright 1999.  You are free to use, modify, and redistribute this module as 
long as the source remains freely available, and credit is given to the the
original author (i.e., me).

=head1 TODO

Fuller and better implementation of Number::Format methods.

Elimination of POSIX call (there's only one).

Implement mod arithmetic.

Is Text::Number really the right name for this package?

=head1 ACKNOWLEDGEMENTS

Tom Christansen and Nathan Torkington; their StrNum/overload example in the [excellent]
Perl Cookbook was the beginning of this module.

William R. Ward <wrw@bayview.com> author of Number::Format.

=head1 SEE ALSO

Number::Format

=cut

