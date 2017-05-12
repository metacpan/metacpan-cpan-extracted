#!perl

use Test::More tests => 18;
use Time::Local;
use Cwd;

BEGIN {
    use_ok( 'Timer::Runtime' ) || print "Bail out!";
}

diag( "Testing Timer::Runtime $Timer::Runtime::VERSION, Perl $], $^X" );

ok( "-e t/timer-runtime-test.pl", "t/timer-runtime-test.pl file exists" );


my $output = `perl t/timer-runtime-test.pl`;
isnt( $output, -1, "ran timer-runtime-test.pl tester successfully" );

my ( $start, $stop ) = split "\n", $output;

my @months       = qw{ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec };
my @days         = ( 1 .. 31 );
my @days_of_week = qw{ Sun Mon Tue Wed Thur Fri Sat };
my @hours        = ( 0 .. 23 );
my @minutes      = ( 0 .. 59 );
my @seconds      = ( 0 .. 59 );

like( $start, qr/timer-runtime-test.pl Started:/,  "got start time okay: $start" );
like( $stop,  qr/timer-runtime-test.pl Finished:/, "got end time okay: $stop" );

$start =~ m/Started: (.*?)$/;
my $start_time = $1;
$stop  =~ m/Finished: (.*?),/;
my $stop_time = $1;
$stop  =~ m/, elapsed time = (.*?)$/;
my $elapsed_time = $1;


#  check start time
my ( $start_day_of_week, $start_month, $start_day, $start_times ) = split " ", $start_time;
my ( $start_hour, $start_minute, $start_second ) = split ":", $start_times;

ok( (grep{ m/$start_day_of_week/ } @days_of_week), "start - got valid day of week: $start_day_of_week" );
ok( (grep{ m/$start_month/ } @months), "start - got valid month: $start_month" );
ok( (grep{ m/$start_day/ } @days), "start - got valid day: $start_day" );
ok( (grep{ $_ == $start_hour } @hours), "start - got valid hour: $start_hour" );
ok( (grep{ $_ == $start_minute } @minutes), "start - got valid minute: $start_minute" );
ok( (grep{ $_ == $start_second } @seconds), "start - got valid second: $start_second" );


#  check stop time
my ( $stop_day_of_week, $stop_month, $stop_day, $stop_times ) = split " ", $stop_time;
my ( $stop_hour, $stop_minute, $stop_second ) = split ":", $stop_times;

ok( ( grep{ m/$stop_day_of_week/ } @days_of_week ), "stop - got valid day of week: $stop_day_of_week" );
ok( ( grep{ m/$stop_month/ } @months ), "stop - got valid month: $stop_month" );
ok( ( grep{ m/$stop_day/ } @days ), "stop - got valid day: $stop_day" );
ok( ( grep{ $_ == $stop_hour } @hours ), "stop - got valid hour: $stop_hour" );
ok( ( grep{ $_ == $stop_minute } @minutes ), "stop - got valid minute: $stop_minute" );
ok( ( grep{ $_ == $stop_second } @seconds ), "stop - got valid second: $stop_second" );

#  checked elapsed time
like( $elapsed_time, qr/\d\d:\d\d:\d\d.\d\d\d\d\d\d/, "got elapsed time: $elapsed_time" );


