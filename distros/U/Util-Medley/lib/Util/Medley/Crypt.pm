package Util::Medley::Crypt;
$Util::Medley::Crypt::VERSION = '0.016';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Crypt::CBC;
use Crypt::Blowfish;

=head1 NAME

Util::Medley::Crypt - Class for simple encrypt/descrypt of strings.

=head1 VERSION

version 0.016

=cut

=head1 SYNOPSIS

 my $key = 'abcdefghijklmnopqrstuvwxyz';
 my $str = 'foobar';

 my $crypt = Util::Medley::Crypt->new;

 #
 # positional
 #
 my $encryptedStr = $crypt->encryptStr($str, $key);

 my $decryptedStr = $crypt->decryptStr($encryptedStr, $key);
 
 #
 # named pair
 # 
 my $encryptedStr = $crypt->encryptStr(
    str => $str,
    key => $key
 );

 my $decryptedStr = $crypt->decryptStr(
    str => $encryptedStr,
    key => $key
 );
  
=cut

########################################################

=head1 DESCRIPTION

This class provides a thin wrapper around Crypt::CBC.
 
All methods confess on error.

=cut

########################################################

=head1 ATTRIBUTES

=head2 key (optional)

Key to use for encrypting/decrypting methods when one isn't provided through
the method calls.

=over

=item type: Str

=item env var: MEDLEY_CRYPT_KEY

=back

=cut

has key =>(
	is => 'rw',
	isa => 'Str',
);

########################################################

=head1 METHODS

=head2 decryptStr

Decrypts the provided string.

=over

=item usage:

 my $decryptedStr = $crypt->decryptStr($encryptedStr, $key);
 
 my $decryptedStr = $crypt->decryptStr(
       str => $encryptedStr,
     [ key => $key ]
 );
      
=item args:

=over

=item str [Str]

String you wish to decrypt.

=item key [Str]

Key that was used to encrypt the string.
                                
=back

=back

=cut

multi method decryptStr (Str :$str!,
				   		 Str :$key) {

	$key = $self->_getKey($key);
	
    my $cipher = Crypt::CBC->new(-key => $key, -cipher => 'Blowfish');
    return $cipher->decrypt_hex($str);
}

multi method decryptStr (Str $str,
				   		 Str $key?) {

	my %a;
	$a{str} = $str;
	$a{key} = $key if $key;
	
	return $self->decryptStr(%a);
}

=head2 encryptStr

Encrypts the provided string.

=over

=item usage:

 my $encryptedStr = $crypt->encryptStr($str, $key);
 
 my $encryptedStr = $crypt->encryptStr(
     str => $str,
     [ key => $key ]
 );
 
=item args:
 
=over

=item str [Str]

String you wish to encrypt.

=item key [Str] (optional)

Key used to encrypt the string.
                                
=back

=back

=cut

multi method encryptStr (Str :$str!, 
	    			   	 Str :$key) {

	$key = $self->_getKey($key);
    
    my $cipher = Crypt::CBC->new(-key => $key, -cipher => 'Blowfish');
    return $cipher->encrypt_hex($str);
}

multi method encryptStr (Str $str, 
	    			   	 Str $key?) {

	my %a;
	$a{str} = $str;
	$a{key} = $key if $key;
	
	return $self->encryptStr(%a);	
}
	    			   	 	    			   	 	
#################################################

method _getKey (Str|Undef $key) {
	
	if ( !$key ) {
		if ( !$self->key ) {
			if ($ENV{MEDLEY_CRYPT_KEY}){
				return 	$ENV{MEDLEY_CRYPT_KEY};
			}
			else {
				confess "must provide key";
			}
		}

		return $self->key;
	}

	return $key;
}

1;
