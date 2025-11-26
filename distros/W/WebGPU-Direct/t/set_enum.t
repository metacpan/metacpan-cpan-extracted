use v5.30;
use Test::More;

use WebGPU::Direct;
use Data::Dumper;

my $wgpu = WebGPU::Direct->new;

# Defaults with inline structs
{
  my $a = $wgpu->ChainedStruct->new(
    {
      sType => 'renderPassMaxDrawCount',
    }
  );

  cmp_ok( $a->sType, '==', $wgpu->SType->renderPassMaxDrawCount, 'sType was set by name' );
  cmp_ok( $a->sType, 'eq', $wgpu->SType->renderPassMaxDrawCount, 'Setting by name used dualvar version' );
}

done_testing;
