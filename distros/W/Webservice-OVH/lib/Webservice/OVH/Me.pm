package Webservice::OVH::Me;

=encoding utf-8

=head1 NAME

Webservice::OVH::Me

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $contacts = $ovh->me->contacts;
    my $tasks_contact_change = $ovh->me->tasks_contact_change;
    my $orders = $ovh->me->orders(DateTime->now->sub(days => -1), DateTime->now);
    my $bills = $ovh->me->bills(DateTime->now->sub(days => -1), DateTime->now);
    
    my $bill_id = $bills->[0]->id;
    my $order_id = $orders->[0]->id;
    
    my $bill = $me->ovh->bill($bill_id);
    my $order = $me->ovh->bill($order_id);
    
    print $bill->pdf_url;
    print $order->url;

=head1 DESCRIPTION

Module support for now only basic retrieval methods for contacs, tasks, orders and bills

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };
use Webservice::OVH::Helper;

our $VERSION = 0.48;

# sub modules
use Webservice::OVH::Me::Contact;
use Webservice::OVH::Me::Order;
use Webservice::OVH::Me::Bill;
use Webservice::OVH::Me::Task;

=head2 _new

Internal Method to create the me object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Me>

=item * Synopsis: Webservice::OVH::Me->_new($ovh_api_wrapper, $self);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _contacts => {}, _tasks_contact_change => {}, _orders => {}, _bills => {} }, $class;

    return $self;
}

=head2 contacts

Produces an array of all available contacts that are stored for the used account.

=over

=item * Return: ARRAY

=item * Synopsis: my $contacts = $ovh->me->contacs();

=back

=cut

sub contacts {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/me/contact", noSignature => 0 );
    croak $response->error if $response->error;

    my $contact_ids = $response->content;
    my $contacts    = [];

    foreach my $contact_id (@$contact_ids) {

        my $contact = $self->{_contacts}{$contact_id} = $self->{_contacts}{$contact_id} || Webservice::OVH::Me::Contact->_new_existing( wrapper => $api, id => $contact_id, module => $self->{_module} );
        push @$contacts, $contact;
    }

    return $contacts;
}

=head2 contact

Returns a single contact by id

=over

=item * Parameter: $contact_id - id

=item * Return: L<Webservice::OVH::Me::Contact>

=item * Synopsis: my $contact = $ovh->me->contact(1234567);

=back

=cut

sub contact {

    my ( $self, $contact_id ) = @_;

    my $api = $self->{_api_wrapper};
    my $contact = $self->{_contacts}{$contact_id} = $self->{_contacts}{$contact_id} || Webservice::OVH::Me::Contact->_new_existing( wrapper => $api, id => $contact_id, module => $self->{_module} );

    return $contact;
}

=head2 tasks_contact_change

Produces an array of all available contact change tasks.

=over

=item * Return: ARRAY

=item * Synopsis: my $tasks = $ovh->me->tasks_contact_change();

=back

=cut

sub tasks_contact_change {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/me/task/contactChange", noSignature => 0 );
    croak $response->error if $response->error;

    my $task_ids = $response->content;
    my $tasks    = [];

    foreach my $task_id (@$task_ids) {

        my $task = $self->{_tasks_contact_change}{$task_id} = $self->{_tasks_contact_change}{$task_id} || Webservice::OVH::Me::Task->_new( wrapper => $api, type => "contact_change", id => $task_id, module => $self->{_module} );
        push @$tasks, $task;
    }

    return $tasks;
}

=head2 task_contact_change

Returns a single contact change task by id

=over

=item * Parameter: $task_id - id

=item * Return: L<Webservice::OVH::Me::Task>

=item * Synopsis: my $contact = $ovh->me->task_contact_change(1234567);

=back

=cut

sub task_contact_change {

    my ( $self, $task_id ) = @_;

    my $api = $self->{_api_wrapper};
    my $task = $self->{_tasks_contact_change}{$task_id} = $self->{_tasks_contact_change}{$task_id} || Webservice::OVH::Me::Task->_new( wrapper => $api, type => "contact_change", id => $task_id, module => $self->{_module} );

    return $task;

}

=head2 orders

Produces an array of all available orders.
Orders can be optionally filtered by date.

=over

=item * Parameter: $date_from - optional filter DateTime, $date_to - optional filter DateTime

=item * Return: ARRAY

=item * Synopsis: my $orders = $ovh->me->orders(DateTime->new(), DateTime->new());

=back

=cut

sub orders {

    my ( $self, $date_from, $date_to ) = @_;

    my $str_date_from = $date_from ? $date_from->strftime("%Y-%m-%d") : "";
    my $str_date_to   = $date_to   ? $date_to->strftime("%Y-%m-%d")   : "";
    my $filter = Webservice::OVH::Helper->construct_filter( "date.from" => $str_date_from, "date.to" => $str_date_to );

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/me/order$filter", noSignature => 0 );
    croak $response->error if $response->error;

    my $order_ids = $response->content;
    my $orders    = [];

    foreach my $order_id (@$order_ids) {

        my $order = $self->{_orders}{$order_id} = $self->{_orders}{$order_id} || Webservice::OVH::Me::Order->_new( wrapper => $api, id => $order_id, module => $self->{_module} );
        push @$orders, $order;
    }

    return $orders;
}

=head2 order

Returns a single order by id

=over

=item * Parameter: $order_id - id

=item * Return: L<Webservice::OVH::Me::Order>

=item * Synopsis: my $order = $ovh->me->order(1234567);

=back

=cut

sub order {

    my ( $self, $order_id ) = @_;

    my $api = $self->{_api_wrapper};
    my $order = $self->{_orders}{$order_id} = $self->{_orders}{$order_id} || Webservice::OVH::Me::Order->_new( wrapper => $api, id => $order_id, module => $self->{_module} );

    return $order;
}

=head2 bill

Returns a single bill by id

=over

=item * Parameter: $bill_id - id

=item * Return: L<Webservice::OVH::Me::Bill>

=item * Synopsis: my $order = $ovh->me->bill(1234567);

=back

=cut

sub bill {

    my ( $self, $bill_id ) = @_;

    my $api = $self->{_api_wrapper};
    my $bill = $self->{_bills}{$bill_id} = $self->{_bills}{$bill_id} || Webservice::OVH::Me::Bill->_new( wrapper => $api, id => $bill_id, module => $self->{_module} );

    return $bill;
}

=head2 bills

Produces an array of all available bills.
Bills can be optionally filtered by date.

=over

=item * Parameter: $date_from - optional filter DateTime, $date_to - optional filter DateTime

=item * Return: ARRAY

=item * Synopsis: my $bills = $ovh->me->bills(DateTime->new(), DateTime->new());

=back

=cut

sub bills {

    my ( $self, $date_from, $date_to ) = @_;

    my $str_date_from = $date_from ? $date_from->strftime("%Y-%m-%d") : "";
    my $str_date_to   = $date_to   ? $date_to->strftime("%Y-%m-%d")   : "";
    my $filter = Webservice::OVH::Helper->construct_filter( "date.from" => $str_date_from, "date.to" => $str_date_to );

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => sprintf( "/me/bill%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    my $bill_ids = $response->content;
    my $bills    = [];

    foreach my $bill_id (@$bill_ids) {

        my $bill = $self->{_bills}{$bill_id} = $self->{_bills}{$bill_id} || Webservice::OVH::Me::Bill->_new( wrapper => $api, id => $bill_id, module => $self->{_module} );
        push @$bills, $bill;
    }

    return $bills;
}

1;
