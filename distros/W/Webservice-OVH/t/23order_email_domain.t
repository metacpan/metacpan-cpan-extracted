use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ($json_dir && -e $json_dir) {  plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

=head2

    new can't be tested, because an order is directly created when called

=cut
my $api = Webservice::OVH->new_from_json($json_dir);
ok($api, "module ok");
=head2

my $services = $api->order->email->domain->available_services;
ok( $services && ref $services eq 'ARRAY' && scalar @$services > 0, 'available_services ok');

my $allowed_durations = $api->order->email->domain->allowed_durations($services->[0], '100');
ok( $allowed_durations && ref $allowed_durations eq 'ARRAY' && scalar @$allowed_durations > 0, 'allowed_durations ok');

my $info = $api->order->email->domain->info($services->[0], '100', $allowed_durations->[0]);
ok($info && ref $info eq 'HASH', 'info ok' );
=cut
done_testing();