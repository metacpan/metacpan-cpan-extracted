use strict;
use warnings;
use utf8;

use Test::More tests => 6;
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
    'ERROR_SUCCESS',
    'ERROR_INVALID_HANDLE',
    'ERROR_MR_MID_NOT_FOUND',
    'FACILITY_WIN32',

    '_MultiByteToWideChar',
    '_WideCharToMultiByte', 

    '_HRESULT_CODE',
    '_HRESULT_FACILITY',
    '__HRESULT_FROM_WIN32',
  );
  no warnings;
  *CP_UTF8                = Win32API::Console->can('CP_UTF8');
  *ERROR_SUCCESS          = Win32API::Console->can('ERROR_SUCCESS');
  *ERROR_INVALID_HANDLE   = Win32API::Console->can('ERROR_INVALID_HANDLE');
  *ERROR_MR_MID_NOT_FOUND = Win32API::Console->can('ERROR_MR_MID_NOT_FOUND');
  *FACILITY_WIN32         = Win32API::Console->can('FACILITY_WIN32');

  *MultiByteToWideChar    = Win32API::Console->can('_MultiByteToWideChar');
  *WideCharToMultiByte    = Win32API::Console->can('_WideCharToMultiByte');

  *HRESULT_CODE           = Win32API::Console->can('_HRESULT_CODE');
  *HRESULT_FACILITY       = Win32API::Console->can('_HRESULT_FACILITY');
  *__HRESULT_FROM_WIN32   = Win32API::Console->can('__HRESULT_FROM_WIN32');
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

subtest 'HRESULT' => sub {
  is(
    __HRESULT_FROM_WIN32(ERROR_SUCCESS), ERROR_SUCCESS, 
    'HRESULT from Win32 success'
  );
  is(
    __HRESULT_FROM_WIN32(ERROR_INVALID_HANDLE), 0x80070006, 
    'HRESULT from Win32 error'
  );
  is(
    HRESULT_FACILITY(0x80070006), FACILITY_WIN32,
    'HRESULT_FACILITY calculation'
  );
  is(
    HRESULT_CODE(0x80070006), ERROR_INVALID_HANDLE, 
    'HRESULT_CODE calculation'
  );
};

done_testing();
