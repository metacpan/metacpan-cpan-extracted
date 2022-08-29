#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML::xmlsec;

my $signer=XML::LibXML::xmlsec->new();

my $pem= <<'PEM';
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIICxjBABgkqhkiG9w0BBQ0wMzAbBgkqhkiG9w0BBQwwDgQIyBdWdqfkhi0CAggA
MBQGCCqGSIb3DQMHBAg7pc6ekszKVASCAoC5y2fNSCNBpZ0HPMAvT0dEPEGPNrB/
e2SFmkvYxzS2oTDURiHCessJ6u3lSdVnTBhUp34gS3CfX+5FqvhJblf2h4UXsExO
zuqpw9srJ28ZLLvkog1AhoibfT4wbR8fZyHRScn0fRbD50oSqN3pIuIo/TQxkdam
psztbAQKoczKIrlYXlfyq1CIm7yRgKy5AS1QKdYH7nPmkpd/GmTtdOhjm/w4yAnF
VAcen/noyHrBkclBwsWRukLoe6Z32Pk33cIp+aPZyFK9V69Cu0Y4e6zQAjiTY3kd
kyK0n75dLqptKuh6rTpl1ej1SBGl7R6cbQKfRjmLidB2nIFBM/yJjp+DHSGPo/HD
P1rUVAWQGJKB5ApNSeOyGfM/8b/lPv03E8xh4y8J7HW2s4ljEgkixt5oFmEdhqpx
LeXevsdmhGCPEUdOcjzP72p0qwfZ2dMcQWeVngr9iMaJIU1uBZPqqHi63LHfrNkm
vWBtaianq5fbv03ec4p9+CQ7G29RClHUbMKHXfnJ74iYM6pujAmVl80Z6XkvvyQV
5XwXLlppulu+TdcUbx/6jt5IxI6Azr+3n++LLU/VOKtqui0D9nj9LiZdZ1GooEXS
OJkEtowglwku4/QdlxBIsNX3j3p8pwrCffoCNbjfXWUkZqiSUpqBZgL3rkWwyvQs
JLds9qGwMIxnVYM30MoiY2dL6YiGbfMzyJBUoxanCD1Ir+KiPbCP9sYkuydgx7OE
LX441Gw053MPl9z+8jzz/8T9YFnKQEwj934C96jjNevoPVWYjY6/5FedMzElpMCM
jffyFDaO8KURnn1lKv/kLiZ3e4d9FOYHUkOfXMTJ7Nla94r253NC72zr
-----END ENCRYPTED PRIVATE KEY-----
PEM
$signer->loadpkey(PEM => $pem, secret => 'the watcher and the tower');

