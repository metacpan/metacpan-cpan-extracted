package WWW::TypePad::Users;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::users { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Users - Users API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->users->get($id);

Get basic information about the selected user.

Returns User which contains following properties.

=over 8

=item displayName

(string) The user's chosen display name.

=item location

(string) BE<lt>DeprecatedE<gt> The user's location, as a free-form string provided by them. Use the the ME<lt>locationE<gt> property of the related OE<lt>UserProfileE<gt> object, which can be retrieved from the NE<lt>/users/{id}/profileE<gt> endpoint.

=item interests

(arrayE<lt>stringE<gt>) BE<lt>DeprecatedE<gt> A list of interests provided by the user and displayed on the user's profile page. Use the ME<lt>interestsE<gt> property of the OE<lt>UserProfileE<gt> object, which can be retrieved from the NE<lt>/users/{id}/profileE<gt> endpoint.

=item preferredUsername

(string) The name the user has chosen for use in the URL of their TypePad profile page. This property can be used to select this user in URLs, although it is not a persistent key, as the user can change it at any time.

=item avatarLink

(ImageLink) A link to an image representing this user.

=item profilePageUrl

(string) The URL of the user's TypePad profile page.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>DeprecatedE<gt> An array of object type identifier URIs.

=item objectType

(string) The keyword identifying the type of object this is. For a User object, ME<lt>objectTypeE<gt> will be CE<lt>UserE<gt>.

=item email

(string) BE<lt>DeprecatedE<gt> The user's email address. This property is only provided for authenticated requests if the user has shared it with the authenticated application, and the authenticated user is allowed to view it (as with administrators of groups the user has joined). In all other cases, this property is omitted.

=item gender

(string) BE<lt>DeprecatedE<gt> The user's gender, as they provided it. This property is only provided for authenticated requests if the user has shared it with the authenticated application, and the authenticated user is allowed to view it (as with administrators of groups the user has joined). In all other cases, this property is omitted.

=item id

(string) A URI that serves as a globally unique identifier for the object.

=item urlId

(string) A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.


=back

=cut

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item get_badges

  my $res = $tp->users->get_badges($id);

Get a list of badges that the selected user has won.

Returns ListE<lt>UserBadgeE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>UserBadgeE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_badges {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/badges.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub badges {
    my $self = shift;
    Carp::carp("'badges' is deprecated. Use 'get_badges' instead.");
    $self->get_badges(@_);
}

=pod



=item get_learning_badges

  my $res = $tp->users->get_learning_badges($id);

Get a list of learning badges that the selected user has won.

Returns ListE<lt>UserBadgeE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>UserBadgeE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_learning_badges {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/badges/@learning.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub learning_badges {
    my $self = shift;
    Carp::carp("'learning_badges' is deprecated. Use 'get_learning_badges' instead.");
    $self->get_learning_badges(@_);
}

=pod



=item get_public_badges

  my $res = $tp->users->get_public_badges($id);

Get a list of public badges that the selected user has won.

Returns ListE<lt>UserBadgeE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>UserBadgeE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_public_badges {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/badges/@public.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub public_badges {
    my $self = shift;
    Carp::carp("'public_badges' is deprecated. Use 'get_public_badges' instead.");
    $self->get_public_badges(@_);
}

=pod



=item get_blogs

  my $res = $tp->users->get_blogs($id);

Get a list of blogs that the selected user has access to.

Returns ListE<lt>BlogE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>BlogE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_blogs {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/blogs.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub blogs {
    my $self = shift;
    Carp::carp("'blogs' is deprecated. Use 'get_blogs' instead.");
    $self->get_blogs(@_);
}

=pod



=item get_elsewhere_accounts

  my $res = $tp->users->get_elsewhere_accounts($id);

Get a list of elsewhere accounts for the selected user.

Returns ListE<lt>AccountE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>AccountE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_elsewhere_accounts {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/elsewhere-accounts.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub elsewhere_accounts {
    my $self = shift;
    Carp::carp("'elsewhere_accounts' is deprecated. Use 'get_elsewhere_accounts' instead.");
    $self->get_elsewhere_accounts(@_);
}

=pod



=item get_events

  my $res = $tp->users->get_events($id);

Get a list of events describing actions that the selected user performed.

Returns StreamE<lt>EventE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole stream of which this response contains a subset. CE<lt>nullE<gt> if an exact count cannot be determined.

=item estimatedTotalResults

(integer) An estimate of the total number of items in the whole list of which this response contains a subset. CE<lt>nullE<gt> if a count cannot be determined at all, or if an exact count is returned in CE<lt>totalResultsE<gt>.

=item moreResultsToken

(string) An opaque token that can be used as the CE<lt>start-tokenE<gt> parameter of a followup request to retrieve additional results. CE<lt>nullE<gt> if there are no more results to retrieve, but the presence of this token does not guarantee that the response to a followup request will actually contain results.

=item entries

(arrayE<lt>EventE<gt>) A selection of items from the underlying stream.


=back

=cut

sub get_events {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/events.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub events {
    my $self = shift;
    Carp::carp("'events' is deprecated. Use 'get_events' instead.");
    $self->get_events(@_);
}

=pod



=item get_events_by_group

  my $res = $tp->users->get_events_by_group($id, $groupId);

Get a list of events describing actions that the selected user performed in a particular group.

Returns ListE<lt>EventE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>EventE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_events_by_group {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # groupId
    my $uri = sprintf '/users/%s/events/@by-group/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub events_by_group {
    my $self = shift;
    Carp::carp("'events_by_group' is deprecated. Use 'get_events_by_group' instead.");
    $self->get_events_by_group(@_);
}

=pod



=item post_to_favorites

  my $res = $tp->users->post_to_favorites($id);

Create a new favorite in the selected user's list of favorites.

Returns Favorite which contains following properties.

=over 8

=item id

(string) A URI that serves as a globally unique identifier for the favorite.

=item urlId

(string) A string containing the canonical identifier that can be used to identify this favorite in URLs. This can be used to recognise where the same favorite is returned in response to different requests, and as a mapping key for an application's local data store.

=item author

(User) The user who saved this favorite. That is, this property is the user who saved the target asset as a favorite, not the creator of that asset.

=item inReplyTo

(AssetRef) A reference to the target asset that has been marked as a favorite.

=item published

(datetime) The time that the favorite was created, as a W3CDTF timestamp.


=back

=cut

sub post_to_favorites {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/favorites.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_favorites

  my $res = $tp->users->get_favorites($id);

Get a list of favorites that were listed by the selected user.

Returns ListE<lt>FavoriteE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>FavoriteE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_favorites {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/favorites.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub favorites {
    my $self = shift;
    Carp::carp("'favorites' is deprecated. Use 'get_favorites' instead.");
    $self->get_favorites(@_);
}

=pod



=item get_memberships

  my $res = $tp->users->get_memberships($id);

Get a list of relationships that the selected user has with groups.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_memberships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/memberships.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub memberships {
    my $self = shift;
    Carp::carp("'memberships' is deprecated. Use 'get_memberships' instead.");
    $self->get_memberships(@_);
}

=pod



=item get_admin_memberships

  my $res = $tp->users->get_admin_memberships($id);

Get a list of relationships that have an Admin type that the selected user has with groups.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_admin_memberships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/memberships/@admin.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub admin_memberships {
    my $self = shift;
    Carp::carp("'admin_memberships' is deprecated. Use 'get_admin_memberships' instead.");
    $self->get_admin_memberships(@_);
}

=pod



=item get_memberships_by_group

  my $res = $tp->users->get_memberships_by_group($id, $groupId);

Get a list containing only the relationship between the selected user and a particular group, or an empty list if the user has no relationship with the group.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_memberships_by_group {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # groupId
    my $uri = sprintf '/users/%s/memberships/@by-group/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub memberships_by_group {
    my $self = shift;
    Carp::carp("'memberships_by_group' is deprecated. Use 'get_memberships_by_group' instead.");
    $self->get_memberships_by_group(@_);
}

=pod



=item get_member_memberships

  my $res = $tp->users->get_member_memberships($id);

Get a list of relationships that have a Member type that the selected user has with groups.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_member_memberships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/memberships/@member.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub member_memberships {
    my $self = shift;
    Carp::carp("'member_memberships' is deprecated. Use 'get_member_memberships' instead.");
    $self->get_member_memberships(@_);
}

=pod



=item get_notifications

  my $res = $tp->users->get_notifications($id);

Get a list of events describing actions by users that the selected user is following.

Returns ListE<lt>EventE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>EventE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_notifications {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/notifications.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub notifications {
    my $self = shift;
    Carp::carp("'notifications' is deprecated. Use 'get_notifications' instead.");
    $self->get_notifications(@_);
}

=pod



=item get_notifications_by_group

  my $res = $tp->users->get_notifications_by_group($id, $groupId);

Get a list of events describing actions in a particular group by users that the selected user is following.

Returns ListE<lt>EventE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>EventE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_notifications_by_group {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # groupId
    my $uri = sprintf '/users/%s/notifications/@by-group/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub notifications_by_group {
    my $self = shift;
    Carp::carp("'notifications_by_group' is deprecated. Use 'get_notifications_by_group' instead.");
    $self->get_notifications_by_group(@_);
}

=pod



=item get_profile

  my $res = $tp->users->get_profile($id);

Get a more extensive set of user properties that can be used to build a user profile page.

Returns UserProfile which contains following properties.

=over 8

=item id

(string) The URI from the related OE<lt>UserE<gt> object's ME<lt>idE<gt> property.

=item urlId

(string) The canonical identifier from the related OE<lt>UserE<gt> object's ME<lt>urlIdE<gt> property.

=item displayName

(string) The user's chosen display name.

=item location

(string) The user's location, as a free-form string they provided.

=item aboutMe

(string) The user's long description or biography, as a free-form string they provided.

=item interests

(arrayE<lt>stringE<gt>) A list of interests provided by the user and displayed on their profile page.

=item preferredUsername

(string) The name the user has chosen for use in the URL of their TypePad profile page. This property can be used to select this user in URLs, although it is not a persistent key, as the user can change it at any time.

=item avatarLink

(ImageLink) A link to an image representing this user.

=item profilePageUrl

(string) The URL of the user's TypePad profile page.

=item followFrameContentUrl

(string) The URL of a widget that, when rendered in an CE<lt>iframeE<gt>, allows viewers to follow this user. Render this widget in an CE<lt>iframeE<gt> 300 pixels wide and 125 pixels high.

=item profileEditPageUrl

(string) The URL of a page where this user can edit their profile information. If this is not the authenticated user's UserProfile object, this property is omitted.

=item membershipManagementPageUrl

(string) The URL of a page where this user can manage their group memberships. If this is not the authenticated user's UserProfile object, this property is omitted.

=item homepageUrl

(string) The address of the user's homepage, as a URL they provided. This property is omitted if the user has not provided a homepage.

=item email

(string) The user's email address. This property is only provided for authenticated requests if the user has shared it with the authenticated application, and the authenticated user is allowed to view it (as with administrators of groups the user has joined). In all other cases, this property is omitted.

=item gender

(string) The user's gender, as they provided it. This property is only provided for authenticated requests if the user has shared it with the authenticated application, and the authenticated user is allowed to view it (as with administrators of groups the user has joined). In all other cases, this property is omitted.


=back

=cut

sub get_profile {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/profile.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub profile {
    my $self = shift;
    Carp::carp("'profile' is deprecated. Use 'get_profile' instead.");
    $self->get_profile(@_);
}

=pod



=item get_relationships

  my $res = $tp->users->get_relationships($id);

Get a list of relationships that the selected user has with other users, and that other users have with the selected user.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_relationships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/relationships.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub relationships {
    my $self = shift;
    Carp::carp("'relationships' is deprecated. Use 'get_relationships' instead.");
    $self->get_relationships(@_);
}

=pod



=item get_relationships_by_group

  my $res = $tp->users->get_relationships_by_group($id, $groupId);

Get a list of relationships that the selected user has with other users, and that other users have with the selected user, constrained to members of a particular group.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_relationships_by_group {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # groupId
    my $uri = sprintf '/users/%s/relationships/@by-group/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub relationships_by_group {
    my $self = shift;
    Carp::carp("'relationships_by_group' is deprecated. Use 'get_relationships_by_group' instead.");
    $self->get_relationships_by_group(@_);
}

=pod



=item get_relationships_by_user

  my $res = $tp->users->get_relationships_by_user($id, $userId);

Get a list of relationships that the selected user has with a single other user.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_relationships_by_user {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # userId
    my $uri = sprintf '/users/%s/relationships/@by-user/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub relationships_by_user {
    my $self = shift;
    Carp::carp("'relationships_by_user' is deprecated. Use 'get_relationships_by_user' instead.");
    $self->get_relationships_by_user(@_);
}

=pod



=item get_follower_relationships

  my $res = $tp->users->get_follower_relationships($id);

Get a list of relationships that have the Contact type that the selected user has with other users.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_follower_relationships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/relationships/@follower.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub follower_relationships {
    my $self = shift;
    Carp::carp("'follower_relationships' is deprecated. Use 'get_follower_relationships' instead.");
    $self->get_follower_relationships(@_);
}

=pod



=item get_follower_relationships_by_group

  my $res = $tp->users->get_follower_relationships_by_group($id, $groupId);

Get a list of relationships that have the Contact type that the selected user has with other users, constrained to members of a particular group.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_follower_relationships_by_group {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # groupId
    my $uri = sprintf '/users/%s/relationships/@follower/@by-group/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub follower_relationships_by_group {
    my $self = shift;
    Carp::carp("'follower_relationships_by_group' is deprecated. Use 'get_follower_relationships_by_group' instead.");
    $self->get_follower_relationships_by_group(@_);
}

=pod



=item get_following_relationships

  my $res = $tp->users->get_following_relationships($id);

Get a list of relationships that have the Contact type that other users have with the selected user.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_following_relationships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/users/%s/relationships/@following.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub following_relationships {
    my $self = shift;
    Carp::carp("'following_relationships' is deprecated. Use 'get_following_relationships' instead.");
    $self->get_following_relationships(@_);
}

=pod



=item get_following_relationships_by_group

  my $res = $tp->users->get_following_relationships_by_group($id, $groupId);

Get a list of relationships that have the Contact type that other users have with the selected user, constrained to members of a particular group.

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_following_relationships_by_group {
    my $api = shift;
    my @args;
    push @args, shift; # id
    push @args, shift; # groupId
    my $uri = sprintf '/users/%s/relationships/@following/@by-group/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub following_relationships_by_group {
    my $self = shift;
    Carp::carp("'following_relationships_by_group' is deprecated. Use 'get_following_relationships_by_group' instead.");
    $self->get_following_relationships_by_group(@_);
}

=pod

=back

=cut

### END auto-generated

1;
