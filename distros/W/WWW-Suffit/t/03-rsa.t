#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More tests => 4;
use WWW::Suffit::RSA;

my $rsa = WWW::Suffit::RSA->new(key_size => 512);

# Key gen
$rsa->keygen;
my $private_key = $rsa->private_key;
my $public_key = $rsa->public_key;
ok(length $private_key // '', 'Private key');
ok(length $public_key // '', 'Public key');

# Encrypt/Decrypt
{
    my $plaintext = "My test string";
    my $ciphertext = $rsa->encrypt($plaintext);
    my $outtext = $rsa->decrypt($ciphertext);
    is $plaintext, $outtext, 'RSA Encrypt/Decrypt strings' or diag $rsa->error;
}

# Sign/Verify
{
	my $plaintext = "My test string";
	my $signature = $rsa->sign($plaintext); # base64 string
	ok($rsa->verify($plaintext, $signature), 'RSA Sign/Verify');
	diag $rsa->error if $rsa->error;
}

1;

__END__
