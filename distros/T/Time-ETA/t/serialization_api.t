use strict;
use warnings;

use Time::ETA;
use Test::More;
use Time::HiRes qw(gettimeofday);

my $true = 1;
my $false = '';

my $precision = 0.1;

=head1 check_serialization_api_v_1

=cut

sub check_serialization_api_v_1 {
    my ($seconds, $microseconds) = gettimeofday;

    my $seconds_in_the_past = $seconds - 4;

    my $string = "---
_milestones: 10
_passed_milestones: 4
_start:
  - $seconds_in_the_past
  - $microseconds
_version: 1
";

    my $eta;
    eval {
        $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Version .* can work only with serialized data version 3\./,
        "spawn() does not support serialization api version 1.",
    );

}

=head2 check_serialization_api_v_2

The difference from version 1:

 * when the process is finished the field "_end" appear
 * after every pass_milestone() in the object _miliestone_pass gets the
   current time (and _miliestone_pass is stored in serialized object)

=cut

sub check_serialization_api_v_2 {
    my ($seconds, $microseconds) = gettimeofday;

    my $seconds_in_the_past = $seconds - 4;

    my $string = "---
_milestones: 10
_passed_milestones: 4
_start:
  - $seconds_in_the_past
  - $microseconds
_miliestone_pass:
  - $seconds
  - $microseconds
_version: 2
";

    my $eta;
    eval {
        $eta = Time::ETA->spawn($string);
    };

    like(
        $@,
        qr/Can't spawn Time::ETA object\. Version .* can work only with serialized data version 3\./,
        "spawn() does not support serialization api version 2.",
    );
}

=head2 check_serialization_api_v_3

The difference from version 2:

 * Added _is_paused and _elapsed.

=cut

sub check_serialization_api_v_3 {
    my ($seconds, $microseconds) = gettimeofday;

    my $seconds_in_the_past = $seconds - 4;

    my $string = "---
_milestones: 10
_passed_milestones: 4
_elapsed: 0
_is_paused: ''
_start:
  - $seconds_in_the_past
  - $microseconds
_milestone_pass:
  - $seconds
  - $microseconds
_version: 3
";

    my $eta = Time::ETA->spawn($string);

    my $percent = $eta->get_completed_percent();
    my $secs = $eta->get_remaining_seconds();

    is($percent, 40, "Got expected percent from respawned object");
    cmp_ok(abs($secs-6), "<", $precision, "Got expected remaining seconds from respawned object");
}

sub main {
    check_serialization_api_v_1();
    check_serialization_api_v_2();
    check_serialization_api_v_3();

    done_testing();
}

main();
