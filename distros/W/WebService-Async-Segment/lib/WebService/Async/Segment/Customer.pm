package WebService::Async::Segment::Customer;

use strict;
use warnings;

use constant COMMON_FIELDS => qw(context integrations timestamp);

our $VERSION = '0.001';    # VERSION

=head1 NAME

WebService::Async::Segment::Customer - represents a customer object with methods to make Segment API calls.

=head1 DESCRIPTION

You can create objects directly or (preferably) indirectly using C<< WebService::Async::Segment::new_customer >>.
Segment calls L</identify> and L</track> can be triggered on objects of this class.

=cut

=head1 METHODS

=head2 new

Class constructor accepting a hash of named args containing customer info, along with a Segment API wrapper object (an object of class L<WebService::Async::Segment::Customer>).
There is no need to make this call if you create an object using C<< WebService::Async::Segment::new_customer >> (as recommended).

The accepted params are:

=over 4

=item * C<api_client> - Segment API wrapper object.

=item * C<user_id> or C<userId> - Unique identifier of a user.

=item * C<anonymous_id> or C<anonymousId> - A pseudo-unique substitute for a User ID, for cases when you don't have an absolutely unique identifier.

=item * C<traits> - Free-form dictionary of traits of the user, like email or name.

=back

=cut

sub new {
    my ($class, %args) = @_;

    die 'Missing required arg api_client' unless $args{api_client};
    my $api_client = $args{api_client};
    die 'Invalid api_client value' unless $api_client->isa('WebService::Async::Segment');

    my $self;

    $args{user_id}      = delete $args{userId}      if $args{userId};
    $args{anonymous_id} = delete $args{anonymousId} if $args{anonymousId};

    $self->{$_} = $args{$_} for (qw(api_client user_id anonymous_id));
    $self->{traits} = {%{$args{traits}}} if $args{traits};

    bless $self, $class;

    return $self;
}

=head2 user_id

Unique identifier for the user in the database.

=cut

sub user_id { shift->{user_id} }

=head2 anonymous_id

A pseudo-unique substitute for a User ID, for cases when you don't have an absolutely unique identifier.

=cut

sub anonymous_id { shift->{anonymous_id} }

=head2 traits

Free-form dictionary of traits of the user, containg both standard and custom attributes.
For more information on standard (reserved) traits please refer to L<https://segment.com/docs/spec/identify/#traits>.

=cut

sub traits { shift->{traits} }

=head2 api_client

A C<WebService::Async::Segment> object acting as Segment HTTP API client.

=cut

sub api_client { shift->{api_client} }

=head2 identify

Makes an B<identify> call on the current customer.
For a detailed information on the API call please refer to: L<https://segment.com/docs/spec/identify/>.

It can be called with the following named params:

=over

=item * C<user_id> or C<userId> - Unique identifier of a user (will overwrite object's attribute).

=item * C<anonymous_id> or C<anonymousId> - A pseudo-unique substitute for a User ID (will overwrite object's attribute).

=item * C<traits> - Free-form dictionary of traits of the user, like email or name (will overwrite object's attribute).

=item * C<context> - Context information of the API call.
Note that the API wrapper automatically sets context B<sentAt> and B<library> fields.

=item * C<integrations> -  Dictionary of destinations to either enable or disable.

=item * C<timestamp> - Timestamp when the message itself took place, defaulted to the current time by the Segment Tracking API. It is an ISO-8601 date string

=item * C<custom> - Dictionary of custom business specific fileds.

=back

About common fields please refer to: L<https://segment.com/docs/spec/common/>.

It returns a L<Future> object.

=cut

sub identify {
    my ($self, %args) = @_;

    $args{traits} //= $self->traits if $self->traits;

    $args{user_id}      = delete $args{userId}      if $args{userId};
    $args{anonymous_id} = delete $args{anonymousId} if $args{anonymousId};

    my %call_args = $self->_make_call_args(\%args, [COMMON_FIELDS, qw(user_id anonymous_id traits)]);

    return $self->api_client->method_call('identify', %call_args)->then(
        sub {
            for (qw(user_id anonymous_id)) {
                $self->{$_} = $args{$_} if $args{$_};
            }
            $self->{traits} = {%{$args{traits}}} if $args{traits};

            return Future->done(@_);
        })->retain;
}

=head2 track

Makes a B<track> call on the current customer. It can take any standard (B<event> and B<properties>), common or custom fields.
For more information on track API please refer to L<https://segment.com/docs/spec/track/>.

It can be called with the following parameters:

=over

=item * C<event> - required. event name.

=item * C<properties> - Free-form dictionary of event properties.

=item * C<context> - Context information of the API call.
Note that the API wrapper automatically sets context B<sentAt> and B<library> fields.

=item * C<integrations> -  Dictionary of destinations to either enable or disable.

=item * C<timestamp> - Timestamp when the message itself took place, defaulted to the current time by the Segment Tracking API. It is an ISO-8601 date string.

=item * C<custom> - Dictionary of custom business specific fileds.

=back

About common API call params: L<https://segment.com/docs/spec/common/>.

It returns a L<Future> object.

=cut

sub track {
    my ($self, %args) = @_;

    return Future->fail('ValidationError', 'segment', 'Missing required argument "event"') unless $args{event};

    my %call_args = $self->_make_call_args(\%args, [COMMON_FIELDS, qw(event properties)]);

    return $self->api_client->method_call('track', %call_args);
}

sub _make_call_args {
    my ($self, $args, $accepted_fields) = @_;
    $args //= {};
    my $custom = delete $args->{custom} // {};

    for my $field (keys %$args) {
        delete $args->{$field} unless grep { $field eq $_ } (@$accepted_fields);
    }

    for (qw(user_id anonymous_id)) {
        $args->{$_} //= $self->$_ if $self->$_;
    }

    my %call_args = map { $args->{$_} ? ($_ => $args->{$_}) : () } (keys %$args);

    return (%$custom, %call_args);
}

1;

__END__

=head1 AUTHOR

deriv.com C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright deriv.com 2019. Licensed under the same terms as Perl itself.
