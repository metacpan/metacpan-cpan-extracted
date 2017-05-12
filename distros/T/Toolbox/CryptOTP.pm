#
# Toolbox::CryptOTP - Simple one-time-pad encryption
#
#    (c) 2002 Jason Leane <alphamethyl@mac.com>
#
# See "README" for more information.
#

package Toolbox::CryptOTP;

use Exporter;

@ISA 		= 	qw(Exporter);
@EXPORT 	= 	qw(encrypt_file decrypt_file encrypt_string decrypt_string rand_pad);
@EXPORT_OK 	= 	qw(encrypt_file decrypt_file encrypt_string decrypt_string rand_pad);

# 4k blocks should be ok for most applications...

$BLOCKSIZE 	= 	4096;

$VERSION	=	"0.52";

BEGIN {
	srand;
}

sub encrypt_string {
	my $string = shift;
	my $pad = chr(hex(shift));
	my @str = split(//, $string);
	my $out, $cc;
	while(@str) {
		my $chr = shift(@str);
		$cc = ($chr ^ $pad);
		$out = $out . $cc;
	}
	return($out);
}

sub decrypt_string {
	my $string = shift;
	my $pad = chr(hex(shift));
	my @str = split(//, $string);
	my $out, $cc;
	while(@str) {
		my $chr = shift(@str);
		$chr = ($chr ^ $pad);
		$out = $out . $chr;
	}
	return($out);
}

sub encrypt_file {

	my $pf = shift;
	my $cf = shift || "$pf.enc";
	my $padf = shift;

	open(PLAIN, "<$pf") or die("Can't open $pf: $!");
	open(PADFILE, "<$padf") or die("Can't open $padf: $!");
	open(CIPHER, ">$cf") or die("Can't open $cf: $!");
	
	binmode(PLAIN); binmode(PADFILE); binmode(CIPHER);

	while(my $read = sysread(PLAIN, $in_buffer, $BLOCKSIZE)) {
		if($read < $BLOCKSIZE) { $in_buffer = &null_pad($in_buffer, $BLOCKSIZE); }
		sysread(PADFILE, $pad_buffer, $BLOCKSIZE);
		my $ctext = ($in_buffer ^ $pad_buffer);
		syswrite(CIPHER, $ctext, $BLOCKSIZE);
	}

	close(CIPHER); close(PLAIN); close(PADFILE);

	return(1);

}

sub decrypt_file {

	my $cf = shift;
	my $pf = shift || "$cf.out";
	my $padf = shift;

	open(PLAIN, ">$pf") or die("Can't open $pf: $!");
	open(PADFILE, "<$padf") or die("Can't open $padf: $!");
	open(CIPHER, "<$cf") or die("Can't open $cf: $!");
	
	binmode(PLAIN); binmode(PADFILE); binmode(CIPHER);

	while(my $read = sysread(CIPHER, $in_buffer, $BLOCKSIZE)) {
		
		sysread(PADFILE, $pad_buffer, $BLOCKSIZE);
		my $ctext = ($in_buffer ^ $pad_buffer);
		if(eof(PADFILE)) { $ctext = &remove_pad($ctext); }
		syswrite(PLAIN, $ctext, length($ctext));
		
	}

	close(CIPHER); close(PLAIN); close(PADFILE);

	return(1);

}

sub null_pad {
	my $block = shift;
	my $size = shift;
	my $null = chr(0);
	my $needed = $size - length($block);
	my $padstring = $null x $needed;
	$block = $block . $padstring;
	return($block);
}

sub remove_pad {
	my $block = shift;
	$block =~ s/(\000)*$//g;
	return($block);
}

sub rand_pad {
	my $filename = shift || "rand" . int(rand(9000)) . ".pad";
	my $cnt = 0;
	open(PADD, ">$filename") or die("Couldn't open $filename: $!");
	while($cnt < $BLOCKSIZE) {
		$cnt++;
		syswrite(PADD, chr(int(rand(254)) + 1), 1);
	}
	close(PADD);
	return($filename);
}

return(1);

__END__

=head1 NAME

C<Toolbox::CryptOTP> - Play around with one-time-pad type encryption

=head1 SYNOPSIS

	use Toolbox::CryptOTP;
	
	$plaintextfile = "doc.txt";
	
	# Generate a random pad
	$pad_file = rand_pad("mypad.otp");
	
	# Encrypt a file
	encrypt_file($plaintextfile, "ciphertext.txt", "mypad.otp");
	
	# Decrypt it back
	decrypt_file("ciphertext.txt", "decrypted-plain.txt", "mypad.otp");
	
	# Encrypt a string
	
	$plaintext = "Squeamish Ossifrage";
	
	$garbage = encrypt_string($plaintext, 'f4');
	
	# Decrypt it back
	$text = decrypt_string($garbage, 'f4');
	
	
=head1 DESCRIPTION

A module meant for those interested in learning abotu cryptography... the methods
used here are not MEANT to be secure, and should be used solely to understand the principles
of encryption. DO NOT use any function in this module to attempt to protect sensitive data.

These functions implement "One-Time-Pad" encryption.  For the file encryption/decryption
functions, you specify another file as the 'pad'. One block is read from this file, and applied
to each block of the input (NOTE: this is a BIG security flaw). If you run the output back through,
with an IDENTICAL pad, you should recover the plaintext.

For more information, see "Internet Cryptography" by Richard E. Smith. It covers this topic
and many others.


=head2 B<encrypt_file(input, output, pad)   decrypt_file(input, output, pad)>

Encrypts or decrypts a file.  For encryption, the input is plaintext, the output
is ciphertext. For decryption, the input is ciphertext, the output is plaintext. The pad
is shared between both functions.  All arguments are filenames (not fileHANDLES).


=head2 B<encrypt_string("string", 'FF')  decrypt_string("f2fe3222", 'FF')>

Encrypts or decrypts a string.  The pad is given as a two-digit hexadecimal number
(00 - FF). It is applied to each character of the plaintext/ciphertext.  Returns either
ciphertext of plaintext.


=head2 B<rand_pad("filename.pad")>

Generates a somewhat-random pad file, BLOCKSIZE bytes long. Use this if you can't locate
a pad file of your own...


=head2 B<BLOCKSIZE>

You can set the size of the functions' encryption blocks by setting
C<Toolbox::CryptOTP::BLOCKSIZE>.  The default is 4096 (bytes).


=head1 EXPORTABLE FUNCTIONS

All functions are exported.

	use Toolbox::CryptOTP;

=head1 BUGS

None that i know about.  If you want to see bugs, go have a look at DES...

Wel, of course, using it for actual crypto is a bug in itself.

=head1 TO DO

Add more useful things as I think of them... Send me suggestions!

=head1 AUTHOR

Jason Leane (alphamethyl@mac.com)

Copyright 2002 Jason Leane

Thanks to B<LucyFerr> for getting me out of a rut and renewing my enthusiasm for Perl
with her own brand of persevereance as she learned Perl for the first time.

I<"Now quick, what's 0xDEADBEEF in octal?">

=cut
