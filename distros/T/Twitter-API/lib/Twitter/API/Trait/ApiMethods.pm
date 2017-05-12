package Twitter::API::Trait::ApiMethods;
# ABSTRACT: Convenient API Methods
$Twitter::API::Trait::ApiMethods::VERSION = '0.0112';
use 5.14.1;
use Carp;
use Moo::Role;
use MooX::Aliases;
use Ref::Util qw/is_hashref is_arrayref/;
use namespace::clean;

requires 'request';

with 'Twitter::API::Role::RequestArgs';

#pod =method account_settings([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/account/settings>
#pod
#pod =cut

sub account_settings {
    shift->request(get => 'account/settings', @_);
}

#pod =method blocking([ \%args ])
#pod
#pod Aliases: blocks_list
#pod
#pod L<https://dev.twitter.com/rest/reference/get/blocks/list>
#pod
#pod =cut

sub blocking {
    shift->request(get => 'blocks/list', @_);
}
alias blocks_list => 'blocking';

#pod =method blocking_ids([ \%args ])
#pod
#pod Aliases: blocks_ids
#pod
#pod L<https://dev.twitter.com/rest/reference/get/blocks/ids>
#pod
#pod =cut

sub blocking_ids {
    shift->request(get => 'blocks/ids', @_);
}
alias blocks_ids => 'blocking_ids';

#pod =method collection_entries([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/collections/entries>
#pod
#pod =cut

sub collection_entries {
    shift->request_with_pos_args(id => get => 'collections/entries', @_);
}

#pod =method collections([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/collections/list>
#pod
#pod =cut

sub collections {
    shift->request_with_pos_args(':ID', get => 'collections/list', @_);
}

#pod =method direct_messages([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/direct_messages>
#pod
#pod =cut

sub direct_messages {
    shift->request(get => 'direct_messages', @_);
}

#pod =method favorites([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/favorites/list>
#pod
#pod =cut

sub favorites {
    shift->request(get => 'favorites/list', @_);
}

#pod =method followers([ \%args ])
#pod
#pod Aliases: followers_list
#pod
#pod L<https://dev.twitter.com/rest/reference/get/followers/list>
#pod
#pod =cut

sub followers {
    shift->request(get => 'followers/list', @_);
}
alias followers_list => 'followers';

#pod =method followers_ids([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/followers/ids>
#pod
#pod =cut

sub followers_ids {
    shift->request_with_pos_args(':ID', get => 'followers/ids', @_);
}

#pod =method friends([ \%args ])
#pod
#pod Aliases: friends_list
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friends/list>
#pod
#pod =cut

sub friends {
    shift->request(get => 'friends/list', @_);
}
alias friends_list => 'friends';

#pod =method friends_ids([ \%args ])
#pod
#pod Aliases: following_ids
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friends/ids>
#pod
#pod =cut

sub friends_ids {
    shift->request_with_id(get => 'friends/ids', @_);
}
alias following_ids => 'friends_ids';

#pod =method friendships_incoming([ \%args ])
#pod
#pod Aliases: incoming_friendships
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friendships/incoming>
#pod
#pod =cut

sub friendships_incoming {
    shift->request(get => 'friendships/incoming', @_);
}
alias incoming_friendships => 'friendships_incoming';

#pod =method friendships_outgoing([ \%args ])
#pod
#pod Aliases: outgoing_friendships
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friendships/outgoing>
#pod
#pod =cut

sub friendships_outgoing {
    shift->request(get => 'friendships/outgoing', @_);
}
alias outgoing_friendships => 'friendships_outgoing';

#pod =method geo_id([ $place_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/geo/id/:place_id>
#pod
#pod =cut

# NT incompatibility
sub geo_id {
    shift->request_with_pos_args(place_id => get => 'geo/id/:place_id', @_);
}

#pod =method geo_search([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/geo/search>
#pod
#pod =cut

sub geo_search {
    shift->request(get => 'geo/search', @_);
}

#pod =method get_configuration([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/help/configuration>
#pod
#pod =cut

sub get_configuration {
    shift->request(get => 'help/configuration', @_);
}

#pod =method get_languages([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/help/languages>
#pod
#pod =cut

sub get_languages {
    shift->request(get => 'help/languages', @_);
}

#pod =method get_list([ \%args ])
#pod
#pod Aliases: show_list
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/show>
#pod
#pod =cut

sub get_list {
    shift->request(get => 'lists/show', @_);
}
alias show_list => 'get_list';

#pod =method get_lists([ \%args ])
#pod
#pod Aliases: list_lists, all_subscriptions
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/list>
#pod
#pod =cut

sub get_lists {
    shift->request(get => 'lists/list', @_);
}
alias $_ => 'get_lists' for qw/list_lists all_subscriptions/;

#pod =method get_privacy_policy([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/help/privacy>
#pod
#pod =cut

sub get_privacy_policy {
    shift->request(get => 'help/privacy', @_);
}

#pod =method get_tos([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/help/tos>
#pod
#pod =cut

sub get_tos {
    shift->request(get => 'help/tos', @_);
}

#pod =method home_timeline([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/home_timeline>
#pod
#pod =cut

sub home_timeline {
    shift->request(get => 'statuses/home_timeline', @_);
}

#pod =method list_members([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/members>
#pod
#pod =cut

sub list_members {
    shift->request(get => 'lists/members', @_);
}

#pod =method list_memberships([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/memberships>
#pod
#pod =cut

sub list_memberships {
    shift->request(get => 'lists/memberships', @_);
}

#pod =method list_ownerships([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/ownerships>
#pod
#pod =cut

sub list_ownerships {
    shift->request(get => 'lists/ownerships', @_);
}

#pod =method list_statuses([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/statuses>
#pod
#pod =cut

sub list_statuses {
    shift->request(get => 'lists/statuses', @_);
}

#pod =method list_subscribers([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/subscribers>
#pod
#pod =cut

sub list_subscribers {
    shift->request(get => 'lists/subscribers', @_);
}

#pod =method list_subscriptions([ \%args ])
#pod
#pod Aliases: subscriptions
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/subscriptions>
#pod
#pod =cut

sub list_subscriptions {
    shift->request(get => 'lists/subscriptions', @_);
}
alias subscriptions => 'list_subscriptions';

#pod =method lookup_friendships([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friendships/lookup>
#pod
#pod =cut

sub lookup_friendships {
    shift->request(get => 'friendships/lookup', @_);
}

#pod =method lookup_statuses([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/lookup>
#pod
#pod =cut

sub lookup_statuses {
    shift->request_with_pos_args(id => get => 'statuses/lookup', @_);
}

#pod =method lookup_users([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/lookup>
#pod
#pod =cut

sub lookup_users {
    shift->request(get => 'users/lookup', @_);
}

#pod =method mentions([ \%args ])
#pod
#pod Aliases: replies, mentions_timeline
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline>
#pod
#pod =cut

sub mentions {
    shift->request(get => 'statuses/mentions_timeline', @_);
}
alias $_ => 'mentions' for qw/replies mentions_timeline/;

#pod =method mutes([ \%args ])
#pod
#pod Aliases: muting_ids, muted_ids
#pod
#pod L<https://dev.twitter.com/rest/reference/get/mutes/users/ids>
#pod
#pod =cut

sub mutes {
    shift->request(get => 'mutes/users/ids', @_);
}
alias $_ => 'mutes' for qw/muting_ids muted_ids/;

#pod =method muting([ \%args ])
#pod
#pod Aliases: mutes_list
#pod
#pod L<https://dev.twitter.com/rest/reference/get/mutes/users/list>
#pod
#pod =cut

sub muting {
    shift->request(get => 'mutes/users/list', @_);
}
alias mutes_list => 'muting';

#pod =method no_retweet_ids([ \%args ])
#pod
#pod Aliases: no_retweets_ids
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friendships/no_retweets/ids>
#pod
#pod =cut

sub no_retweet_ids {
    shift->request(get => 'friendships/no_retweets/ids', @_);
}
alias no_retweets_ids => 'no_retweet_ids';

#pod =method oembed([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/oembed>
#pod
#pod =cut

sub oembed {
    shift->request(get => 'statuses/oembed', @_);
}

#pod =method profile_banner([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/profile_banner>
#pod
#pod =cut

sub profile_banner {
    shift->request(get => 'users/profile_banner', @_);
}

#pod =method rate_limit_status([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/application/rate_limit_status>
#pod
#pod =cut

sub rate_limit_status {
    shift->request(get => 'application/rate_limit_status', @_);
}

#pod =method retweeters_ids([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/retweeters/ids>
#pod
#pod =cut

sub retweeters_ids {
    shift->request_with_pos_args(id => get => 'statuses/retweeters/ids', @_);
}

#pod =method retweets([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/retweets/:id>
#pod
#pod =cut

sub retweets {
    shift->request_with_pos_args(id => get => 'statuses/retweets/:id', @_);
}

#pod =method retweets_of_me([ \%args ])
#pod
#pod Aliases: retweeted_of_me
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/retweets_of_me>
#pod
#pod =cut

sub retweets_of_me {
    shift->request(get => 'statuses/retweets_of_me', @_);
}
alias retweeted_of_me => 'retweets_of_me';

#pod =method reverse_geocode([ $lat, [ $long, ]][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/geo/reverse_geocode>
#pod
#pod =cut

sub reverse_geocode {
    shift->request_with_pos_args([ qw/lat long/ ], get => 'geo/reverse_geocode', @_);
}

#pod =method saved_searches([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/saved_searches/list>
#pod
#pod =cut

sub saved_searches {
    shift->request(get => 'saved_searches/list', @_);
}

#pod =method search([ $q, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/search/tweets>
#pod
#pod =cut

sub search {
    shift->request_with_pos_args(q => get => 'search/tweets', @_);
}

#pod =method sent_direct_messages([ \%args ])
#pod
#pod Aliases: direct_messages_sent
#pod
#pod L<https://dev.twitter.com/rest/reference/get/direct_messages/sent>
#pod
#pod =cut

sub sent_direct_messages {
    shift->request(get => 'direct_messages/sent', @_);
}
alias direct_messages_sent => 'sent_direct_messages';

#pod =method show_direct_message([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/direct_messages/show>
#pod
#pod =cut

sub show_direct_message {
    shift->request_with_pos_args(id => get => 'direct_messages/show', @_);
}

#pod =method show_friendship([ \%args ])
#pod
#pod Aliases: show_relationship
#pod
#pod L<https://dev.twitter.com/rest/reference/get/friendships/show>
#pod
#pod =cut

sub show_friendship {
    shift->request(get => 'friendships/show', @_);
}
alias show_relationship => 'show_friendship';

#pod =method show_list_member([ \%args ])
#pod
#pod Aliases: is_list_member
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/members/show>
#pod
#pod =cut

sub show_list_member {
    shift->request(get => 'lists/members/show', @_);
}
alias is_list_member => 'show_list_member';

#pod =method show_list_subscriber([ \%args ])
#pod
#pod Aliases: is_list_subscriber, is_subscriber_lists
#pod
#pod L<https://dev.twitter.com/rest/reference/get/lists/subscribers/show>
#pod
#pod =cut

sub show_list_subscriber {
    shift->request(get => 'lists/subscribers/show', @_);
}
alias $_ => 'show_list_subscriber' for qw/is_list_subscriber is_subscriber_lists/;

#pod =method show_saved_search([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/saved_searches/show/:id>
#pod
#pod =cut

sub show_saved_search {
    shift->request_with_pos_args(id => get => 'saved_searches/show/:id', @_);
}

#pod =method show_status([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/show/:id>
#pod
#pod =cut

sub show_status {
    shift->request_with_pos_args(id => get => 'statuses/show/:id', @_);
}

#pod =method show_user([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/show>
#pod
#pod =cut

sub show_user {
    shift->request_with_pos_args(':ID', get => 'users/show', @_);
}

#pod =method suggestion_categories([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/suggestions>
#pod
#pod =cut

sub suggestion_categories {
    shift->request(get => 'users/suggestions', @_);
}

#pod =method trends_available([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/trends/available>
#pod
#pod =cut

sub trends_available {
    my ( $self, $args ) = @_;

    goto &trends_closest if exists $$args{lat} || exists $$args{long};

    shift->request(get => 'trends/available', @_);
}

#pod =method trends_closest([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/trends/closest>
#pod
#pod =cut

sub trends_closest {
    shift->request(get => 'trends/closest', @_);
}

#pod =method trends_place([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/trends/place>
#pod
#pod =cut

sub trends_place {
    shift->request_with_pos_args(id => get => 'trends/place', @_);
}
alias trends_location => 'trends_place';

#pod =method user_suggestions([ $slug, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/suggestions/:slug/members>
#pod
#pod =cut

# Net::Twitter compatibility - rename category to slug
my $rename_category = sub {
    my $self = shift;

    my $args = is_hashref($_[-1]) ? pop : {};
    $args->{slug} = delete $args->{category} if exists $args->{category};
    return ( @_, $args );
};

sub user_suggestions {
    my $self = shift;

    $self->request_with_pos_args(slug => get => 'users/suggestions/:slug/members',
        $self->$rename_category(@_));
}
alias follow_suggestions => 'user_suggestions';

#pod =method user_suggestions_for([ $slug, ][ \%args ])
#pod
#pod Aliases: follow_suggestions
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/suggestions/:slug>
#pod
#pod =cut

sub user_suggestions_for {
    my $self = shift;

    $self->request_with_pos_args(slug => get => 'users/suggestions/:slug',
        $self->$rename_category(@_));
}
alias follow_suggestions_for => 'user_suggestions_for';

#pod =method user_timeline([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/statuses/user_timeline>
#pod
#pod =cut

sub user_timeline {
    shift->request_with_id(get => 'statuses/user_timeline', @_);
}

#pod =method users_search([ $q, ][ \%args ])
#pod
#pod Aliases: find_people, search_users
#pod
#pod L<https://dev.twitter.com/rest/reference/get/users/search>
#pod
#pod =cut

sub users_search {
    shift->request_with_pos_args(q => get => 'users/search', @_);
}
alias $_ => 'users_search' for qw/find_people search_users/;

#pod =method verify_credentials([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/get/account/verify_credentials>
#pod
#pod =cut

sub verify_credentials {
    shift->request(get => 'account/verify_credentials', @_);
}

#pod =method add_collection_entry([ $id, [ $tweet_id, ]][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/entries/add>
#pod
#pod =cut

sub add_collection_entry {
    shift->request_with_pos_args([ qw/id tweet_id /],
        post => 'collections/entries/add', @_);
}

#pod =method add_list_member([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/members/create>
#pod
#pod =cut

sub add_list_member {
    shift->request(post => 'lists/members/create', @_);
}

# deprecated: https://dev.twitter.com/rest/reference/post/geo/place
sub add_place {
    shift->request_with_pos_args([ qw/name contained_within token lat long/ ],
        post => 'geo/place', @_);
}

#pod =method create_block([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/blocks/create>
#pod
#pod =cut

sub create_block {
    shift->request_with_pos_args(':ID', post => 'blocks/create', @_);
}

#pod =method create_collection([ $name, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/create>
#pod
#pod =cut

sub create_collection {
    shift->request_with_pos_args(name => post => 'collections/create', @_);
}

#pod =method create_favorite([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/favorites/create>
#pod
#pod =cut

sub create_favorite {
    shift->request_with_pos_args(id => post => 'favorites/create', @_);
}

#pod =method create_friend([ $screen_name | $user_id, ][ \%args ])
#pod
#pod Aliases: follow, follow_new, create_friendship
#pod
#pod L<https://dev.twitter.com/rest/reference/post/friendships/create>
#pod
#pod =cut

sub create_friend {
    shift->request_with_pos_args(':ID', post => 'friendships/create', @_);
}
alias $_ => 'create_friend' for qw/follow follow_new create_friendship/;

#pod =method create_list([ $name, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/create>
#pod
#pod =cut

sub create_list {
    shift->request_with_pos_args(name => post => 'lists/create', @_);
}

#pod =method create_media_metadata([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/media/metadata/create>
#pod
#pod =cut

# E.g.:
# create_media_metadata({ media_id => $id, alt_text => { text => $text } })
sub create_media_metadata {
    my ( $self, $to_json ) = @_;

    croak 'expected a single hashref argument'
        unless @_ == 2 && is_hashref($_[1]);

    $self->request(post => 'media/metadata/create', {
        -to_json => $to_json,
    });
}

#pod =method create_mute([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/mutes/users/create>
#pod
#pod Alias: mute
#pod
#pod =cut

sub create_mute {
    shift->request_with_pos_args(':ID' => post => 'mutes/users/create', @_);
}
alias mute => 'create_mute';

#pod =method create_saved_search([ $query, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/saved_searches/create>
#pod
#pod =cut

sub create_saved_search {
    shift->request_with_pos_args(query => post => 'saved_searches/create', @_);
}

#pod =method curate_collection([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/entries/curate>
#pod
#pod =cut

sub curate_collection {
    my ( $self, $to_json ) = @_;

    croak 'unexpected extra args' if @_ > 2;
    $self->request(post => 'collections/entries/curate', {
        -to_json => $to_json,
    });
}

#pod =method delete_list([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/destroy>
#pod
#pod =cut

sub delete_list {
    shift->request(post => 'lists/destroy', @_);
}

#pod =method delete_list_member([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/members/destroy>
#pod
#pod =cut

sub delete_list_member {
    shift->request(post => 'lists/members/destroy', @_);
}
alias remove_list_member => 'delete_list_member';

#pod =method destroy_block([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/blocks/destroy>
#pod
#pod =cut

sub destroy_block {
    shift->request_with_pos_args(':ID', post => 'blocks/destroy', @_);
}

#pod =method destroy_collection([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/destroy>
#pod
#pod =cut

sub destroy_collection {
    shift->request_with_pos_args(id => post => 'collections/destroy', @_);
}

#pod =method destroy_direct_message([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/direct_messages/destroy>
#pod
#pod =cut

sub destroy_direct_message {
    shift->request_with_pos_args(id => post => 'direct_messages/destroy', @_);
}

#pod =method destroy_favorite([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/favorites/destroy>
#pod
#pod =cut

sub destroy_favorite {
    shift->request_with_pos_args(id => post => 'favorites/destroy', @_);
}

#pod =method destroy_friend([ $screen_name | $user_id, ][ \%args ])
#pod
#pod Aliases: unfollow, destroy_friendship
#pod
#pod L<https://dev.twitter.com/rest/reference/post/friendships/destroy>
#pod
#pod =cut

sub destroy_friend {
    shift->request_with_pos_args(':ID', post => 'friendships/destroy', @_);
}
alias $_ => 'destroy_friend' for qw/unfollow destroy_friendship/;

#pod =method destroy_mute([ $screen_name | $user_id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/mutes/users/destroy>
#pod
#pod Alias: unmute
#pod
#pod =cut

sub destroy_mute {
    shift->request_with_pos_args(':ID' => post => 'mutes/users/destroy', @_);
}
alias unmute => 'destroy_mute';

#pod =method destroy_saved_search([ $id, ][ \%args ])
#pod
#pod Aliases: delete_saved_search
#pod
#pod L<https://dev.twitter.com/rest/reference/post/saved_searches/destroy/:id>
#pod
#pod =cut

sub destroy_saved_search {
    shift->request_with_pos_args(id => post => 'saved_searches/destroy/:id', @_);
}
alias delete_saved_search => 'destroy_saved_search';

#pod =method destroy_status([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/statuses/destroy/:id>
#pod
#pod =cut

sub destroy_status {
    shift->request_with_pos_args(id => post => 'statuses/destroy/:id', @_);
}

#pod =method members_create_all([ \%args ])
#pod
#pod Aliases: add_list_members
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/members/create_all>
#pod
#pod =cut

sub members_create_all {
    shift->request(post => 'lists/members/create_all', @_);
}
alias add_list_members => 'members_create_all';

#pod =method members_destroy_all([ \%args ])
#pod
#pod Aliases: remove_list_members
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/members/destroy_all>
#pod
#pod =cut

sub members_destroy_all {
    shift->request(post => 'lists/members/destroy_all', @_);
}
alias remove_list_members => 'members_destroy_all';

#pod =method move_collection_entry([ $id, [ $tweet_id, [ $relative_to, ]]][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/entries/move>
#pod
#pod =cut

sub move_collection_entry {
    shift->request_with_pos_args([ qw/id tweet_id relative_to /],
        post => 'collections/entries/move', @_);
}

#pod =method new_direct_message([ $text, [ $screen_name | $user_id, ]][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/direct_messages/new>
#pod
#pod =cut

sub new_direct_message {
    shift->request_with_pos_args([ qw/text :ID/ ], post => 'direct_messages/new', @_);
}

#pod =method remove_collection_entry([ $id, [ $tweet_id, ]][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/entries/remove>
#pod
#pod =cut

sub remove_collection_entry {
    shift->request_with_pos_args([ qw/id tweet_id/ ],
        post => 'collections/entries/remove', @_);
}

#pod =method remove_profile_banner([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/account/remove_profile_banner>
#pod
#pod =cut

sub remove_profile_banner {
    shift->request(post => 'account/remove_profile_banner', @_);
}

#pod =method report_spam([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/users/report_spam>
#pod
#pod =cut

sub report_spam {
    shift->request_with_id(post => 'users/report_spam', @_);
}

#pod =method retweet([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/statuses/retweet/:id>
#pod
#pod =cut

sub retweet {
    shift->request_with_pos_args(id => post => 'statuses/retweet/:id', @_);
}

#pod =method subscribe_list([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/subscribers/create>
#pod
#pod =cut

sub subscribe_list {
    shift->request(post => 'lists/subscribers/create', @_);
}

#pod =method unretweet([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/statuses/unretweet/:id>
#pod
#pod =cut

sub unretweet {
    shift->request_with_pos_args(id => post => 'statuses/unretweet/:id', @_);
}

#pod =method unsubscribe_list([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/subscribers/destroy>
#pod
#pod =cut

sub unsubscribe_list {
    shift->request(post => 'lists/subscribers/destroy', @_);
}

#pod =method update([ $status, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/statuses/update>
#pod
#pod =cut

sub update {
    my $self = shift;

    my ( $http_method, $path, $args, @rest ) =
        $self->normalize_pos_args(status => post => 'statuses/update', @_);

    $self->flatten_list_args(media_ids => $args);
    return $self->request($http_method, $path, $args, @rest);
}

#pod =method update_account_settings([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/account/settings>
#pod
#pod =cut

sub update_account_settings {
    shift->request(post => 'account/settings', @_);
}

#pod =method update_collection([ $id, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/collections/update>
#pod
#pod =cut

sub update_collection {
    shift->request_with_pos_args(id => post => 'collections/update', @_);
}

#pod =method update_friendship([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/friendships/update>
#pod
#pod =cut

sub update_friendship {
    shift->request_with_id(post => 'friendships/update', @_);
}

#pod =method update_list([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/lists/update>
#pod
#pod =cut

sub update_list {
    shift->request(post => 'lists/update', @_);
}

#pod =method update_profile([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/account/update_profile>
#pod
#pod =cut

sub update_profile {
    shift->request(post => 'account/update_profile', @_);
}

#pod =method update_profile_background_image([ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/account/update_profile_background_image>
#pod
#pod =cut

sub update_profile_background_image {
    shift->request(post => 'account/update_profile_background_image', @_);
}

#pod =method update_profile_banner([ $banner, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/account/update_profile_banner>
#pod
#pod =cut

sub update_profile_banner {
    shift->request_with_pos_args(banner => post => 'account/update_profile_banner', @_);
}

#pod =method update_profile_image([ $image, ][ \%args ])
#pod
#pod L<https://dev.twitter.com/rest/reference/post/account/update_profile_image>
#pod
#pod =cut

sub update_profile_image {
    shift->request_with_pos_args(image => post => 'account/update_profile_image', @_);
}

#pod =method upload_media([ $media, ][ \%args ])
#pod
#pod Aliases: upload
#pod
#pod L<https://dev.twitter.com/rest/reference/post/media/upload>
#pod
#pod =cut

sub upload_media {
    my $self = shift;

    # Used to require media. Now requires media *or* media_data.
    # Handle either as a positional parameter, like we do with
    # screen_name or user_id on other methods.
    if ( @_ && !is_hashref($_[0]) ) {
        my $media = shift;
        my $key = is_arrayref($media) ? 'media' : 'media_data';
        my $args = @_ && is_hashref($_[0]) ? pop : {};
        $args->{$key} = $media;
        unshift @_, $args;
    }

    my $args = shift;
    $args->{-multipart_form_data} = 1;
    $self->flatten_list_args(additional_owners => $args);

    $self->request(post => $self->upload_url_for('media/upload'), $args, @_);
}
alias upload => 'upload_media';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Trait::ApiMethods - Convenient API Methods

=head1 VERSION

version 0.0112

=head1 DESCRIPTION

This trait provides convenient methods for calling API endpoints. They are
L<Net::Twitter> compatible, with the same names and calling conventions.

Refer to L<Twitter's API documentation|https://dev.twitter.com/rest/reference>
for details about each method's parameters.

These methods are simply shorthand forms of C<get> and C<post>.  All methods
can be called with a parameters hashref. It can be omitted for endpoints that
do not require any parameters, such as C<mentions>. For example, all of these
calls are equivalent:

    $client->mentions;
    $client->mentions({});
    $client->get('statuses/mentions_timeline');
    $client->get('statuses/mentions_timelien', {});

Use the parameters hashref to pass optional parameters. For example,

    $client->mentions({ count => 200, trim_user=>'true' });

Some methods, with required parameters, can take positional parameters. For
example, C<geo_id> requires a C<place_id> parameter. These calls are
equivalent:

    $client->place_id($place);
    $client->place_id({ place_id => $place });

When positional parameters are allowed, they must be specified in the correct
order, but they don't all need to be specified. Those not specified
positionally can be added to the parameters hashref. For example, these calls
are equivalent:

    $client->add_collection_entry($id, $tweet_id);
    $client->add_collection_entry($id, { tweet_id => $tweet_id);
    $client->add_collection_entry({ id => $id, tweet_id => $tweet_id });

Many calls require a C<screen_name> or C<user_id>. Where noted, you may pass
either ID as the first positional parameter. Twitter::API will inspect the
value. If it contains only digits, it will be considered a C<user_id>.
Otherwise, it will be considered a C<screen_name>. Best practice is to
explicitly declare the ID type by passing it in the parameters hashref, because
it is possible to for users to set their screen names to a string of digits,
making the inferred ID ambiguous. These calls are equivalent:

   $client->create_block('realDonaldTrump');
   $client->create_block({ screen_name => 'realDonaldTrump' });

Since all of these methods simple resolve to a C<get> or C<post> call, see the
L<Twitter::API> for details about return values and error handling.

=head1 METHODS

=head2 account_settings([ \%args ])

L<https://dev.twitter.com/rest/reference/get/account/settings>

=head2 blocking([ \%args ])

Aliases: blocks_list

L<https://dev.twitter.com/rest/reference/get/blocks/list>

=head2 blocking_ids([ \%args ])

Aliases: blocks_ids

L<https://dev.twitter.com/rest/reference/get/blocks/ids>

=head2 collection_entries([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/collections/entries>

=head2 collections([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/collections/list>

=head2 direct_messages([ \%args ])

L<https://dev.twitter.com/rest/reference/get/direct_messages>

=head2 favorites([ \%args ])

L<https://dev.twitter.com/rest/reference/get/favorites/list>

=head2 followers([ \%args ])

Aliases: followers_list

L<https://dev.twitter.com/rest/reference/get/followers/list>

=head2 followers_ids([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/followers/ids>

=head2 friends([ \%args ])

Aliases: friends_list

L<https://dev.twitter.com/rest/reference/get/friends/list>

=head2 friends_ids([ \%args ])

Aliases: following_ids

L<https://dev.twitter.com/rest/reference/get/friends/ids>

=head2 friendships_incoming([ \%args ])

Aliases: incoming_friendships

L<https://dev.twitter.com/rest/reference/get/friendships/incoming>

=head2 friendships_outgoing([ \%args ])

Aliases: outgoing_friendships

L<https://dev.twitter.com/rest/reference/get/friendships/outgoing>

=head2 geo_id([ $place_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/geo/id/:place_id>

=head2 geo_search([ \%args ])

L<https://dev.twitter.com/rest/reference/get/geo/search>

=head2 get_configuration([ \%args ])

L<https://dev.twitter.com/rest/reference/get/help/configuration>

=head2 get_languages([ \%args ])

L<https://dev.twitter.com/rest/reference/get/help/languages>

=head2 get_list([ \%args ])

Aliases: show_list

L<https://dev.twitter.com/rest/reference/get/lists/show>

=head2 get_lists([ \%args ])

Aliases: list_lists, all_subscriptions

L<https://dev.twitter.com/rest/reference/get/lists/list>

=head2 get_privacy_policy([ \%args ])

L<https://dev.twitter.com/rest/reference/get/help/privacy>

=head2 get_tos([ \%args ])

L<https://dev.twitter.com/rest/reference/get/help/tos>

=head2 home_timeline([ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/home_timeline>

=head2 list_members([ \%args ])

L<https://dev.twitter.com/rest/reference/get/lists/members>

=head2 list_memberships([ \%args ])

L<https://dev.twitter.com/rest/reference/get/lists/memberships>

=head2 list_ownerships([ \%args ])

L<https://dev.twitter.com/rest/reference/get/lists/ownerships>

=head2 list_statuses([ \%args ])

L<https://dev.twitter.com/rest/reference/get/lists/statuses>

=head2 list_subscribers([ \%args ])

L<https://dev.twitter.com/rest/reference/get/lists/subscribers>

=head2 list_subscriptions([ \%args ])

Aliases: subscriptions

L<https://dev.twitter.com/rest/reference/get/lists/subscriptions>

=head2 lookup_friendships([ \%args ])

L<https://dev.twitter.com/rest/reference/get/friendships/lookup>

=head2 lookup_statuses([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/lookup>

=head2 lookup_users([ \%args ])

L<https://dev.twitter.com/rest/reference/get/users/lookup>

=head2 mentions([ \%args ])

Aliases: replies, mentions_timeline

L<https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline>

=head2 mutes([ \%args ])

Aliases: muting_ids, muted_ids

L<https://dev.twitter.com/rest/reference/get/mutes/users/ids>

=head2 muting([ \%args ])

Aliases: mutes_list

L<https://dev.twitter.com/rest/reference/get/mutes/users/list>

=head2 no_retweet_ids([ \%args ])

Aliases: no_retweets_ids

L<https://dev.twitter.com/rest/reference/get/friendships/no_retweets/ids>

=head2 oembed([ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/oembed>

=head2 profile_banner([ \%args ])

L<https://dev.twitter.com/rest/reference/get/users/profile_banner>

=head2 rate_limit_status([ \%args ])

L<https://dev.twitter.com/rest/reference/get/application/rate_limit_status>

=head2 retweeters_ids([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/retweeters/ids>

=head2 retweets([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/retweets/:id>

=head2 retweets_of_me([ \%args ])

Aliases: retweeted_of_me

L<https://dev.twitter.com/rest/reference/get/statuses/retweets_of_me>

=head2 reverse_geocode([ $lat, [ $long, ]][ \%args ])

L<https://dev.twitter.com/rest/reference/get/geo/reverse_geocode>

=head2 saved_searches([ \%args ])

L<https://dev.twitter.com/rest/reference/get/saved_searches/list>

=head2 search([ $q, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/search/tweets>

=head2 sent_direct_messages([ \%args ])

Aliases: direct_messages_sent

L<https://dev.twitter.com/rest/reference/get/direct_messages/sent>

=head2 show_direct_message([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/direct_messages/show>

=head2 show_friendship([ \%args ])

Aliases: show_relationship

L<https://dev.twitter.com/rest/reference/get/friendships/show>

=head2 show_list_member([ \%args ])

Aliases: is_list_member

L<https://dev.twitter.com/rest/reference/get/lists/members/show>

=head2 show_list_subscriber([ \%args ])

Aliases: is_list_subscriber, is_subscriber_lists

L<https://dev.twitter.com/rest/reference/get/lists/subscribers/show>

=head2 show_saved_search([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/saved_searches/show/:id>

=head2 show_status([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/show/:id>

=head2 show_user([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/users/show>

=head2 suggestion_categories([ \%args ])

L<https://dev.twitter.com/rest/reference/get/users/suggestions>

=head2 trends_available([ \%args ])

L<https://dev.twitter.com/rest/reference/get/trends/available>

=head2 trends_closest([ \%args ])

L<https://dev.twitter.com/rest/reference/get/trends/closest>

=head2 trends_place([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/trends/place>

=head2 user_suggestions([ $slug, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/users/suggestions/:slug/members>

=head2 user_suggestions_for([ $slug, ][ \%args ])

Aliases: follow_suggestions

L<https://dev.twitter.com/rest/reference/get/users/suggestions/:slug>

=head2 user_timeline([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/get/statuses/user_timeline>

=head2 users_search([ $q, ][ \%args ])

Aliases: find_people, search_users

L<https://dev.twitter.com/rest/reference/get/users/search>

=head2 verify_credentials([ \%args ])

L<https://dev.twitter.com/rest/reference/get/account/verify_credentials>

=head2 add_collection_entry([ $id, [ $tweet_id, ]][ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/entries/add>

=head2 add_list_member([ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/members/create>

=head2 create_block([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/blocks/create>

=head2 create_collection([ $name, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/create>

=head2 create_favorite([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/favorites/create>

=head2 create_friend([ $screen_name | $user_id, ][ \%args ])

Aliases: follow, follow_new, create_friendship

L<https://dev.twitter.com/rest/reference/post/friendships/create>

=head2 create_list([ $name, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/create>

=head2 create_media_metadata([ \%args ])

L<https://dev.twitter.com/rest/reference/post/media/metadata/create>

=head2 create_mute([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/mutes/users/create>

Alias: mute

=head2 create_saved_search([ $query, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/saved_searches/create>

=head2 curate_collection([ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/entries/curate>

=head2 delete_list([ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/destroy>

=head2 delete_list_member([ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/members/destroy>

=head2 destroy_block([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/blocks/destroy>

=head2 destroy_collection([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/destroy>

=head2 destroy_direct_message([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/direct_messages/destroy>

=head2 destroy_favorite([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/favorites/destroy>

=head2 destroy_friend([ $screen_name | $user_id, ][ \%args ])

Aliases: unfollow, destroy_friendship

L<https://dev.twitter.com/rest/reference/post/friendships/destroy>

=head2 destroy_mute([ $screen_name | $user_id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/mutes/users/destroy>

Alias: unmute

=head2 destroy_saved_search([ $id, ][ \%args ])

Aliases: delete_saved_search

L<https://dev.twitter.com/rest/reference/post/saved_searches/destroy/:id>

=head2 destroy_status([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/statuses/destroy/:id>

=head2 members_create_all([ \%args ])

Aliases: add_list_members

L<https://dev.twitter.com/rest/reference/post/lists/members/create_all>

=head2 members_destroy_all([ \%args ])

Aliases: remove_list_members

L<https://dev.twitter.com/rest/reference/post/lists/members/destroy_all>

=head2 move_collection_entry([ $id, [ $tweet_id, [ $relative_to, ]]][ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/entries/move>

=head2 new_direct_message([ $text, [ $screen_name | $user_id, ]][ \%args ])

L<https://dev.twitter.com/rest/reference/post/direct_messages/new>

=head2 remove_collection_entry([ $id, [ $tweet_id, ]][ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/entries/remove>

=head2 remove_profile_banner([ \%args ])

L<https://dev.twitter.com/rest/reference/post/account/remove_profile_banner>

=head2 report_spam([ \%args ])

L<https://dev.twitter.com/rest/reference/post/users/report_spam>

=head2 retweet([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/statuses/retweet/:id>

=head2 subscribe_list([ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/subscribers/create>

=head2 unretweet([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/statuses/unretweet/:id>

=head2 unsubscribe_list([ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/subscribers/destroy>

=head2 update([ $status, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/statuses/update>

=head2 update_account_settings([ \%args ])

L<https://dev.twitter.com/rest/reference/post/account/settings>

=head2 update_collection([ $id, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/collections/update>

=head2 update_friendship([ \%args ])

L<https://dev.twitter.com/rest/reference/post/friendships/update>

=head2 update_list([ \%args ])

L<https://dev.twitter.com/rest/reference/post/lists/update>

=head2 update_profile([ \%args ])

L<https://dev.twitter.com/rest/reference/post/account/update_profile>

=head2 update_profile_background_image([ \%args ])

L<https://dev.twitter.com/rest/reference/post/account/update_profile_background_image>

=head2 update_profile_banner([ $banner, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/account/update_profile_banner>

=head2 update_profile_image([ $image, ][ \%args ])

L<https://dev.twitter.com/rest/reference/post/account/update_profile_image>

=head2 upload_media([ $media, ][ \%args ])

Aliases: upload

L<https://dev.twitter.com/rest/reference/post/media/upload>

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2016 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
