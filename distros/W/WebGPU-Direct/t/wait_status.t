use v5.30;
use Test::More;

use WebGPU::Direct;

foreach my $status (qw/success timedOut/)
{
  my $status = WebGPU::Direct::WaitStatus->$status;
  isnt( $status, undef, "$status is a valid WaitStatus" );
  is( !!$status->is_success, 1,  "$status is a success" );
  is( !!$status->is_error,   '', "$status is not an error" );
}

foreach my $status (qw/unsupportedTimeout unsupportedCount unsupportedMixedSources/)
{
  my $status = WebGPU::Direct::WaitStatus->$status;
  isnt( $status, undef, "$status is a valid WaitStatus" );
  is( !!$status->is_success, '', "$status is a success" );
  is( !!$status->is_error,   1,  "$status is not an error" );
}

done_testing;
