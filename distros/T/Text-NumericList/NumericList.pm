package Text::NumericList;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

# Object creator
sub new{
    my $self = shift;
    my $pkg = {
	array		    => [],
	string		    => '',
	mask		    => undef,
	output_separator    => ',',
	input_separator	    => ',',
	range_regexp	    => '\-',
	range_symbol	    => '-'
    };
    bless $pkg, $self;
    return $pkg;
}

# Convert array to the string. Set array and string attributes
sub set_array{
    no warnings;
    my ($self, @array) = @_;

    # In each array element, remove all non-digit characters.
    foreach (@array){ $_ =~ s/\D//g; }

    # Remove non-unique elements.
    my %seen;
    @array = grep {!$seen{$_}++ and $_ ne ''} @array;

    # Sort the array.
    @array = sort {$a <=> $b} @array;

    # Set 'array' attribute.
    $self->{'array'} = [@array];

    # Apply the mask to the array. 
    $self->_mask;
    @array = $self->get_array;

    # Replace 3 and more sequential elements with a range string (e.g.
    # '1-5') using range_symbol attribute.
    my @string;
    my @tmp;
    push @tmp, shift @array;
    while (@array){
	push @tmp, shift @array;
	if ($tmp[$#tmp] - $tmp[0] > $#tmp){
	    unshift @array, pop @tmp;
	    push @string, $self->_range(@tmp);
	    @tmp = ();
	    push @tmp, shift @array;	
	}   
    }
    push @string, $self->_range(@tmp);
    $self->{'string'} = join($self->{'output_separator'}, @string);
}

# If the array has more than 3 elements, join them with range symbol.
# Otherwise, return the array.
sub _range {
    my ($self, @array) = @_;
    if (@array < 3){return @array}
    return join($self->{'range_symbol'}, $array[0], $array[$#array]);
}

# Return the array attribute
sub get_array{
    my $self = shift;
    return @{$self->{'array'}};
}

# Convert the string into an array.  Set string and array attributes.
sub set_string{
    my ($self, $string) = @_;

    my @array;

    # Convert the string to lower case:
    $string = lc($string);

    # If the range is set and the string matches 'all', 'odd', or 'even',
    # set the 'all', 'odd', or 'even' flag.  Remove 'all', 'odd', or
    # 'even' from the string.
    my $all	= ($string =~ s/all//gi);
    my $odd	= ($string =~ s/odd//gi);    
    my $even	= ($string =~ s/even//gi);

    # If 'all' flag is set, the set_array($self->{'mask'}->get_array) 
    # method and return. 
    if ( ref $self->{'mask'} eq ref $self){
	my @mask_array = $self->{'mask'}->get_array;
	if ($all){
	    # Add the whole mask array
	    push @array, @mask_array;
	}
	if ($odd){
	    # Add odd numbers from the mask array
	    push @array, grep {$_%2} @mask_array;	   
	} 
	if ($even){
	    # Add even numbers from the mask array
	    push @array, grep {!($_%2)} @mask_array;
	}
    }

    # Unless range regular expression is '..', 
    # replace all instances of '..' with a space
    unless ($self->{'range_regexp'} eq '\.\.'){
	$string =~ s/\.\./ /g;
    }

    # Replace all instances of <range_regexp> string with '_'
    $string =~ s/$self->{'range_regexp'}+/_/g;

    # $string =~ s/[^\d$is]*_[^\d$is]*/_/g;
    my $is = $self->{'input_separator'};
    $string =~ s/[^\d$is]*_[^\d$is]*/_/g;

    # Replace all instances of one or more non-digit and non-'..' 
    # with a comma
    $string =~ s/[^\d_]+/,/g;
    
    # Remove '_' not surrounded with digits.
    $string =~ s/,_/,/g;
    $string =~ s/_,/,/g;

    # Replace '_\d+_' with a single '_'
    $string =~ s/_\d+_/_/g;

    # Replace all '_' with a '..'
    $string =~ s/_/../g;

    # Split the string using /,/:
    push @array, map {eval "($_)"} split(/,/, $string);

    $self->set_array(@array);
    $self->{'n'} = 0;
}

# Return the string attribute
sub get_string{
    my $self = shift;
    return $self->{'string'};
}

# Set output separator attribute
sub set_output_separator{
    my ($self, $separator) = @_;
    if ($separator){
	$self->{'string'} =~ s/$self->{'output_separator'}/$separator/g;
        $self->{'output_separator'} = $separator;
    } else {
	warn "Output separator is empty. Output separator is unchanged.";
    }
}

# Set input separator attribute
sub set_input_separator{
    my ($self, $separator) = @_;
    if ($separator){
	$self->{'input_separator'} = $separator;
    } else {
	warn "Input separator is empty.  Input separator is unchanged.";
    }
}

# Set range symbol attribute
sub set_range_symbol{
    my ($self, $symbol) = @_;
    if ($symbol){
	$self->{'string'} =~ s/$self->{'range_symbol'}/$symbol/g;
	$self->{'range_symbol'} = $symbol;
    }
    else {
	warn "Range symbol is empty.  Range symbol is left unchanged."
    }
}

# Set range regular expression
sub set_range_regexp{
    my ($self, $regexp) = @_;
    if ($regexp){
	$self->{'range_regexp'} = $regexp;
    }
    else {
	warn 'Range regular expression is empty.  Range regular expression is left unchanged.';
    }
}

# Set object mask
sub set_mask{
    my ($self, $mask) = @_;
    if (ref $mask eq ref $self){
	$self->{'mask'} = $mask;
	$self->_mask;
    } else {
	warn "The mask is not a ".ref $self." object.  The mask is left unchanged.";
    }
}

# Apply the mask to the array
sub _mask{ 
    my $self = shift;
    unless (ref $self->{'mask'} eq ref $self){return}
    my @array = $self->get_array;
    my @mask_array = $self->{'mask'}->get_array;
    if (@mask_array){
	my (@union, %union, @isect, %isect);
	@union = @isect = ();
	%union = %isect = ();

	foreach my $e (@array, @mask_array){ $union{$e}++ && $isect{$e}++ }

	$self->set_array(sort {$a <=> $b} keys %isect) unless $self->{'n'}++; 
    }
}


1;
__END__

=head1 NAME

Text::NumericList - Perl extension for converting strings into
arrays of positive integers and vice-versa.  

=head1 SYNOPSIS

  use Text::NumericList;
  my $list = Text::NumericList->new;

=head2 Converting arrays into strings

  $list->set_array(1,2,3,5,6,7);
  my $string = $list->get_string;   # Returns '1-3,5-7'

  $list->set_output_separator(';');
  $string = $list->get_string;	    # Returns '1-3;5-7'

  $list->set_range_symbol('..');
  $string = $list->get_string;	    # Returns '1..3;5..7'

=head2 Converting strings into arrays

  $list->set_string('1-3,5-7');
  my @array = $list->get_array;	    # Returns (1,2,3,5,6,7)

  $list->set_range_regexp('.+');    # Set range regular expression to
				    # a single or multiple periods
  $list->set_string('1..3,5...7');
  @array = $list->get_array;	    # Returns (1,2,3,5,6,7) 

=head2 Additional methods

  my $mask = new Text::NumericList;
  $mask->set_string('1-10,20-25');
  $list->set_mask($mask);	    # Set the list mask

Mask limits the numeric list to certain values, so that get_string() and
get_array() methods return intersection of the current list and the
mask:  

  $list->set_string('15-30');
  @array    = $list->get_array;	    # Returns (20,21,22,23,24,25)
  $string   = $list->get_string;    # Returns '20-25'

The following shortcuts work if the mask is set.

  $list->set_string('18,odd');
  @array    = $list->get_array;	    # Returns (15,17-19,21,23,25,27,29)

  $list->set_string('21,even');
  @array    = $list->get_array;	    # Returns (16,18,20-22,24,26,28,30)

  $list->set_string('all');
  $string   = $list->get_string;    # Returns '15-30'

=head1 DESCRIPTION

This class is useful for applications where a user is required to
enter large arrays of integers.  This class parses user-provided text
strings and converts them into arrays of integers.  This class also
converts arrays of integers into a text string replacing sequential
integers with a range (e.g. "1-5").

=head1 METHODS

=over

=item new()

Creates a new Text::NumericList object.

=item set_array(@)

Sets the 'array' attribute.
Converts array into string and sets the 'string' attribute as well.
 
 Conversion algorithm:

 * In each array element, remove all non-digit characters.
 * Remove non-unique elements.
 * Sort the array.
 * Set the 'array' attribute.
 * Apply the mask to the array.
 * Replace 3 and more sequential elements with a range string (e.g.
   '1-5') using range_symbol attribute.
 * Join elements and with the output_separator string.
 * Set the 'string' attribute.

=item set_string($)

Converts the string into an array.  Sets the 'array' and 'string'
attributes to the resulting array using set_array().  Every effort is
made to make sense of user input.  Unrecognizeable characters are
removed from the string.  Some illegal combinations of other symbols
are removed or replaced.  Reverse ranges (such as 8-5) are ignored.
If the mask is set, set_string() method recognizes the following keywords:
'all', 'odd', and 'even'.

 Examples (assuming that mask is set to '1-10'):

 ===================================================
 Input string	Resulting array	    Resulting string	    
 ---------------------------------------------------
 '3,2,1,3,5-7'	1,2,3,5,6,7	    '1-3,5-7'
 '2,oDD'	1,2,3,5,7,9	    '1-3,5,7,9'
 'eVen,5'	2,4,5,6,8,10	    '2,4-6,8,10'
 '5,-4-,7'	4,5,7		    '4,5,7'
 '7-9-12'	7,8,9,10	    '7-10'
 '1 -&% 4s7'	1,2,3,4,7	    '1-4,7'
 ===================================================


=item get_array()

Returns the array attribute.

=item get_string()

Returns the string attribute.

=item set_range_regexp($)

Argument: a string.
Sets range regular expression.  Default is '\-'.

=item set_range_symbol($)

Argument: a string.
Set the combination of characters to present ranges in the output
string.  Default is '-'.

=item set_output_separator($)

Argument: a string.
Sets the string to separate elements in the output string.  Default is
','.

=item set_input_separator($)

Argument: a string.
Sets the string which is considered an element separator in the input
string.  Default is ','.  In general, elements in the input string can
be separated by any non-digit character which does not match range
regular expression.  Input separator is used only to avoid character
combinations like '5-,' in the input strings.

=item set_mask($Text_NumericList)

Argument: another Text::NumericList object.  When the mask is set, 
the values of the 'array' attribute are limited to those specified in the
mask object.  All other values in the input string or input array are
ignored.

=back

=head1 BUGS

Methods set_mask(), set_input_separator(),
set_output_separator(),
set_range_regexp(), and set_range_symbol() are supposed to be used
prior to set_array() or set_string().  The output may not look as
expected if you use these methods after set_array() or set_string(),
although some effort has been made to make the output look reasonable.

=head1 AUTHOR

Arkady Grudzinsky, E<lt>grudziar@linuxhightech.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
