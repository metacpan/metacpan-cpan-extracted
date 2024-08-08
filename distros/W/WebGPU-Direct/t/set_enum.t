use v5.30;
use Test::More;
use Scalar::Util qw/refaddr/;

use WebGPU::Direct;
use Data::Dumper;

my $wgpu = WebGPU::Direct->new;

# Defaults with inline structs
{
  my $a = $wgpu->ChainedStruct->new(
    {
      sType => 'renderPassDescriptorMaxDrawCount',
    }
  );

  cmp_ok( $a->sType, '==', $wgpu->SType->renderPassDescriptorMaxDrawCount, 'sType was set by name' );
  cmp_ok( $a->sType, 'eq', $wgpu->SType->renderPassDescriptorMaxDrawCount, 'Setting by name used dualvar version' );
}

{
  my $a = $wgpu->ChainedStruct->new(
    {
      sType => 'invalid',
    }
  );

  cmp_ok( $a->sType, '==', $wgpu->SType->invalid, 'sType was set by name' );
  cmp_ok( $a->sType, 'eq', $wgpu->SType->invalid, 'Setting by name used dualvar version' );
}

done_testing;
