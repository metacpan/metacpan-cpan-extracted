use strict;
use Test::More;

use WebGPU::Direct;

my $wgpu = WebGPU::Direct->new;

subtest 'StringView by definition' => sub
{
  my $strlen = $wgpu->StringView->STRLEN;

  # `{NULL, WGPU_STRLEN}`: the null value.
  my $str1 = $wgpu->newStringView( { data => undef, length => $strlen } );
  is( $str1->as_string, undef, 'Definintion {NULL, WGPU_STRLEN} returns NULL/undef' );
  is( $str1->data, undef, 'Definintion {NULL, WGPU_STRLEN} returns NULL/undef' );
  is( "$str1",     '',    'Definintion {NULL, WGPU_STRLEN} stringifies to ""' );

  # `{non_null_pointer, WGPU_STRLEN}`: a null-terminated string view.
  my $str2 = $wgpu->newStringView( { data => "Something Something", length => $strlen } );
  is( $str2, 'Something Something', 'Definintion {non_null_pointer, WGPU_STRLEN} returns the string' );
  $str2 = $wgpu->newStringView( { data => "Something\0Something", length => $strlen } );
  is( $str2, 'Something', 'Definintion {non_null_pointer, WGPU_STRLEN} returns a null-terminated string' );

  # `{any, 0}`: the empty string.
  my $str3 = $wgpu->newStringView( { data => "", length => 0 } );
  is( $str3, '', 'Definintion {any, 0} returns an empty' );

  $str3 = $wgpu->newStringView( { data => "Something Something", length => 0 } );
  is( $str3, '', 'Definintion {any, 0} returns an empty' );

  # `{NULL, non_zero_length}`: not allowed (null dereference).
  my $error;
  my $str4 = eval { $wgpu->newStringView( { data => undef, length => 1 } ) };
  $error = $@;

  is( $str4, undef, 'Definintion {NULL, non_zero_length} does not work' );
  isnt( $error, undef, 'Definintion {NULL, non_zero_length} produces an error' );
  like( $error, qr/invalid/, 'Definintion {NULL, non_zero_length} error mentions invalid' );
  like( $error, qr/NULL/,    'Definintion {NULL, non_zero_length} error mentions NULL' );

  # `{non_null_pointer, non_zero_length}`: an explictly-sized string view with
  # size `non_zero_length` (in bytes).
  my $str5 = $wgpu->newStringView( { data => "Something Something", length => 19 } );
  is( $str5, 'Something Something', 'Definintion {non_null_pointer, non_zero_length} returns the string' );
  $str5 = $wgpu->newStringView( { data => "Something\0Something", length => 19 } );
  is( $str5, "Something\0Something",
    'Definintion {non_null_pointer, non_zero_length} returns a null-including string' );
  $str5 = $wgpu->newStringView( { data => "Something\0Something", length => 18 } );
  is( $str5, "Something\0Somethin", 'Definintion {non_null_pointer, non_zero_length} returns a string ends early' );
};

my $strv = $wgpu->newStringView("Something\0Something");
my $stre = $wgpu->newStringView( {} );

my $adapter = $wgpu->createAdapter( { compatibleSurface => undef } );

my $info = WebGPU::Direct::AdapterInfo->new;
$adapter->getInfo($info);

done_testing;
