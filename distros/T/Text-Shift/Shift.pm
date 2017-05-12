package Text::Shift;

# Boilerplate package imports
use 5.008;
use strict;
use warnings;
use Carp;

# Implementation-specific imports
use Crypt::Cipher v0.02;
use integer; # potential speed increase

# Constants
use constant {
    # Change the following values to modify the default alphabets
    UPPER  => join("","A".."Z"),
    LOWER  => join("","a".."z"),
    NUMBS  => join("",0..9)
    };
use constant {        # constant is broken for self-reference
    FROM   => join("",UPPER,LOWER,NUMBS),
    
    # THE FOLLOWING THREE CONSTANTS MUST NOT CHANGE
    UPPDEX => 0,
    LOWDEX => 1,
    NUMDEX => 2
    };
    
# Class variables
our @ISA = qw(Crypt::Cipher);
our $VERSION = '1.00';
our %_abs;  # Hash of callers' package names pointing to arrays
            # The array is made up of UPPERCASE, LOWERCASE, NUMBERS


#############
# FUNCTIONS #
#############
# The following function rotates the alphabet by magnitude amount
sub _rotate_alphabet($$) {
    # Get parameters
    my($string,$mag) = (shift, int(shift));
    my $strlng = length($string);
    
    # Handle outliers
    $mag += $strlng while($mag < 0);      # Negative magnitude
    $mag %= $strlng if($mag > $strlng);   # Too large magnitude

    # Return rotated string
    return $string if($mag == 0);
    $string .= substr($string,0,$mag, "");
    return $string;
}

###########
# Methods #
###########

# Create the alphabet control methods
BEGIN {
    my $funcref = sub( $ ) {
	my $index = shift;
	return sub($$) {
	    (undef, my $caller) = (shift, caller);
	    if(scalar(@_)) {
		# Modifier return
		$_abs{$caller} = [] unless($_abs{$caller});
		return $_abs{$caller}->[$index] = join("",@_);
	    } else {
		# Accessor return
		return $_abs{$caller}->[$index];
	    }
	};
    };
    
    *uppercase = $funcref->(UPPDEX);
    *lowercase = $funcref->(LOWDEX);
    *numbers   = $funcref->(NUMDEX);
}

sub new($;$$$) {
    # get the parameters
    my $caller = caller;
    my $class = shift;
    my $caps  = (int(shift) or 0);
    my $small = @_ ? int(shift) : $caps;
    my $nums  = @_ ? int(shift) : $caps;
    
    
    # Get the cipher mapping -- note order in source
    if($_abs{$caller}) {
	our @source;
	*source = $_abs{$caller};
	my $upcase = ($source[UPPDEX] or UPPER);
	my $lwcase = ($source[LOWDEX] or LOWER);
	my $numbrs = ($source[NUMDEX] or NUMBS);
	my $to =
	    _rotate_alphabet($upcase, $caps).
	    _rotate_alphabet($lwcase, $small).
	    _rotate_alphabet($numbrs, $nums);
	return $class->SUPER::new(
				  ($upcase.$lwcase.$numbrs),
				  $to
				  );
    } else {
	my $to =
	    _rotate_alphabet(UPPER, $caps).
	    _rotate_alphabet(LOWER, $small).
	    _rotate_alphabet(NUMBS, $nums);		    
	return $class->SUPER::new(FROM,$to);
    }
}


return 1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Shift - Perl extension for shifting text 

=head1 SYNOPSIS

  use Text::Shift; 

  #############
  # Alphabets #
  #############

  # Report on current alphabets
  my @uc_alphabet = Text::Shift->uppercase();
  my @lc_alphabet = Text::Shift->lowercase();
  my @number_list = Text::Shift->numbers();

  # Set alphabets to something other than default
  Text::Shift->uppercase(("a".."p"),("Q".."Z"));
  Text::Shift->lowercase(("A".."P"),("q".."z"));
  Text::Shift->numbers((1..9),0);

  ################
  # Constructors #
  ################
  my $obj;
  $obj = Text::Shift->new(1);     # One value (1) for all shifts
  $obj = Text::Shift->new(1,2);   # Caps=Numbers=1, Small=2
  $obj = Text::Shift->new(1,2,3); # Caps=1, Lowercase=2, Numbers=3

  ###########################################
  # OTHER METHODS PROVIDED BY Crypt::Cipher #
  ###########################################

(See L<Crypt::Cipher> for more methods.)

=head1 ABSTRACT

This class provides an object-oriented wrapper around shift ciphers.
It is designed to provide a simple solution cleanly and unobtrusively.
Shift ciphers are simple, and the code to use them should be simple, 
too.

=head1 DESCRIPTION

=head2 Overview

Shift Ciphers are based on the simple princple of mapping each letter
to another letter "down the line".  It works purely linearly.  There
are three distinct alphabets, one for uppercase, another for 
lowercase, and the last for numbers.  Anything not contained in these
alphabets are deleted from the resulting string, and each alphabet may
be shifted a different magnitude.

=head2 Methods

=head3 Constructors

    CLASS->new(CAPMAG, [LOWMAG, NUMMAG])

Returns an instance of this class shifting the alphabets certain
amounts.  Note that the alphabets used at instantiation are the
alphabets which this object will always use, and so changing the
alphabets after object creation will have no effect on the older
objects.  Any value not supplied will default to CAPMAG or 0.

=head3 Accessors

    CLASS->uppercase()
    CLASS->lowercase()
    CLASS->numbers()

Returns a list consisting of the uppercase alphabet currently in use,
the lowercase alphabet currently in use, and the numbers currenty in
use.  Note that because the accessors are named the same thing as the
modifiers, it is important to use the parentheses here.

=head3 Modifiers

    CLASS->uppercase(LIST)
    CLASS->lowercase(LIST)
    CLASS->numbers(LIST)

Sets the uppercase, lowercase, or numbers alphabet in use for this
package.  Each package has a distinct "alphabetspace" which cannot be
modified by anyone else.  If you would like to change the default
alphabets in use, please see the source code comments.

=head3 Performing the Shift

The methods to actually perform the shift are inherited from L<Crypt::Cipher>.

=head1 HISTORY

=over 4

=item 1.00

Major rewrite; started from scratch and reconstructed the code to be
more clear to both maintainers and the perl interpretater.  The import
routine was removed because it never worked in the first place.  The
information for the 

=item 0.03

Minor efficiency repairs.

=item 0.02

Created import subroutine for alphabet control.


=item 0.01

Original version; created by h2xs 1.22 with options

  -ABCXO
	-n
	Text::Shift

=back



=head1 SEE ALSO

=over 4

=item L<Crypt::Cipher>

=over 4

Parent class, providing many inherited methods including the
following very useful methods:

    $obj->encipher(SCALAR)       # aka: $obj->encipher_string(SCALAR)
    $obj->encipher_scalar(SCALARREF)
    $obj->encipher_list(LIST)
    $obj->encipher_array(ARRAYREF)
    
=back

=back

=head1 AUTHOR

Robert Fischer, E<lt>chia@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Robert Fischer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
