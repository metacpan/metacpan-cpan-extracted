use strict;
use warnings;
use utf8;

use Test::More tests => 5;
require bytes;

BEGIN {
  use_ok 'Win32';
  use_ok 'Win32API::Console', qw(
    GetOSVersion
  );
}

BEGIN { subtest "Import private helper's" => sub {
  can_ok('Win32API::Console' =>
    'CP_UTF8', 
    '_WideCharToMultiByte', 
    '_MultiByteToWideChar',
  );
  no warnings;
  *CP_UTF8             = Win32API::Console->can('CP_UTF8');
  *WideCharToMultiByte = Win32API::Console->can('_WideCharToMultiByte');
  *MultiByteToWideChar = Win32API::Console->can('_MultiByteToWideChar');
}}

subtest 'GetOSVersion' => sub {
  my $id = GetOSVersion();
  diag "$^E" if $^E;
  cmp_ok($id, '>=', Win32::GetOSVersion(), 'GetOSVersion() scalar context');

  my @ver = GetOSVersion();
  diag "$^E" if $^E;
  cmp_ok(@ver, '>=', 5, 'GetOSVersion() array context');
  note join(", " => @ver);
};

subtest 'WideCharToMultiByte and back' => sub {
  my $original = "Viele Grüße";

  # Convert multibyte to wide string (UTF-8 codepage)
  my $wide = MultiByteToWideChar($original, CP_UTF8);
  ok(defined $wide, 'MultiByteToWideChar returned a value');
  ok($wide, 'wide string is not empty');

  # Convert back to multibyte string
  my $mb = WideCharToMultiByte($wide, CP_UTF8);
  ok(defined $mb, 'WideCharToMultiByte returned a value');
  ok($mb, 'Multibyte string is not empty');
  is(
    bytes::substr($original, 0), 
    bytes::substr($mb, 0), 
    'Round-trip conversion preserved string'
  );
};

done_testing();
