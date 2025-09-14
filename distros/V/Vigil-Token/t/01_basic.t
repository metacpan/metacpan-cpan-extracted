#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use Vigil::Token;


my $token = Vigil::Token->new;
	
my $session_token = $token->custom_token(256);
ok(length($session_token) == 256, 'custom_token() okay');

my $overload_token = $token->(16);    #An alias for $token->custom_token(16);
ok(length($overload_token) == 16, 'overload method okay');

my $otp = $token->otp(6);
ok(length($otp) == 6, 'otp() method length is okay');

like($otp, qr/^\d+$/, 'otp() format is okay');

done_testing();
