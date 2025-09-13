#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use Vigil::Crypt;

my $EXAMPLE_ENCRYPTION_KEY_DO_NOT_USE_THIS_IN_YOUR_OWN_PROJECT = 'a3f1c5e7b9d2f4a6c8e0b2d4f6a8c0e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a2';
my $crypt = Vigil::Crypt->new($EXAMPLE_ENCRYPTION_KEY_DO_NOT_USE_THIS_IN_YOUR_OWN_PROJECT);

my %values_to_encrypt = (
    1 => 'Farmer Brown',
	2 => 'daemon@gmail.com',
	3 => 'Sasparilla is fuzzy and makes me sneeze.',
	4 => '213-555-1212'
);

print "< < < < < < < < < < ENCRYPTION/DECRYPTION > > > > > > > > > >\n\n";

foreach my $key (sort keys %values_to_encrypt) {
	my $encrypted_value = $crypt->encrypt($values_to_encrypt{$key});
	my $decrypted_value = $crypt->decrypt($encrypted_value);
	print "Plaintext: $values_to_encrypt{$key}\n";
	print "Encrypted: $encrypted_value\n";
	print "Plaintext length: ", length($values_to_encrypt{$key}), "; Encrypted length: ", length($encrypted_value), "\n";
	print "Decrypted: $decrypted_value\n\n";
}

print "< < < < < < < < < < HASHING > > > > > > > > > >\n\n";
my $EXAMPLE_PEPPER_DO_NOT_USE_THIS_IN_YOUR_OWN_PROJECT = "EzekielAndTony";
my @test_passwords = (
    'aB7$dF9!kLm2Qw#eRtY6ZpXv',
    'vT9#kP1',
    'Hq2&nD7fXr!Vb5$YmC1zWk8pLgQw$eZ8@RbM4xYjL6s',
    'sG4$eL9wQv#TyJ2@NpK7xHjB6yR',
    'Zr1!fM6cT5xPyJ2hW',
    'aN3@dX7pJw#F9L6yRtH1zG'
);

foreach my $pwd (@test_passwords) {
	my $hash = $crypt->hash($pwd, $EXAMPLE_PEPPER_DO_NOT_USE_THIS_IN_YOUR_OWN_PROJECT);
	print "PWD : $pwd\nHASH: ", $hash, "\n";
	print "PWD length: ", length($pwd), "; HASH length: ", length($hash), "\n";
	if($crypt->verify_hash($pwd, $hash, $EXAMPLE_PEPPER_DO_NOT_USE_THIS_IN_YOUR_OWN_PROJECT)) {
		print "PWD Verifies\n\n";
	} else {
		print "PWD does NOT verify!\n\n";
	}
}

print "\n";
use MIME::Base64;
print decode_base64('RGVtbyBmaW5pc2hlZDogTXkgS3VuZy1GdSBpcyBzdHJvbmcuLi4='), "\n";
