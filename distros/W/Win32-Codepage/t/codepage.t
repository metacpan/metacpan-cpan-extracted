#!perl -w

BEGIN
{ 
   use Test::More tests => 11;
   use_ok(Win32::Codepage);
}

use warnings;
use strict;
use Carp;
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::confess;

my $result;

$result = Win32::Codepage::get_encoding();
diag "got encoding: $result";
ok($result, "get_encoding");
like($result, qr/^cp[\da-f]+$/, "get_encoding");

$result = Win32::Codepage::get_ms_codepage();
diag "got Microsoft's code for the current codepage: $result";
ok($result, "get_ms_codepage");
like($result, qr/^\d+$/, "get_ms_codepage");

$result = Win32::Codepage::get_ms_install_codepage();
diag "got Microsoft's code for the installed codepage: $result";
ok($result, "get_ms_install_codepage");
like($result, qr/^\d+$/, "get_ms_install_codepage");

$result = Win32::Codepage::get_codepage();
diag "got lang for the current codepage: $result";
ok($result, "get_codepage");
like($result, qr/^[a-z]{2}(?:-[a-z]+)?$/, "get_codepage");

$result = Win32::Codepage::get_install_codepage();
diag "got lang for the installed codepage: $result";
ok($result, "get_install_codepage");
like($result, qr/^[a-z]{2}(?:-[a-z]+)?$/, "get_install_codepage");
