use Test2::V0 -no_srand => 1;
use Test2::Tools::Process;
use Capture::Tiny qw( capture_merged );

skip_all 'CI only' unless ($ENV{CIPSOMETHING}||'') eq 'true';

process {
  system 'true';
} [
  proc_event('system' => 'true'),
], 'normal';

process {
  system q{bash -c 'exit 22'};
} [
  proc_event('system' => q{bash -c 'exit 22'}, { status => 22 }),
], 'return non-zero';

process {
  capture_merged { system 'bogus' };
} [
  proc_event('system' => 'bogus', { errno => D() }),
], 'bad command';

process {
  capture_merged { system 'bash', -c => 'kill -9 $$' };
} [
  proc_event('system' => { signal => 9 }),
], 'signal';

done_testing;
