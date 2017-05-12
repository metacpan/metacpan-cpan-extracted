package WWW::TypePad::Groups;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::groups { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Groups - Groups API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item get

  my $res = $tp->groups->get($id);

Get basic information about the selected group.

Returns Group which contains following properties.

=over 8

=item displayName

(string) The display name set by the group's owner.

=item tagline

(string) A tagline describing the group, as set by the group's owner.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>DeprecatedE<gt> An array of object type identifier URIs.

=item objectType

(string) A keyword describing the type of this object. For a group object, ME<lt>objectTypeE<gt> will be CE<lt>GroupE<gt>.

=item avatarLink

(ImageLink) A link to an image representing this group.

=item siteUrl

(string) The URL to the front page of the group website.

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
    my $uri = sprintf '/groups/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item add_member

  my $res = $tp->groups->add_member($id);

Add a given user as a member of the selected group.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub add_member {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/add-member.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item post_to_audio_assets

  my $res = $tp->groups->post_to_audio_assets($id);

Create a new Audio asset within the selected group.

Returns Audio which contains following properties.

=over 8

=item audioLink

(AudioLink) BE<lt>Read OnlyE<gt> A link to the audio stream that is this Audio asset's content.

=item suppressEvents

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that asset creation should not trigger notification events such as emails or dashboard entries. Not available to all applications.

=item id

(string) BE<lt>Read OnlyE<gt> A URI that serves as a globally unique identifier for the user.

=item urlId

(string) BE<lt>Read OnlyE<gt> A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item permalinkUrl

(string) BE<lt>Read OnlyE<gt> The URL that is this asset's permalink. This will be omitted if the asset does not have a permalink of its own (for example, if it's embedded in another asset) or if TypePad does not know its permalink.

=item shortUrl

(string) BE<lt>Read OnlyE<gt> The short version of the URL that is this asset's permalink. This is currently available only for OE<lt>PostE<gt> assetes.

=item author

(User) BE<lt>Read OnlyE<gt> The user who created the selected asset.

=item published

(datetime) BE<lt>Read OnlyE<gt> The time at which the asset was created, as a W3CDTF timestamp.

=item content

(string) The raw asset content. The ME<lt>textFormatE<gt> property describes how to format this data. Use this property to set the asset content in write operations. An asset posted in a group may have a ME<lt>contentE<gt> value up to 10,000 bytes long, while a OE<lt>PostE<gt> asset in a blog may have up to 65,000 bytes of content.

=item renderedContent

(string) BE<lt>Read OnlyE<gt> The content of this asset rendered to HTML. This is currently available only for OE<lt>PostE<gt> and OE<lt>PageE<gt> assets.

=item excerpt

(string) BE<lt>Read OnlyE<gt> A short, plain-text excerpt of the entry content. This is currently available only for OE<lt>PostE<gt> assets.

=item textFormat

(string) A keyword that indicates what formatting mode to use for the content of this asset. This can be CE<lt>htmlE<gt> for assets the content of which is HTML, CE<lt>html_convert_linebreaksE<gt> for assets the content of which is HTML but where paragraph tags should be added automatically, or CE<lt>markdownE<gt> for assets the content of which is Markdown source. Other formatting modes may be added in future. Applications that present assets for editing should use this property to present an appropriate editor.

=item groups

(arrayE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of strings containing the ME<lt>idE<gt> URI of the OE<lt>GroupE<gt> object that this asset is mapped into, if any. This property has been superseded by the ME<lt>containerE<gt> property.

=item source

(AssetSource) BE<lt>Read OnlyE<gt> An object describing the site from which this asset was retrieved, if the asset was obtained from an external source.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of object type identifier URIs identifying the type of this asset. Only the one object type URI for the particular type of asset this asset is will be present.

=item objectType

(string) BE<lt>Read OnlyE<gt> The keyword identifying the type of asset this is.

=item isFavoriteForCurrentUser

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset is a favorite for the currently authenticated user, or CE<lt>falseE<gt> otherwise. This property is omitted from responses to anonymous requests.

=item favoriteCount

(integer) BE<lt>Read OnlyE<gt> The number of distinct users who have added this asset as a favorite.

=item commentCount

(integer) BE<lt>Read OnlyE<gt> The number of comments that have been posted in reply to this asset. This number includes comments that have been posted in response to other comments.

=item title

(string) The title of the asset.

=item description

(string) The description of the asset.

=item container

(ContainerRef) BE<lt>Read OnlyE<gt> An object describing the group or blog to which this asset belongs.

=item publicationStatus

(PublicationStatus) An object describing the visibility status and publication date for this asset. Only visibility status is editable.

=item crosspostAccounts

(setE<lt>stringE<gt>) BE<lt>Write OnlyE<gt> A set of identifiers for OE<lt>AccountE<gt> objects to which to crosspost this asset when it's posted. This property is omitted when retrieving existing assets.

=item isConversationsAnswer

(boolean) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> CE<lt>trueE<gt> if this asset is an answer to a TypePad Conversations question, or absent otherwise. This property is deprecated and will be replaced with something more useful in future.

=item reblogOf

(AssetRef) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset, this property describes the original asset.

=item reblogOfUrl

(string) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset or some other arbitrary web page, this property contains the URL of the item that was reblogged.

=item positiveVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of positive votes this asset has received via the NE<lt>/assets/{id}/cast-positive-voteE<gt> endpoint.

=item negativeVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of negative votes this asset has received via the NE<lt>/assets/{id}/cast-negative-voteE<gt> endpoint.

=item hasExtendedContent

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset has the extended content. This is currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.


=back

=cut

sub post_to_audio_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/audio-assets.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_audio_assets

  my $res = $tp->groups->get_audio_assets($id);

Get a list of recently created Audio assets from the selected group.

Returns ListE<lt>AudioE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>AudioE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_audio_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/audio-assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub audio_assets {
    my $self = shift;
    Carp::carp("'audio_assets' is deprecated. Use 'get_audio_assets' instead.");
    $self->get_audio_assets(@_);
}

=pod



=item block_user

  my $res = $tp->groups->block_user($id);

Block the given user from joining the selected group, removing that user as a member in the process.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub block_user {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/block-user.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item create_external_feed_subscription

  my $res = $tp->groups->create_external_feed_subscription($id);

Subscribe the group to one or more external feeds.

Returns hash reference which contains following properties.

=over 8

=item subscription

(ExternalFeedSubscription) The subscription object that was created.


=back

=cut

sub create_external_feed_subscription {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/create-external-feed-subscription.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_events

  my $res = $tp->groups->get_events($id);

Get a list of events describing actions performed in the selected group.

Returns ListE<lt>EventE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>EventE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_events {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/events.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub events {
    my $self = shift;
    Carp::carp("'events' is deprecated. Use 'get_events' instead.");
    $self->get_events(@_);
}

=pod



=item get_external_feed_subscriptions

  my $res = $tp->groups->get_external_feed_subscriptions($id);

Get a list of the group's active external feed subscriptions.

Returns ListE<lt>ExternalFeedSubscriptionE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>ExternalFeedSubscriptionE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_external_feed_subscriptions {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/external-feed-subscriptions.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub external_feed_subscriptions {
    my $self = shift;
    Carp::carp("'external_feed_subscriptions' is deprecated. Use 'get_external_feed_subscriptions' instead.");
    $self->get_external_feed_subscriptions(@_);
}

=pod



=item post_to_link_assets

  my $res = $tp->groups->post_to_link_assets($id);

Create a new Link asset within the selected group.

Returns Link which contains following properties.

=over 8

=item targetUrl

(string) The URL that is the target of this link.

=item suppressEvents

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that asset creation should not trigger notification events such as emails or dashboard entries. Not available to all applications.

=item id

(string) BE<lt>Read OnlyE<gt> A URI that serves as a globally unique identifier for the user.

=item urlId

(string) BE<lt>Read OnlyE<gt> A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item permalinkUrl

(string) BE<lt>Read OnlyE<gt> The URL that is this asset's permalink. This will be omitted if the asset does not have a permalink of its own (for example, if it's embedded in another asset) or if TypePad does not know its permalink.

=item shortUrl

(string) BE<lt>Read OnlyE<gt> The short version of the URL that is this asset's permalink. This is currently available only for OE<lt>PostE<gt> assetes.

=item author

(User) BE<lt>Read OnlyE<gt> The user who created the selected asset.

=item published

(datetime) BE<lt>Read OnlyE<gt> The time at which the asset was created, as a W3CDTF timestamp.

=item content

(string) The raw asset content. The ME<lt>textFormatE<gt> property describes how to format this data. Use this property to set the asset content in write operations. An asset posted in a group may have a ME<lt>contentE<gt> value up to 10,000 bytes long, while a OE<lt>PostE<gt> asset in a blog may have up to 65,000 bytes of content.

=item renderedContent

(string) BE<lt>Read OnlyE<gt> The content of this asset rendered to HTML. This is currently available only for OE<lt>PostE<gt> and OE<lt>PageE<gt> assets.

=item excerpt

(string) BE<lt>Read OnlyE<gt> A short, plain-text excerpt of the entry content. This is currently available only for OE<lt>PostE<gt> assets.

=item textFormat

(string) A keyword that indicates what formatting mode to use for the content of this asset. This can be CE<lt>htmlE<gt> for assets the content of which is HTML, CE<lt>html_convert_linebreaksE<gt> for assets the content of which is HTML but where paragraph tags should be added automatically, or CE<lt>markdownE<gt> for assets the content of which is Markdown source. Other formatting modes may be added in future. Applications that present assets for editing should use this property to present an appropriate editor.

=item groups

(arrayE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of strings containing the ME<lt>idE<gt> URI of the OE<lt>GroupE<gt> object that this asset is mapped into, if any. This property has been superseded by the ME<lt>containerE<gt> property.

=item source

(AssetSource) BE<lt>Read OnlyE<gt> An object describing the site from which this asset was retrieved, if the asset was obtained from an external source.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of object type identifier URIs identifying the type of this asset. Only the one object type URI for the particular type of asset this asset is will be present.

=item objectType

(string) BE<lt>Read OnlyE<gt> The keyword identifying the type of asset this is.

=item isFavoriteForCurrentUser

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset is a favorite for the currently authenticated user, or CE<lt>falseE<gt> otherwise. This property is omitted from responses to anonymous requests.

=item favoriteCount

(integer) BE<lt>Read OnlyE<gt> The number of distinct users who have added this asset as a favorite.

=item commentCount

(integer) BE<lt>Read OnlyE<gt> The number of comments that have been posted in reply to this asset. This number includes comments that have been posted in response to other comments.

=item title

(string) The title of the asset.

=item description

(string) The description of the asset.

=item container

(ContainerRef) BE<lt>Read OnlyE<gt> An object describing the group or blog to which this asset belongs.

=item publicationStatus

(PublicationStatus) An object describing the visibility status and publication date for this asset. Only visibility status is editable.

=item crosspostAccounts

(setE<lt>stringE<gt>) BE<lt>Write OnlyE<gt> A set of identifiers for OE<lt>AccountE<gt> objects to which to crosspost this asset when it's posted. This property is omitted when retrieving existing assets.

=item isConversationsAnswer

(boolean) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> CE<lt>trueE<gt> if this asset is an answer to a TypePad Conversations question, or absent otherwise. This property is deprecated and will be replaced with something more useful in future.

=item reblogOf

(AssetRef) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset, this property describes the original asset.

=item reblogOfUrl

(string) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset or some other arbitrary web page, this property contains the URL of the item that was reblogged.

=item positiveVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of positive votes this asset has received via the NE<lt>/assets/{id}/cast-positive-voteE<gt> endpoint.

=item negativeVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of negative votes this asset has received via the NE<lt>/assets/{id}/cast-negative-voteE<gt> endpoint.

=item hasExtendedContent

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset has the extended content. This is currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.


=back

=cut

sub post_to_link_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/link-assets.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_link_assets

  my $res = $tp->groups->get_link_assets($id);

Returns a list of recently created Link assets from the selected group.

Returns ListE<lt>LinkE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>LinkE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_link_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/link-assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub link_assets {
    my $self = shift;
    Carp::carp("'link_assets' is deprecated. Use 'get_link_assets' instead.");
    $self->get_link_assets(@_);
}

=pod



=item get_memberships

  my $res = $tp->groups->get_memberships($id);

Get a list of relationships between users and the selected group.

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
    my $uri = sprintf '/groups/%s/memberships.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub memberships {
    my $self = shift;
    Carp::carp("'memberships' is deprecated. Use 'get_memberships' instead.");
    $self->get_memberships(@_);
}

=pod



=item get_admin_memberships

  my $res = $tp->groups->get_admin_memberships($id);

Get a list of relationships that have the Admin type between users and the selected group.

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
    my $uri = sprintf '/groups/%s/memberships/@admin.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub admin_memberships {
    my $self = shift;
    Carp::carp("'admin_memberships' is deprecated. Use 'get_admin_memberships' instead.");
    $self->get_admin_memberships(@_);
}

=pod



=item get_blocked_memberships

  my $res = $tp->groups->get_blocked_memberships($id);

Get a list of relationships that have the Blocked type between users and the selected groups. (Restricted to group admin.)

Returns ListE<lt>RelationshipE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>RelationshipE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_blocked_memberships {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/memberships/@blocked.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub blocked_memberships {
    my $self = shift;
    Carp::carp("'blocked_memberships' is deprecated. Use 'get_blocked_memberships' instead.");
    $self->get_blocked_memberships(@_);
}

=pod



=item get_member_memberships

  my $res = $tp->groups->get_member_memberships($id);

Get a list of relationships that have the Member type between users and the selected group.

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
    my $uri = sprintf '/groups/%s/memberships/@member.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub member_memberships {
    my $self = shift;
    Carp::carp("'member_memberships' is deprecated. Use 'get_member_memberships' instead.");
    $self->get_member_memberships(@_);
}

=pod



=item post_to_photo_assets

  my $res = $tp->groups->post_to_photo_assets($id);

Create a new Photo asset within the selected group.

Returns Photo which contains following properties.

=over 8

=item imageLink

(ImageLink) BE<lt>Read OnlyE<gt> A link to the image that is this Photo asset's content.

=item suppressEvents

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that asset creation should not trigger notification events such as emails or dashboard entries. Not available to all applications.

=item id

(string) BE<lt>Read OnlyE<gt> A URI that serves as a globally unique identifier for the user.

=item urlId

(string) BE<lt>Read OnlyE<gt> A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item permalinkUrl

(string) BE<lt>Read OnlyE<gt> The URL that is this asset's permalink. This will be omitted if the asset does not have a permalink of its own (for example, if it's embedded in another asset) or if TypePad does not know its permalink.

=item shortUrl

(string) BE<lt>Read OnlyE<gt> The short version of the URL that is this asset's permalink. This is currently available only for OE<lt>PostE<gt> assetes.

=item author

(User) BE<lt>Read OnlyE<gt> The user who created the selected asset.

=item published

(datetime) BE<lt>Read OnlyE<gt> The time at which the asset was created, as a W3CDTF timestamp.

=item content

(string) The raw asset content. The ME<lt>textFormatE<gt> property describes how to format this data. Use this property to set the asset content in write operations. An asset posted in a group may have a ME<lt>contentE<gt> value up to 10,000 bytes long, while a OE<lt>PostE<gt> asset in a blog may have up to 65,000 bytes of content.

=item renderedContent

(string) BE<lt>Read OnlyE<gt> The content of this asset rendered to HTML. This is currently available only for OE<lt>PostE<gt> and OE<lt>PageE<gt> assets.

=item excerpt

(string) BE<lt>Read OnlyE<gt> A short, plain-text excerpt of the entry content. This is currently available only for OE<lt>PostE<gt> assets.

=item textFormat

(string) A keyword that indicates what formatting mode to use for the content of this asset. This can be CE<lt>htmlE<gt> for assets the content of which is HTML, CE<lt>html_convert_linebreaksE<gt> for assets the content of which is HTML but where paragraph tags should be added automatically, or CE<lt>markdownE<gt> for assets the content of which is Markdown source. Other formatting modes may be added in future. Applications that present assets for editing should use this property to present an appropriate editor.

=item groups

(arrayE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of strings containing the ME<lt>idE<gt> URI of the OE<lt>GroupE<gt> object that this asset is mapped into, if any. This property has been superseded by the ME<lt>containerE<gt> property.

=item source

(AssetSource) BE<lt>Read OnlyE<gt> An object describing the site from which this asset was retrieved, if the asset was obtained from an external source.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of object type identifier URIs identifying the type of this asset. Only the one object type URI for the particular type of asset this asset is will be present.

=item objectType

(string) BE<lt>Read OnlyE<gt> The keyword identifying the type of asset this is.

=item isFavoriteForCurrentUser

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset is a favorite for the currently authenticated user, or CE<lt>falseE<gt> otherwise. This property is omitted from responses to anonymous requests.

=item favoriteCount

(integer) BE<lt>Read OnlyE<gt> The number of distinct users who have added this asset as a favorite.

=item commentCount

(integer) BE<lt>Read OnlyE<gt> The number of comments that have been posted in reply to this asset. This number includes comments that have been posted in response to other comments.

=item title

(string) The title of the asset.

=item description

(string) The description of the asset.

=item container

(ContainerRef) BE<lt>Read OnlyE<gt> An object describing the group or blog to which this asset belongs.

=item publicationStatus

(PublicationStatus) An object describing the visibility status and publication date for this asset. Only visibility status is editable.

=item crosspostAccounts

(setE<lt>stringE<gt>) BE<lt>Write OnlyE<gt> A set of identifiers for OE<lt>AccountE<gt> objects to which to crosspost this asset when it's posted. This property is omitted when retrieving existing assets.

=item isConversationsAnswer

(boolean) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> CE<lt>trueE<gt> if this asset is an answer to a TypePad Conversations question, or absent otherwise. This property is deprecated and will be replaced with something more useful in future.

=item reblogOf

(AssetRef) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset, this property describes the original asset.

=item reblogOfUrl

(string) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset or some other arbitrary web page, this property contains the URL of the item that was reblogged.

=item positiveVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of positive votes this asset has received via the NE<lt>/assets/{id}/cast-positive-voteE<gt> endpoint.

=item negativeVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of negative votes this asset has received via the NE<lt>/assets/{id}/cast-negative-voteE<gt> endpoint.

=item hasExtendedContent

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset has the extended content. This is currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.


=back

=cut

sub post_to_photo_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/photo-assets.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_photo_assets

  my $res = $tp->groups->get_photo_assets($id);

Get a list of recently created Photo assets from the selected group.

Returns ListE<lt>PhotoE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>PhotoE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_photo_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/photo-assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub photo_assets {
    my $self = shift;
    Carp::carp("'photo_assets' is deprecated. Use 'get_photo_assets' instead.");
    $self->get_photo_assets(@_);
}

=pod



=item post_to_post_assets

  my $res = $tp->groups->post_to_post_assets($id);

Create a new Post asset within the selected group.

Returns Post which contains following properties.

=over 8

=item categories

(arrayE<lt>stringE<gt>) A list of categories associated with the post.

=item embeddedImageLinks

(arrayE<lt>ImageLinkE<gt>) BE<lt>Read OnlyE<gt> A list of links to the images that are embedded within the content of this post.

=item embeddedVideoLinks

(arrayE<lt>VideoLinkE<gt>) BE<lt>Read OnlyE<gt> A list of links to the videos that are embedded within the content of this post.

=item embeddedAudioLinks

(arrayE<lt>AudioLinkE<gt>) BE<lt>Read OnlyE<gt> A list of links to the audio streams that are embedded within the content of this post.

=item title

(string) The title of the post.

=item description

(string) The description of the post.

=item filename

(string) The base name of the post to use when creating its ME<lt>permalinkUrlE<gt>.

=item content

(string) The raw post content. The ME<lt>textFormatE<gt> property defines what format this data is in.

=item textFormat

(string) A keyword that indicates what formatting mode to use for the content of this post. This can be CE<lt>htmlE<gt> for assets the content of which is HTML, CE<lt>html_convert_linebreaksE<gt> for assets the content of which is HTML but where paragraph tags should be added automatically, or CE<lt>markdownE<gt> for assets the content of which is Markdown source. Other formatting modes may be added in future. Applications that present assets for editing should use this property to present an appropriate editor.

=item publicationStatus

(PublicationStatus) An object describing the draft status and publication date for this post.

=item feedbackStatus

(FeedbackStatus) An object describing the comment and trackback behavior for this post.

=item reblogCount

(integer) BE<lt>Read OnlyE<gt> The number of times this post has been reblogged by other people.

=item reblogOf

(AssetRef) BE<lt>Fixed After CreationE<gt> A reference to a post of which this post is a reblog.

=item suppressEvents

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that asset creation should not trigger notification events such as emails or dashboard entries. Not available to all applications.

=item createConversation

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that the asset is starting a new conversation.

=item conversationId

(string) BE<lt>Read OnlyE<gt> Identifies the OE<lt>ConversationE<gt> object this asset belongs to, if any. Omitted if the asset is not part of a conversation.

=item id

(string) BE<lt>Read OnlyE<gt> A URI that serves as a globally unique identifier for the user.

=item urlId

(string) BE<lt>Read OnlyE<gt> A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item permalinkUrl

(string) BE<lt>Read OnlyE<gt> The URL that is this asset's permalink. This will be omitted if the asset does not have a permalink of its own (for example, if it's embedded in another asset) or if TypePad does not know its permalink.

=item shortUrl

(string) BE<lt>Read OnlyE<gt> The short version of the URL that is this asset's permalink. This is currently available only for OE<lt>PostE<gt> assetes.

=item author

(User) BE<lt>Read OnlyE<gt> The user who created the selected asset.

=item published

(datetime) BE<lt>Read OnlyE<gt> The time at which the asset was created, as a W3CDTF timestamp.

=item content

(string) The raw asset content. The ME<lt>textFormatE<gt> property describes how to format this data. Use this property to set the asset content in write operations. An asset posted in a group may have a ME<lt>contentE<gt> value up to 10,000 bytes long, while a OE<lt>PostE<gt> asset in a blog may have up to 65,000 bytes of content.

=item renderedContent

(string) BE<lt>Read OnlyE<gt> The content of this asset rendered to HTML. This is currently available only for OE<lt>PostE<gt> and OE<lt>PageE<gt> assets.

=item excerpt

(string) BE<lt>Read OnlyE<gt> A short, plain-text excerpt of the entry content. This is currently available only for OE<lt>PostE<gt> assets.

=item textFormat

(string) A keyword that indicates what formatting mode to use for the content of this asset. This can be CE<lt>htmlE<gt> for assets the content of which is HTML, CE<lt>html_convert_linebreaksE<gt> for assets the content of which is HTML but where paragraph tags should be added automatically, or CE<lt>markdownE<gt> for assets the content of which is Markdown source. Other formatting modes may be added in future. Applications that present assets for editing should use this property to present an appropriate editor.

=item groups

(arrayE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of strings containing the ME<lt>idE<gt> URI of the OE<lt>GroupE<gt> object that this asset is mapped into, if any. This property has been superseded by the ME<lt>containerE<gt> property.

=item source

(AssetSource) BE<lt>Read OnlyE<gt> An object describing the site from which this asset was retrieved, if the asset was obtained from an external source.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of object type identifier URIs identifying the type of this asset. Only the one object type URI for the particular type of asset this asset is will be present.

=item objectType

(string) BE<lt>Read OnlyE<gt> The keyword identifying the type of asset this is.

=item isFavoriteForCurrentUser

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset is a favorite for the currently authenticated user, or CE<lt>falseE<gt> otherwise. This property is omitted from responses to anonymous requests.

=item favoriteCount

(integer) BE<lt>Read OnlyE<gt> The number of distinct users who have added this asset as a favorite.

=item commentCount

(integer) BE<lt>Read OnlyE<gt> The number of comments that have been posted in reply to this asset. This number includes comments that have been posted in response to other comments.

=item title

(string) The title of the asset.

=item description

(string) The description of the asset.

=item container

(ContainerRef) BE<lt>Read OnlyE<gt> An object describing the group or blog to which this asset belongs.

=item publicationStatus

(PublicationStatus) An object describing the visibility status and publication date for this asset. Only visibility status is editable.

=item crosspostAccounts

(setE<lt>stringE<gt>) BE<lt>Write OnlyE<gt> A set of identifiers for OE<lt>AccountE<gt> objects to which to crosspost this asset when it's posted. This property is omitted when retrieving existing assets.

=item isConversationsAnswer

(boolean) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> CE<lt>trueE<gt> if this asset is an answer to a TypePad Conversations question, or absent otherwise. This property is deprecated and will be replaced with something more useful in future.

=item reblogOf

(AssetRef) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset, this property describes the original asset.

=item reblogOfUrl

(string) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset or some other arbitrary web page, this property contains the URL of the item that was reblogged.

=item positiveVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of positive votes this asset has received via the NE<lt>/assets/{id}/cast-positive-voteE<gt> endpoint.

=item negativeVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of negative votes this asset has received via the NE<lt>/assets/{id}/cast-negative-voteE<gt> endpoint.

=item hasExtendedContent

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset has the extended content. This is currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.


=back

=cut

sub post_to_post_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/post-assets.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_post_assets

  my $res = $tp->groups->get_post_assets($id);

Get a list of recently created Post assets from the selected group.

Returns ListE<lt>PostE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>PostE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_post_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/post-assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub post_assets {
    my $self = shift;
    Carp::carp("'post_assets' is deprecated. Use 'get_post_assets' instead.");
    $self->get_post_assets(@_);
}

=pod



=item remove_member

  my $res = $tp->groups->remove_member($id);

Remove a given user as a member of the selected group.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub remove_member {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/remove-member.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item unblock_user

  my $res = $tp->groups->unblock_user($id);

Remove the block preventing the given user from joining the selected group.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub unblock_user {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/unblock-user.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item post_to_video_assets

  my $res = $tp->groups->post_to_video_assets($id);

Create a new Video asset within the selected group.

Returns Video which contains following properties.

=over 8

=item videoLink

(VideoLink) BE<lt>Fixed After CreationE<gt> A link to the video that is this Video asset's content.

=item previewImageLink

(ImageLink) BE<lt>Read OnlyE<gt> A link to a preview image or poster frame for this video. This property is omitted if no such image is available.

=item suppressEvents

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that asset creation should not trigger notification events such
 as emails or dashboard entries. Not available to all applications.

=item id

(string) BE<lt>Read OnlyE<gt> A URI that serves as a globally unique identifier for the user.

=item urlId

(string) BE<lt>Read OnlyE<gt> A string containing the canonical identifier that can be used to identify this object in URLs. This can be used to recognise where the same user is returned in response to different requests, and as a mapping key for an application's local data store.

=item permalinkUrl

(string) BE<lt>Read OnlyE<gt> The URL that is this asset's permalink. This will be omitted if the asset does not have a permalink of its own (for example, if it's embedded in another asset) or if TypePad does not know its permalink.

=item shortUrl

(string) BE<lt>Read OnlyE<gt> The short version of the URL that is this asset's permalink. This is currently available only for OE<lt>PostE<gt> assetes.

=item author

(User) BE<lt>Read OnlyE<gt> The user who created the selected asset.

=item published

(datetime) BE<lt>Read OnlyE<gt> The time at which the asset was created, as a W3CDTF timestamp.

=item content

(string) The raw asset content. The ME<lt>textFormatE<gt> property describes how to format this data. Use this property to set the asset content in write operations. An asset posted in a group may have a ME<lt>contentE<gt> value up to 10,000 bytes long, while a OE<lt>PostE<gt> asset in a blog may have up to 65,000 bytes of content.

=item renderedContent

(string) BE<lt>Read OnlyE<gt> The content of this asset rendered to HTML. This is currently available only for OE<lt>PostE<gt> and OE<lt>PageE<gt> assets.

=item excerpt

(string) BE<lt>Read OnlyE<gt> A short, plain-text excerpt of the entry content. This is currently available only for OE<lt>PostE<gt> assets.

=item textFormat

(string) A keyword that indicates what formatting mode to use for the content of this asset. This can be CE<lt>htmlE<gt> for assets the content of which is HTML, CE<lt>html_convert_linebreaksE<gt> for assets the content of which is HTML but where paragraph tags should be added automatically, or CE<lt>markdownE<gt> for assets the content of which is Markdown source. Other formatting modes may be added in future. Applications that present assets for editing should use this property to present an appropriate editor.

=item groups

(arrayE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of strings containing the ME<lt>idE<gt> URI of the OE<lt>GroupE<gt> object that this asset is mapped into, if any. This property has been superseded by the ME<lt>containerE<gt> property.

=item source

(AssetSource) BE<lt>Read OnlyE<gt> An object describing the site from which this asset was retrieved, if the asset was obtained from an external source.

=item objectTypes

(setE<lt>stringE<gt>) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> An array of object type identifier URIs identifying the type of this asset. Only the one object type URI for the particular type of asset this asset is will be present.

=item objectType

(string) BE<lt>Read OnlyE<gt> The keyword identifying the type of asset this is.

=item isFavoriteForCurrentUser

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset is a favorite for the currently authenticated user, or CE<lt>falseE<gt> otherwise. This property is omitted from responses to anonymous requests.

=item favoriteCount

(integer) BE<lt>Read OnlyE<gt> The number of distinct users who have added this asset as a favorite.

=item commentCount

(integer) BE<lt>Read OnlyE<gt> The number of comments that have been posted in reply to this asset. This number includes comments that have been posted in response to other comments.

=item title

(string) The title of the asset.

=item description

(string) The description of the asset.

=item container

(ContainerRef) BE<lt>Read OnlyE<gt> An object describing the group or blog to which this asset belongs.

=item publicationStatus

(PublicationStatus) An object describing the visibility status and publication date for this asset. Only visibility status is editable.

=item crosspostAccounts

(setE<lt>stringE<gt>) BE<lt>Write OnlyE<gt> A set of identifiers for OE<lt>AccountE<gt> objects to which to crosspost this asset when it's posted. This property is omitted when retrieving existing assets.

=item isConversationsAnswer

(boolean) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> CE<lt>trueE<gt> if this asset is an answer to a TypePad Conversations question, or absent otherwise. This property is deprecated and will be replaced with something more useful in future.

=item reblogOf

(AssetRef) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset, this property describes the original asset.

=item reblogOfUrl

(string) BE<lt>Read OnlyE<gt> BE<lt>DeprecatedE<gt> If this asset was created by 'reblogging' another asset or some other arbitrary web page, this property contains the URL of the item that was reblogged.

=item positiveVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of positive votes this asset has received via the NE<lt>/assets/{id}/cast-positive-voteE<gt> endpoint.

=item negativeVoteCount

(integer) BE<lt>Read OnlyE<gt> The total number of negative votes this asset has received via the NE<lt>/assets/{id}/cast-negative-voteE<gt> endpoint.

=item hasExtendedContent

(boolean) BE<lt>Read OnlyE<gt> CE<lt>trueE<gt> if this asset has the extended content. This is currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.


=back

=cut

sub post_to_video_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/video-assets.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_video_assets

  my $res = $tp->groups->get_video_assets($id);

Get a list of recently created Video assets from the selected group.

Returns ListE<lt>VideoE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>VideoE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_video_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/groups/%s/video-assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub video_assets {
    my $self = shift;
    Carp::carp("'video_assets' is deprecated. Use 'get_video_assets' instead.");
    $self->get_video_assets(@_);
}

=pod

=back

=cut

### END auto-generated


sub upload_photo {
    my $api = shift;
    my( $id, $asset, $filename ) = @_;
    return $api->base->call_upload( {
        # No extension on this!
        target_url  => '/groups/' . $id . '/photo-assets',
        asset       => $asset,
        filename    => $filename,
    } );
}

sub upload_audio {
    my $api = shift;
    my( $id, $asset, $filename ) = @_;
    return $api->base->call_upload( {
        # No extension on this!
        target_url  => '/groups/' . $id . '/audio-assets',
        asset       => $asset,
        filename    => $filename,
    } );
}


1;
