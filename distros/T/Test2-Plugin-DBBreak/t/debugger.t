use Test2::V0;
use Test2::Plugin::DBBreak;

our $curr_dir;

BEGIN {
  $0 =~ '(.*[\\\/])\w+\.\w+$';
  $curr_dir = $1 || "./";
}

my $pass = `perl -d ${curr_dir}tests/pass.t 2>&1`;
unlike( $pass, qr/DBBreak/, "Breakpoint did not occur" );

my $fail = `perl -d ${curr_dir}tests/failnobreak.t 2>&1`;
unlike( $fail, qr/DBBreak/, "Breakpoint occurred" );

$fail = `perl -d ${curr_dir}tests/fail.t 2>&1`;
like( $fail, qr/DBBreak/, "Breakpoint occurred" );

done_testing;

exit;
