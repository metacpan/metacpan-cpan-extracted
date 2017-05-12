###############################################################################
# Purpose : Substitution cipher based on a keyword alphabet
# Author  : John Alden
# Created : Jan 2005
# CVS     : $Id: KeywordAlphabet.pm,v 1.5 2005/03/20 20:02:11 aldenj20 Exp $
###############################################################################

package Text::Cipher::KeywordAlphabet;

use strict;
use Text::Cipher;
use Carp;
use vars qw($VERSION $AUTOLOAD);
$VERSION = sprintf "%d.%03d", (q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/);

sub new {
	my ($class, $keywords, $offset) = @_;
   	croak("offset must be an integer") unless($offset =~ /^\-?\d*$/); #Integer or blank
	my %seen;
	my $alphabet = join("", map {uc} grep {/^[a-z]$/i && !$seen{$_}++} (split //, $keywords), 'a'..'z');
	$alphabet = _rotate_alphabet($alphabet, $offset);	
	my $self = {
		cipher => new Text::Cipher(join("", 'A'..'Z', 'a'..'z'), join("", $alphabet, map {lc} $alphabet)),
		decipher => new Text::Cipher(join("", $alphabet, map {lc} $alphabet), join("", 'A'..'Z', 'a'..'z')),
		alphabet => $alphabet
	};
	return bless($self, $class);
}

sub alphabet {
	my ($self) = shift;
	return $self->{alphabet};
}

sub AUTOLOAD {
	my ($self) = shift;	
	
    # DESTROY messages should never be propagated
    return if $AUTOLOAD =~ /::DESTROY$/;

    # Remove the package name
    my $package = __PACKAGE__;
    $AUTOLOAD =~ s/^${package}:://;

    # Pass on to either the enciphering or deciphering object
	if($AUTOLOAD =~ /^decipher/) {
		$AUTOLOAD =~ s/^decipher/encipher/;
		$self->{decipher}->$AUTOLOAD(@_);			
	} else {
		$self->{cipher}->$AUTOLOAD(@_);	
    }
}

# Based on routine in Text::Shift
sub _rotate_alphabet {
    # Get parameters
    my($string,$mag) = @_;
    my $strlng = length($string);
    
    # Handle outliers
    $mag %= $strlng if(abs($mag) > $strlng or $mag < 0);

    # Return rotated string
    return $string if($mag == 0);
    $string .= substr($string,0,$mag, "");
    return $string;
}

1;

=head1 NAME

Text::Cipher::KeywordAlphabet - Substitution cipher based on a keyword alphabet

=head1 SYNOPSIS

	#Create a keyword alphabet with a left shift of 5
	$cipher = new Text::Cipher::KeywordAlphabet("the quick brown fox", -5);

	#Fetch the generated alphabet
	$keyword_alphabet = $cipher->alphabet();

	#Encipher a string
	$ciphered = $cipher->encipher($message);

	#Decipher an enciphered message
	$message = $cipher->decipher($ciphered);

	#Some convenience methods
	$cipher->encipher_scalar(\$some_scalar);
	$cipher->decipher_scalar(\$some_scalar);
	@ciphered = $cipher->encipher_list(@list);
	@list = $cipher->decipher_list(@ciphered);
	$cipher->encipher_array(\@some_array);
	$cipher->decipher_array(\@some_array);

	#Other uses
	$null_cipher = new Text::Cipher::KeywordAlphabet(); #no-op cipher
	$rot13_cipher = new Text::Cipher::KeywordAlphabet(undef, 13); #Caesar cipher

=head1 DESCRIPTION

This module generates a monoalphabetic substitution cipher from a set of words, resulting in what's sometimes referred to as a "keyword (generated) alphabet".
Here's a good definition, plagiarised from an anonymous source:

"A keyword alphabet is formed by taking a word or phrase, deleting the second and subsequent occurrence of each letter and then writing the remaining letters of the alphabet in order.
Encipherment is achieved by replacing each plaintext letter by the letter that appears N letters later in the (cyclic) keyword alphabet."

The keyword alphabet is case-insensitive - both uppercase and lowercase characters will be transformed with the same mapping.
The offset (N in the definition above) can be a positive or negative integer.

L<http://www.trincoll.edu/depts/cpsc/cryptography/substitution.html> is an introductory tutorial on how substitution ciphers can be broken.
L<http://www-math.cudenver.edu/~wcherowi/courses/m5410/exsubcip.html> contains a full worked example.
L<http://www.muth.org/Robert/Cipher/query_scb.html> provides an online substitution cipher breaker.

At the risk of stating the obvious, since substitution ciphers are easy to break, it's advisable not to use them for protecting important data.
Look at some of the more heavy-duty ciphers in the Crypt:: namespace which plug into Crypt::CBC if you want to protect data.

=head1 METHODS

=over 4

=item $obj = new Text::Cipher::KeywordAlphabet($keyword_phrase, $offset)

Create a new keyword alphabet

=item $keyword_alphabet = $obj->alphabet();

Return the keyword alphabet created by the constructor

=item $ciphered = $obj->encipher($message)

Enciphers a string using the keyword alphabet

=item $message = $obj->decipher($ciphered)

Reverse of encipher()

=item $obj->encipher_scalar(\$some_scalar);

By-reference equivalent of encipher()

=item $obj->decipher_scalar(\$some_scalar);

By-reference equivalent of decipher()

=item @ciphered = $obj->encipher_list(@list);

Convenience method provided by Text::Cipher

=item @list = $obj->decipher_list(@ciphered);

Reverse of encipher_list().

=item $obj->encipher_array(\@some_array);

Convenience method provided by Text::Cipher

=item $obj->decipher_array(\@some_array);

Reverse of encipher_array().

=back

=head1 VERSION

See $Text::Cipher::KeywordAlphabet::VERSION.
Last edit: $Revision: 1.5 $ on $Date: 2005/03/20 20:02:11 $

=head1 BUGS

None known.  This module has not been used heavily in production so it's not impossible a bug may have slipped through the unit tests.
Bug reports are welcome, particularly with patches & test cases.

=head1 AUTHOR

John Alden <johna@cpan.org>

=head1 SEE ALSO

=over 4

=item Text::Cipher and Regexp::Tr

Useful building blocks for substitution ciphers

=item Text::Shift and Crypt::Rot13

Caesar (aka shift or rot-N) ciphers (see L<http://www.trincoll.edu/depts/cpsc/cryptography/caesar.html>)

=item Crypt::Caesar

Crack Caesar ciphers using letter frequency (see L<http://www.trincoll.edu/depts/cpsc/cryptography/caesar.html>)

=item Crypt::Vigenere

Vigenere polyalphabetic cipher (see L<http://www.trincoll.edu/depts/cpsc/cryptography/vigenere.html>)

=item Crypt::Enigma and Crypt::OOEnigma

Implementations of Enigma ciphers (see L<http://www.trincoll.edu/depts/cpsc/cryptography/enigma.html>)

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by John Alden

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
