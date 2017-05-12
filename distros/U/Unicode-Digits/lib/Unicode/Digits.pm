package Unicode::Digits;

use warnings;
use strict;

use Carp;
use Unicode::UCD qw/charinfo/;
use Exporter     qw/import/;

our @EXPORT_OK = qw(digits_to_int);

=head1 NAME

Unicode::Digits - Convert UNICODE digits to integers you can do math with

=head1 VERSION

Version 20090607

=cut

our $VERSION = '20090607';

=head1 SYNOPSIS

So, you have matched a string with C<\d> and now want to do some math.
What is that you say?  The number your captured plus 5 is 5?  Oh, that
is right \d now matches UNICODE digits not [0-9].  What to do?  Well,
You can just call C<digits_to_int> and all of your troubles* are over!

    use Unicode::Digits qw/digits_to_int/;

    my $string = "forty-two in Mongolian is \x{1814}\x{1812}";
    my $num = digits_to_int $string =~ /(\d+)/;
    print $num + 5, "\n";

=head1 FUNCTIONS

=head2 digits_to_int(STRING)

The digits_to_int function transliterates a string of UNICODE digit 
characters to a number you can do math with, non-digit characters are
passed through, so C<"42 is \x{1814}\x{1812}"> becomes C<"42 is 42">.

=head2 digits_to_int(STRING, ERRORHANDLING)

You can optionally pass an argument that controls what happens when
the source string contains non-digit characters or characters from
different sets of digits.  ERRORHANDLING can be one of C<"strict">, 
C<"loose">, C<"looser">, or C<"loosest">.  Their behaviours are as 
follows:

=over

=item strict

All of the characters must be digit characters and they must all come 
from the same range (so no mixing Monglian digits with Arabic-Indic 
digits) or the function will die.

=item loose

All of the characters must be digit characters or it will die.
If there are characters from different ranges you will get a warning.

=item looser

If there are any non digit characters, or the characters are from 
different ranges, you will get a warning.

=item loosest

This is the default mode, all non-digit characters are passed through 
witout warning, and the digits do not have to come from the same range.

=back

=cut

sub _find_zero($) {
	my $ord = ord shift;
	return $ord - charinfo($ord)->{digit};
}

sub digits_to_int {
	croak "wrong number of arguments" unless @_ == 1 or @_ == 2;
	my ($string, $mode) = @_;
	$mode = "loosest" unless defined $mode;

	croak "ERRORHANDLING must be strict, loose, looser, or loosest not '$mode'"
		unless $mode =~ /^(?:strict|loose(?:r|st)?)$/;

	croak "string '$string' contains non-digit characters"
		if $mode =~ '^(?:strict|loose)$' and $string =~ /\D/;

	carp "string '$string' contains non-digit characters"
		if $mode eq "looser" and $string =~ /\D/;

	my $num;
	my ($first_num) = $string =~ /(\d)/;
	return $string unless defined $first_num;

	my $zero = _find_zero $first_num;

	for my $d (split //, $string) {
		if ($d =~ /\D/) {
			$num .= $d;
			next;
		}

		my $info = charinfo ord $d;

		croak "string '$string' contains digits from different ranges"
			if $mode eq 'strict' and $zero != _find_zero $d;

		carp "string '$string' contains digits from different ranges"
			if $mode =~ /^looser?$/ and $zero != _find_zero $d;

		die sprintf "U+%x claims to be a digit, but doesn't have a digit number", ord $d
			unless $info->{digit} =~ /[0-9]/;

		$num .= $info->{digit};
	}
	return $num;
}

=head1 AUTHOR

Chas. J. Owens IV, C<< <chas.owens at gmail.com> >>

=head1 DIAGNOSTICS

=over

=item "wrong number of arguments"

C<digits_to_int> takes one or two arguments, 
if you have more than two or no arguments you will recieve this error.

=item "ERRORHANDLING must be strict, loose, looser, or loosest not '%s'"

If you pass a second argument that is not strict, loose, looser, 
or loosest to C<digits_to_int>, you will
recieve this error.

=item "string '%s' contains non-digit characters"

You will recieve this message as a warning or error (depending on what
mode you chose), if the string has characters that do not have the 
UNICODE digit property.

=item "string '$s' contains digits from different ranges"

You will recieve this message as a warning or error (depending on what
mode you chose), if the string has characters that are not part of the 
same range of digit characters.

=item "U+%x claims to be a digit, but doesn't have a digit number"

This error is unlikely to occur, if it does then the bug is either with
my code (the likely scenario) or C<Unicode::UCD> (not very likely).

=back

=head1 BUGS

My understanding of UNICODE is flawed, therefore, I have undoubtly done 
something wrong.  For instance, what should be done with "5\x{0308}"?
Also, there is a bunch of stuff relating to surrogates I don't understand.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Unicode::Digits

=head1 COPYRIGHT & LICENSE

Copyright 2009 Chas. J. Owens IV, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"this is not an interesting return value";
