package WWW::TypePad::ExternalFeedSubscriptions;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::external_feed_subscriptions { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::ExternalFeedSubscriptions - ExternalFeedSubscriptions API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item delete

  my $res = $tp->external_feed_subscriptions->delete($id);

Remove the selected subscription.

Returns ExternalFeedSubscription which contains following properties.

=over 8

=item urlId

(string) The canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item callbackUrl

(string) The URL to which to send notifications of new items in this subscription's feeds.

=item callbackStatus

(string) The HTTP status code that was returned by the last call to the subscription's callback URL.

=item filterRules

(arrayE<lt>stringE<gt>) A list of rules for filtering notifications to this subscription. Each rule is a full-text search query string, like those used with the NE<lt>/assetsE<gt> endpoint. An item will be delivered to the ME<lt>callbackUrlE<gt> if it matches any one of these query strings.

=item postAsUserId

(arrayE<lt>stringE<gt>) For a Group-owned subscription, the urlId of the User who will own the items posted into the group by the subscription.


=back

=cut

sub delete {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s.json', @args;
    $api->base->call("DELETE", $uri, @_);
}


=pod



=item get

  my $res = $tp->external_feed_subscriptions->get($id);

Get basic information about the selected subscription.

Returns ExternalFeedSubscription which contains following properties.

=over 8

=item urlId

(string) The canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item callbackUrl

(string) The URL to which to send notifications of new items in this subscription's feeds.

=item callbackStatus

(string) The HTTP status code that was returned by the last call to the subscription's callback URL.

=item filterRules

(arrayE<lt>stringE<gt>) A list of rules for filtering notifications to this subscription. Each rule is a full-text search query string, like those used with the NE<lt>/assetsE<gt> endpoint. An item will be delivered to the ME<lt>callbackUrlE<gt> if it matches any one of these query strings.

=item postAsUserId

(arrayE<lt>stringE<gt>) For a Group-owned subscription, the urlId of the User who will own the items posted into the group by the subscription.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item add_feeds

  my $res = $tp->external_feed_subscriptions->add_feeds($id);

Add one or more feed identifiers to the subscription.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub add_feeds {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s/add-feeds.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_feeds

  my $res = $tp->external_feed_subscriptions->get_feeds($id);

Get a list of strings containing the identifiers of the feeds to which this subscription is subscribed.

Returns ListE<lt>stringE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>stringE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_feeds {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s/feeds.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub feeds {
    my $self = shift;
    Carp::carp("'feeds' is deprecated. Use 'get_feeds' instead.");
    $self->get_feeds(@_);
}

=pod



=item remove_feeds

  my $res = $tp->external_feed_subscriptions->remove_feeds($id);

Remove one or more feed identifiers from the subscription.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub remove_feeds {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s/remove-feeds.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item update_filters

  my $res = $tp->external_feed_subscriptions->update_filters($id);

Change the filtering rules for the subscription.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub update_filters {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s/update-filters.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item update_notification_settings

  my $res = $tp->external_feed_subscriptions->update_notification_settings($id);

Change the callback URL and/or secret for the subscription.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub update_notification_settings {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s/update-notification-settings.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item update_user

  my $res = $tp->external_feed_subscriptions->update_user($id);

Change the "post as" user for a subscription owned by a group.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub update_user {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/external-feed-subscriptions/%s/update-user.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
