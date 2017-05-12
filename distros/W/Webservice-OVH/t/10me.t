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

    It is common that no contact change tasks are available so the single search of a task can't be tested.
    In the connected account should be at least one order. There must be something that was ordered, or else testing is senseless with that account.

=cut 

my $api = Webservice::OVH->new_from_json($json_dir);
ok($api, "module ok");

my $contacts = $api->me->contacts;
my $example_contact = $contacts->[0];
my $search_contact = $api->me->contact($example_contact->id);

my $tasks_contact_change = $api->me->tasks_contact_change;

my $orders = $api->me->orders;
my $example_order = $orders->[0];
my $search_order = $api->me->order($example_order->id);

my $bills = $api->me->bills;
my $example_bill = $bills->[0];
my $search_bill = $api->me->bill($example_bill->id);

ok( $contacts && ref $contacts eq 'ARRAY', 'Contacts ok' );
ok( $example_contact, 'contact exists ok' );
ok( $search_contact, 'contact found ok' );

ok( ref $tasks_contact_change eq 'ARRAY', 'task list ok');

ok( $orders && ref $orders eq 'ARRAY', 'orders ok');
ok( $example_order, 'one order exists ok');
ok( $search_order, 'order found ok' );

ok( $bills && ref $bills eq 'ARRAY', 'bills ok' );
ok( $example_bill, 'one bill exists ok' );
ok( $search_bill, 'bill found ok' );

ok( scalar keys %{$api->me->{_contacts}} == scalar @$contacts, 'intern contacts ok' );
ok( scalar keys %{$api->me->{_tasks_contact_change}} == scalar @$tasks_contact_change, 'intern tasks ok' );
ok( scalar keys %{$api->me->{_orders}} == scalar @$orders, 'intern orders ok' );
ok( scalar keys %{$api->me->{_bills}} == scalar @$bills, 'intern bills ok' );

done_testing();

