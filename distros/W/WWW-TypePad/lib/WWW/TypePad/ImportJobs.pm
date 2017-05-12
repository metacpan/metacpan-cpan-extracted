package WWW::TypePad::ImportJobs;

use strict;
use warnings;

# Install an accessor into WWW::TypePad to access an instance of this class
# bound to the WWW::TypePad instance.
sub WWW::TypePad::import_jobs { __PACKAGE__->new( base => $_[0] ) }

### BEGIN auto-generated
### This is an automatically generated code, do not edit!
### Scroll down to look for END to add additional methods

=pod

=head1 NAME

WWW::TypePad::ImportJobs - ImportJobs API methods

=head1 METHODS

=cut

use strict;
use Any::Moose;
extends 'WWW::TypePad::Noun';

use Carp ();


=pod

=over 4


=item close_job

  my $res = $tp->import_jobs->close_job($id);

Terminates a blog import job.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub close_job {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/import-jobs/%s/close-job.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item post_to_media_assets

  my $res = $tp->import_jobs->post_to_media_assets($id);

Add a new media asset to the account that owns the blog associated with this import job.

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

sub post_to_media_assets {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/import-jobs/%s/media-assets.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod



=item submit_items

  my $res = $tp->import_jobs->submit_items($id);

Imports a selection of items into a blog import job.

Returns hash reference which contains following properties.

=over 8


=back

=cut

sub submit_items {
    my $api = shift;
    my @args;
    push @args, shift; # id
    my $uri = sprintf '/import-jobs/%s/submit-items.json', @args;
    $api->base->call("POST", $uri, @_);
}


=pod

=back

=cut

### END auto-generated

1;
