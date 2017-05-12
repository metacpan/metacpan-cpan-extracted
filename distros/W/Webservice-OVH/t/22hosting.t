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

ok ($api->order->hosting, 'hosting ok');
ok ($api->order->hosting->web, 'web ok');

done_testing();