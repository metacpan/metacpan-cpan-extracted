package WWW::TypePad::Assets;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::assets { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::Assets - Assets API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item search

  my $res = $tp->assets->search();

Search for user-created content across the whole of TypePad.

Returns StreamE<lt>AssetE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole stream of which this response contains a subset. CE<lt>nullE<gt> if an exact count cannot be determined.

=item estimatedTotalResults

(integer) An estimate of the total number of items in the whole list of which this response contains a subset. CE<lt>nullE<gt> if a count cannot be determined at all, or if an exact count is returned in CE<lt>totalResultsE<gt>.

=item moreResultsToken

(string) An opaque token that can be used as the CE<lt>start-tokenE<gt> parameter of a followup request to retrieve additional results. CE<lt>nullE<gt> if there are no more results to retrieve, but the presence of this token does not guarantee that the response to a followup request will actually contain results.

=item entries

(arrayE<lt>AssetE<gt>) A selection of items from the underlying stream.


=back

=cut

sub search {
    my $api = shift;
    my @args;
    my $uri = sprintf '/assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item delete

  my $res = $tp->assets->delete($id);

Delete the selected asset and its associated events, comments and favorites.

Returns Asset which contains following properties.

=over 8

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

sub delete {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s.json', @args;
    $api->base->call("DELETE", $uri, @_);
}


=pod



=item get

  my $res = $tp->assets->get($id);

Get basic information about the selected asset.

Returns Asset which contains following properties.

=over 8

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

sub get {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s.json', @args;
    $api->base->call("GET", $uri, @_);
}


=pod



=item put

  my $res = $tp->assets->put($id);

Update the selected asset.

Returns Asset which contains following properties.

=over 8

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

sub put {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s.json', @args;
    $api->base->call("PUT", $uri, @_);
}


=pod



=item add_category

  my $res = $tp->assets->add_category($id);

Send label argument to add a category to an asset

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub add_category {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/add-category.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item cast_negative_vote

  my $res = $tp->assets->cast_negative_vote($id);

Send a negative vote/thumbs up for an asset.

Returns hash reference which contains following properties.

=over 8

=item negativeVoteCount

(integer) The new sum of negative votes for the asset.


=back

=cut

sub cast_negative_vote {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/cast-negative-vote.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item cast_positive_vote

  my $res = $tp->assets->cast_positive_vote($id);

Send a positive vote/thumbs up for an asset.

Returns hash reference which contains following properties.

=over 8

=item positiveVoteCount

(integer) The new sum of positive votes for the asset.


=back

=cut

sub cast_positive_vote {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/cast-positive-vote.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_categories

  my $res = $tp->assets->get_categories($id);

Get a list of categories into which this asset has been placed within its blog. Currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.

Returns ListE<lt>stringE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>stringE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_categories {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/categories.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub categories {
    my $self = shift;
    Carp::carp("'categories' is deprecated. Use 'get_categories' instead.");
    $self->get_categories(@_);
}

=pod



=item get_comment_tree

  my $res = $tp->assets->get_comment_tree($id);

Get a list of assets that were posted in response to the selected asset and their depth in the response tree

Returns ListE<lt>CommentTreeItemE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>CommentTreeItemE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_comment_tree {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/comment-tree.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub comment_tree {
    my $self = shift;
    Carp::carp("'comment_tree' is deprecated. Use 'get_comment_tree' instead.");
    $self->get_comment_tree(@_);
}

=pod



=item post_to_comments

  my $res = $tp->assets->post_to_comments($id);

Create a new Comment asset as a response to the selected asset.

Returns Comment which contains following properties.

=over 8

=item inReplyTo

(AssetRef) BE<lt>Read OnlyE<gt> A reference to the asset that this comment is in reply to.

=item root

(AssetRef) BE<lt>Read OnlyE<gt> A reference to the root asset that this comment is descended from. This will be the same as ME<lt>inReplyToE<gt> unless this comment is a reply to another comment.

=item publicationStatus

(PublicationStatus) An object describing the visibility status and publication date for this page. Only visibility status is editable.

=item suppressEvents

(boolean) BE<lt>Write OnlyE<gt> An optional, write-only flag indicating that asset creation should not trigger notification events such as emails or dashboard entries. Not available to all applications.

=item commenter

(CommenterInfo) BE<lt>Read OnlyE<gt> A structure containing information about the author of this comment, which may be either an authenticated user or an unauthenticated user.

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

sub post_to_comments {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/comments.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_comments

  my $res = $tp->assets->get_comments($id);

Get a list of assets that were posted in response to the selected asset.

Returns ListE<lt>CommentE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>CommentE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_comments {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/comments.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub comments {
    my $self = shift;
    Carp::carp("'comments' is deprecated. Use 'get_comments' instead.");
    $self->get_comments(@_);
}

=pod



=item get_extended_content

  my $res = $tp->assets->get_extended_content($id);

Get the extended content for the asset, if any. Currently supported only for OE<lt>PostE<gt> assets that are posted within a blog.

Returns AssetExtendedContent which contains following properties.

=over 8

=item renderedExtendedContent

(string) The HTML rendered version of this asset's extended content, if it has any. Otherwise, this property is omitted.


=back

=cut

sub get_extended_content {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/extended-content.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub extended_content {
    my $self = shift;
    Carp::carp("'extended_content' is deprecated. Use 'get_extended_content' instead.");
    $self->get_extended_content(@_);
}

=pod



=item get_favorites

  my $res = $tp->assets->get_favorites($id);

Get a list of favorites that have been created for the selected asset.

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
    my $uri = sprintf '/assets/%s/favorites.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub favorites {
    my $self = shift;
    Carp::carp("'favorites' is deprecated. Use 'get_favorites' instead.");
    $self->get_favorites(@_);
}

=pod



=item get_feedback_status

  my $res = $tp->assets->get_feedback_status($id);

Get the feedback status of the selected asset.

Returns FeedbackStatus which contains following properties.

=over 8

=item allowComments

(boolean) CE<lt>trueE<gt> if new comments may be posted to the related asset, or CE<lt>falseE<gt> if no new comments are accepted.

=item showComments

(boolean) CE<lt>trueE<gt> if comments should be displayed on the related asset's permalink page, or CE<lt>falseE<gt> if they should be hidden.

=item allowTrackback

(boolean) CE<lt>trueE<gt> if new trackback pings may be posted to the related asset, or CE<lt>falseE<gt> if no new pings are accepted.


=back

=cut

sub get_feedback_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/feedback-status.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub feedback_status {
    my $self = shift;
    Carp::carp("'feedback_status' is deprecated. Use 'get_feedback_status' instead.");
    $self->get_feedback_status(@_);
}

=pod



=item put_feedback_status

  my $res = $tp->assets->put_feedback_status($id);

Set the feedback status of the selected asset.

Returns FeedbackStatus which contains following properties.

=over 8

=item allowComments

(boolean) CE<lt>trueE<gt> if new comments may be posted to the related asset, or CE<lt>falseE<gt> if no new comments are accepted.

=item showComments

(boolean) CE<lt>trueE<gt> if comments should be displayed on the related asset's permalink page, or CE<lt>falseE<gt> if they should be hidden.

=item allowTrackback

(boolean) CE<lt>trueE<gt> if new trackback pings may be posted to the related asset, or CE<lt>falseE<gt> if no new pings are accepted.


=back

=cut

sub put_feedback_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/feedback-status.json', @args;
    $api->base->call("PUT", $uri, @_);
}


=pod



=item make_comment_preview

  my $res = $tp->assets->make_comment_preview($id);

Send relevant data to get back a model of what the submitted comment will look like.

Returns hash reference which contains following properties.

=over 8

=item comment

(Asset) A mockup of the future comment.


=back

=cut

sub make_comment_preview {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/make-comment-preview.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_media_assets

  my $res = $tp->assets->get_media_assets($id);

Get a list of media assets that are embedded in the content of the selected asset.

Returns ListE<lt>AssetE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>AssetE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_media_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/media-assets.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub media_assets {
    my $self = shift;
    Carp::carp("'media_assets' is deprecated. Use 'get_media_assets' instead.");
    $self->get_media_assets(@_);
}

=pod



=item get_publication_status

  my $res = $tp->assets->get_publication_status($id);

Get the publication status of the selected asset.

Returns PublicationStatus which contains following properties.

=over 8

=item publicationDate

(string) The time at which the related asset was (or will be) published, as a W3CDTF timestamp. If the related asset has been scheduled to be posted later, this property's timestamp will be in the future.

=item draft

(boolean) CE<lt>trueE<gt> if this asset is private (not yet published), or CE<lt>falseE<gt> if it has been published.


=back

=cut

sub get_publication_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/publication-status.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub publication_status {
    my $self = shift;
    Carp::carp("'publication_status' is deprecated. Use 'get_publication_status' instead.");
    $self->get_publication_status(@_);
}

=pod



=item put_publication_status

  my $res = $tp->assets->put_publication_status($id);

Set the publication status of the selected asset.

Returns PublicationStatus which contains following properties.

=over 8

=item publicationDate

(string) The time at which the related asset was (or will be) published, as a W3CDTF timestamp. If the related asset has been scheduled to be posted later, this property's timestamp will be in the future.

=item draft

(boolean) CE<lt>trueE<gt> if this asset is private (not yet published), or CE<lt>falseE<gt> if it has been published.


=back

=cut

sub put_publication_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/publication-status.json', @args;
    $api->base->call("PUT", $uri, @_);
}


=pod



=item get_reblogs

  my $res = $tp->assets->get_reblogs($id);

Get a list of posts that were posted as reblogs of the selected asset.

Returns ListE<lt>PostE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole list of which this list object is a paginated view.

=item entries

(arrayE<lt>PostE<gt>) The items within the selected slice of the list.


=back

=cut

sub get_reblogs {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/reblogs.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub reblogs {
    my $self = shift;
    Carp::carp("'reblogs' is deprecated. Use 'get_reblogs' instead.");
    $self->get_reblogs(@_);
}

=pod



=item remove_category

  my $res = $tp->assets->remove_category($id);

Send label argument to remove a category from an asset

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub remove_category {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/remove-category.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item update_publication_status

  my $res = $tp->assets->update_publication_status($id);

Adjust publication status of an asset

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub update_publication_status {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/assets/%s/update-publication-status.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item get_trending

  my $res = $tp->assets->get_trending();

Gets a stream of trending assets across TypePad

Returns StreamE<lt>AssetE<gt> which contains following properties.

=over 8

=item totalResults

(integer) The total number of items in the whole stream of which this response contains a subset. CE<lt>nullE<gt> if an exact count cannot be determined.

=item estimatedTotalResults

(integer) An estimate of the total number of items in the whole list of which this response contains a subset. CE<lt>nullE<gt> if a count cannot be determined at all, or if an exact count is returned in CE<lt>totalResultsE<gt>.

=item moreResultsToken

(string) An opaque token that can be used as the CE<lt>start-tokenE<gt> parameter of a followup request to retrieve additional results. CE<lt>nullE<gt> if there are no more results to retrieve, but the presence of this token does not guarantee that the response to a followup request will actually contain results.

=item entries

(arrayE<lt>AssetE<gt>) A selection of items from the underlying stream.


=back

=cut

sub get_trending {
    my $api = shift;
    my @args;
    my $uri = sprintf '/assets/trending.json', @args;
    $api->base->call("GET", $uri, @_);
}


sub trending {
    my $self = shift;
    Carp::carp("'trending' is deprecated. Use 'get_trending' instead.");
    $self->get_trending(@_);
}

=pod

=back

=cut

### END auto-generated

1;
