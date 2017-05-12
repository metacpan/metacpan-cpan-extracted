package Text::Stripper;

# DOCUMENT:  Text-Stripper, strips of text.
# VERSION:   $Revision: 1.18 $
# DATE:      $Date: 2007-06-14 20:00:01 $
# AUTHOR:    M. Beranek <marcus@beranek.de>
# COPYRIGHT: M. Beranek

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Stripper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw(
#	stripof
#) ] );
#
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT_OK = qw(
	stripof
	breakpoints
);

#my $cvsRev = '$Revision: 1.18 $';
#$cvsRev =~ s/\$Revision:\s//g;
#$cvsRev =~ s/\s\$//g;

our $VERSION = '1.16';

# Possible breakpoints:
our @breakpoints = ( ' ', '\t', '\.', ',', ';', ':', '!', 
	'-', '\?', '\n', '\r', '\/', '\|', '\(', '\)' );

# ----------------------------------------------------------------------
# Shortens text at a possible position.
# $text - text to be shortend
# $len  - minimum length
# $tol  - maximum tolerance
# $max  - 0 = shorten as early as possible | 1 = shorten as late as possible
# $dots - 0 = no dots after shortening | 1 add dots after shortening
# ----------------------------------------------------------------------
sub stripof {
	
	# Parameter:
	my $text = shift or return;
	my $len  = shift or return $text;
	my $tol  = shift or return substr($text, $len);
	my $max  = shift or 0;
	my $dots = shift or 0;
	
	# Possible breakpoints:
	#my @breakpoints = ( ' ', '\t', '.', ',', ';', ':', '!', '-', '?', '/', '|', '(', ')' );
	
	# minimum / maximum length:
	my $maxLen = $len + $tol;
	my $minLen = $len;
	
	# current length:
	my $textLen = length( $text );
	
	# if search for latest break:
	if( $max ){
		# stop, if text is shorter than maximum:
		if( $textLen <= $maxLen ){
			return $text;
		}
	}
	
	# shortest possible text (will be in returned string always):
	my $minText  = substr( $text, 0, $minLen );
	
	# longest possible text:
	my $maxText  = substr( $text, 0, $maxLen );
	
	# text between minimum and maximum:
	my $restText = substr( $text, $minLen, $tol );
	
	# buffer for return-string:
	my $shortText = "";
	
	# buffer for additional-text:
	my $addText = "";
	
	# find breakpoint as late as possible:
	if( $max ){
		
		# we're just working on $resttext:
		$addText = $restText;
		
		# previously hardcoded regexp:
		# $addText =~ s/(.*)[ ,\t\.;:!-\?\/\|\(\)].+/$1/gi;
		
		# use regexp to find possible breakpoints. regexps are greedy,
		# so they will find the last possible space: 
		my $regexpBreakpoints = join '', @breakpoints;
		# print "X:".$regexpBreakpoints.":X";
		$addText =~ s/(.*)[$regexpBreakpoints].*/$1/g;
		
		# if no space was found:
		if( $addText eq '' ){
			# return complete text:
			$addText = $restText;
		}
		# return minimum + additional:
		$shortText = "$minText$addText";
	}
	
	# search for first possible break:
	else {
		# emty additional text:
		$addText = "";
		
		# find first break:
		# test all characters in the $restText
		for( my $idx = 0; $idx < $tol; $idx ++ ){
			
			# current character:
			my $char = substr( $restText, $idx, 1 );
			
			# is character a space?
			my $isSpace = 0;
			
			# test if character matches on of the 
			# space-characters defined in @breakpoints:
			foreach( @breakpoints ){
				
				# if caharcter matches space:
				if( $char eq $_ ){
					
					# mark as space, skip rest of @breakpoints:
					$isSpace = 1;
					last;
				}
				
				
			}
			
			# if we didn't find a space:
			if( ! $isSpace ){
				# append the character to the buffer:
				$addText .= $char;
			}
			# if we found a space:
			else {
				# stop here:
				last;
			}
			
		}
		# return text = minimum-text + additional-text:
		$shortText = "$minText$addText";
	}
	
	# if we want some dots on the shortened text:
	if( $dots ){
		# only if text is really shorter than the original text:
		if( length($shortText) < length($text) ){
			# append dots:
			$shortText .= "...";
		}
	}
	
	# return the shortened text:
	return $shortText;
	
}


1;
__END__

=pod


=head1 NAME

Text::Stripper - a module for shortening text


=head1 SYNOPSIS

  use Text::Stripper;
  
  my $text = "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  my $len  = 30;
  my $tol  = 10;
  my $max  = 1;
  my $dots = 1;
  
  print Text::Stripper::stripof( $text, $len, $tol, $max, $dots );
  
  # prints "Lorem ipsum dolor sit amet, consectetur,..."
  
  

=head1 DESCRIPTION

Text::Stripper shortens text and avoids cutting the text in the middle of a word.


=head1 DETAILS


=head2 Motivation

There may be situations, when you have a reasonably long text in
your perl-application, which should be displayed to the user. But
you may not want to print out all of the text, because it would consume
too much space of your screen. So, you might want to display a shortened 
version of the information, and let the user decide, if he wants to view
the full text or not.

In many cases, a "print substr($text, 0, 50).'...';" will be sufficient.
Unfortunatly nearly all uses of the above example will cut your text 
in the middle of a word. So you might get phrases saying "This is an a..."
or similar. For most users, this kind of text-stripping is hard to read 
and also offers some space for misinterpreting the cutted word.

A cleaner solution for the user is to print out "This is an..."
or "This is an abstract...". This way, the user doesn't get confused 
about wondering what the "a..." stands for. This is where Text::Stripper
comes in.


=head2 The stripof-function

The module Text::Stripper consists of a single function named "stripof".
You can give "stripof" a text, a "length" and a "tolerance", and it 
will give you a text shortend to at least "length" characters, with 
at maximum "tolerance" characters more to complete the next word(s).


=head2 Breakpoints

The "stripof"-function tries to find all possible "breakpoints" in the 
text and cuts the text at an apropriate position. It consideres the following 
characters as "breakpoints": 

=over

=item ' '

=item '\t'

=item '.'

=item ','

=item ';'

=item ':'

=item '!'

=item '-'

=item '?'

=item '\n'

=item '\r'

=item '/'

=item '|'

=item '('

=item ')'

=back


=head2 Modes

There are two modes, in which the stripof-function may operate:

=over

=item * I<maximum-mode>: try to find the latest possible breakpoint

=item * I<minimum-mode>: try to find the first possible breakpoint

=back

See the examples-section for more details. 

Optionally you can tell "stripof" to add three dots at the end of
the text, to indicate that the text was shortend.


=head1 CONFIGURATION

Under certain circumstances you might need more or less, or completely 
other characters as the predefined breakpoints. To achieve this, you
have to redefine the breakpoints by overriding the modules global variable
C<@Text::Stripper::breakpoints>:

  use Text::Stripper;
  
  my $text = "abc1xyz2asdfg3zoo4gogo5gadgetto6";
  my $len  = 10;
  my $tol  = 10;
  my $max  = 1;
  my $dots = 0;
  
  # use 0...9 as breakpoints only:
  @Text::Stripper::breakpoints = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
  
  print Text::Stripper::stripof( $text, $len, $tol, $max, $dots );
  
  # prints "abc1xyz2asdfg3zoo"
  
B<Important>: each entry in the breakpoints-list must contain a single character only!
Definig something like: 

  @Text::Stripper::breakpoints = ( '10', '20', '30' );  #  WRONG...!!!

does not work! This definition may result in the following behaviour:
on maximum-search: breakpoints '0', '1', '2' and '3' are matched;
on minimum-seach: no breakpoint will match at all.

Special characters must be escaped. So the following definition to use some
paranthesis as breakpoints does not work:

  @Text::Stripper::breakpoints = ( '(', ')', '[', ']' );  #  WRONG...!!!

The correct definiton is:

  @Text::Stripper::breakpoints = ( '\(', '\)', '\[', '\]' );  #  RIGHT...!!!

This is because the breakpoint-characters are used in a regular expression.
Therefore, they are not treated as usual charaters unless they are escaped.


=head1 EXAMPLES

  use Text::Stripper qw(stripof);
  my $text = "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  
  print stripof( $text, 30, 10, 1, 1 );
  # prints "Lorem ipsum dolor sit amet, consectetur..."
  # orig.: "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  #         1----------------------------^---------^ 
  #                                      30      +10
  #         one space: ----------------------------^
  #         $max set to 1 => use last space, which equals first space.
  
  print stripof( $text, 30, 10, 0, 1 );
  # prints "Lorem ipsum dolor sit amet, consectetur..."
  # orig.: "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  #         1-----------------------------^--------^ 
  #                                       30      +10
  #         one space: ----------------------------^
  #         $max set to 0 => use first space, which equals last space.
  
  print stripof( $text, 25, 14, 1, 1 );
  # prints "Lorem ipsum dolor sit amet,..."
  # orig.: "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  #         1-----------------------^-------------^ 
  #                                 25           +14
  #         two spaces: --------------^^
  #         $max set to 1 => use last space.
  
  
  print stripof( $text, 20, 10, 1, 1 );
  # prints "Lorem ipsum dolor sit amet,..."
  # orig.: "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  #         1------------------^---------^
  #                            20       +10
  #         3 spaces: -----------^----^^
  #         $max set to 1 => use last space. 
  
  print stripof( $text, 20, 10, 0, 1 );
  # prints "Lorem ipsum dolor sit..."
  # orig.: "Lorem ipsum dolor sit amet, consectetur, adipisci velit";
  #         1------------------^---------^
  #                            20       +10
  #         3 spaces: -----------^----^^
  #         $max set to 0 => use first space.
  


=head1 EXPORT

None by default.

You may import the function "stripof" and the list "breakpoints".


=head1 VERSION

$Revision: 1.18 $


=head1 BUGS

No bugs known. Please report bugs to E<lt>marcus@beranek.deE<gt>.


=head1 SEE ALSO

http://www.beranek.de


=head1 AUTHOR

Marcus Beranek, E<lt>marcus@beranek.deE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Marcus Beranek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
