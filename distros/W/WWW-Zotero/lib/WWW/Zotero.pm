package WWW::Zotero;

=pod 

=head1 NAME

WWW::Zotero - Perl interface to the Zotero API

=head1 SYNOPSIS

    use WWW::Zotero;

    my $client = WWW::Zotero->new;
    my $client = WWW::Zotero->new(key => 'API-KEY');

    my $data = $client->itemTypes();
    
    for my $item (@$data) {
        print "%s\n" , $item->itemType;
    } 

    my $data   = $client->itemFields();
    my $data   = $client->itemTypeFields('book');
    my $data   = $client->itemTypeCreatorTypes('book');
    my $data   = $client->creatorFields();
    my $data   = $client->itemTemplate('book');
    my $key    = $client->keyPermissions();
    my $groups = $client->userGroups($userID);

    my $data   = $client->listItems(user => '475425', limit => 5);
    my $data   = $client->listItems(user => '475425', format => 'atom');
    my $generator = $client->listItems(user => '475425', generator => 1);

    while (my $item = $generator->()) {
        print "%s\n" , $item->{title};
    }

    my $data = $client->listItemsTop(user => '475425', limit => 5);
    my $data = $client->listItemsTrash(user => '475425');
    my $data = $client->getItem(user => '475425', itemKey => 'TTJFTW87');
    my $data = $client->getItemTags(user => '475425', itemKey => 'X42A7DEE');
    my $data = $client->listTags(user => '475425');
    my $data = $client->listTags(user => '475425', tag => 'Biography');
    my $data = $client->listCollections(user => '475425');
    my $data = $client->listCollectionsTop(user => '475425');
    my $data = $client->getCollection(user => '475425', collectionKey => 'A5G9W6AX');
    my $data = $client->listSubCollections(user => '475425', collectionKey => 'QM6T3KHX');
    my $data = $client->listCollectionItems(user => '475425', collectionKey => 'QM6T3KHX');
    my $data = $client->listCollectionItemsTop(user => '475425', collectionKey => 'QM6T3KHX');
    my $data = $client->listCollectionItemsTags(user => '475425', collectionKey => 'QM6T3KHX');
    my $data = $client->listSearches(user => '475425');

=cut

use Moo;
use JSON;
use URI::Escape;
use REST::Client;
use Data::Dumper;
use POSIX qw(strftime);
use Carp;
use Log::Any ();
use feature 'state';

our $VERSION = '0.03';

=head1 CONFIGURATION

=over 4

=item baseurl 

The base URL for all API requests. Default 'https://api.zotero.org'.

=item version

The API version. Default '3'.

=item key

The API key which can be requested via https://api.zotero.org.

=item modified_since

Include a UNIX time to be used in a If-Modified-Since header to allow for caching
of results by your application.

=back

=cut
has baseurl => (is => 'ro' , default => sub { 'https://api.zotero.org' });
has modified_since => (is => 'ro');
has version => (is => 'ro' , default => sub { '3'});
has key     => (is => 'ro');
has code    => (is => 'rw');
has sleep   => (is => 'rw' , default => sub { 0 });
has log     => (is => 'lazy');
has client  => (is => 'lazy');

sub _build_client {
    my ($self) = @_;
    my $client = REST::Client->new();

    $self->log->debug("< Zotero-API-Version: " . $self->version); 
    $client->addHeader('Zotero-API-Version', $self->version);

    if (defined $self->key) {
        my $authorization = 'Bearer ' . $self->key;
        $self->log->debug("< Authorization: " . $authorization);
        $client->addHeader('Authorization', $authorization);
    }

    if (defined $self->modified_since) {
        my $date = strftime "%a, %d %b %Y %H:%M:%S GMT" , gmtime($self->modified_since);
        $self->log->debug("< If-Modified-Since: " . $date);
        $client->addHeader('If-Modified-Since',$date);
    }

    $client;
}

sub _build_log {
    my ($self) = @_;
    Log::Any->get_logger(category => ref($self));
}

sub _zotero_get_request {
    my ($self,$path,%param) = @_;

    my $url        = sprintf "%s%s" , $self->baseurl, $path;

    my @params = ();
    for my $name (keys %param) {
        my $value = $param{$name};
        push @params , uri_escape($name) . "=" . uri_escape($value);
    }

    $url .= '?' . join("&",@params) if @params > 0;

    # The server asked us to sleep..
    if ($self->sleep > 0) {
        $self->log->debug("sleeping: " . $self->sleep . " seconds");
        sleep $self->sleep;
        $self->sleep(0)
    }

    $self->log->debug("requesting: $url");
    my $response  = $self->client->GET($url);

    my $backoff    = $response->responseHeader('Backoff') // 0;
    my $retryAfter = $response->responseHeader('Retry-After') // 0;
    my $code       = $response->responseCode();

    $self->log->debug("> Code: $code");
    $self->log->debug("> Backoff: $backoff");
    $self->log->debug("> Retry-After: $retryAfter");

    if ($backoff > 0) {
        $self->sleep($backoff);
    }
    elsif ($code eq '429' || $code eq '503') {
        $self->sleep($retryAfter // 60);
        return undef;
    }
    
    $self->log->debug("> Content: " . $response->responseContent);

    $self->code($code);

    return undef unless $code eq '200';

    $response;
}

=head1 METHODS

=head2 itemTypes()

Get all item types. Returns a Perl array.

=cut
sub itemTypes {
    my ($self) = @_;

    my $response = $self->_zotero_get_request('/itemTypes');

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 itemTypes()

Get all item fields. Returns a Perl array.

=cut
sub itemFields {
    my ($self) = @_;

    my $response = $self->_zotero_get_request('/itemFields');

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 itemTypes($type)

Get all valid fields for an item type. Returns a Perl array.

=cut
sub itemTypeFields {
    my ($self,$itemType) = @_;

    croak "itemTypeFields: need itemType" unless defined $itemType;

    my $response = $self->_zotero_get_request('/itemTypeFields', itemType => $itemType);

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 itemTypeCreatorTypes($type)

Get valid creator types for an item type. Returns a Perl array.

=cut
sub itemTypeCreatorTypes {
    my ($self,$itemType) = @_;

    croak "itemTypeCreatorTypes: need itemType" unless defined $itemType;

    my $response = $self->_zotero_get_request('/itemTypeCreatorTypes', itemType => $itemType);

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 creatorFields()

Get localized creator fields. Returns a Perl array.

=cut
sub creatorFields {
    my ($self) = @_;

    my $response = $self->_zotero_get_request('/creatorFields');

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 itemTemplate($type)

Get a template for a new item. Returns a Perl hash.

=cut
sub itemTemplate {
    my ($self,$itemType) = @_;

    croak "itemTemplate: need itemType" unless defined $itemType;

    my $response = $self->_zotero_get_request('/items/new', itemType => $itemType);

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 keyPermissions($key)

Return the userID and premissions for the given API key.

=cut
sub keyPermissions {
    my ($self,$key) = @_;

    $key = $self->key unless defined $key;

    croak "keyPermissions: need key" unless defined $key;

    my $response = $self->_zotero_get_request("/keys/$key");

    return undef unless $response;

    decode_json $response->responseContent;
}

=head2 userGroups($userID)

Return an array of the set of groups the current API key as access to.

=cut
sub userGroups {
    my ($self,$userID) = @_;

    croak "userGroups: need userID" unless defined $userID;

    my $response = $self->_zotero_get_request("/users/$userID/groups");

    return undef unless $response;
    
    decode_json $response->responseContent;
}

=head2 listItems(user => $userID, %options)

=head2 listItems(group => $groupID, %options)

List all items for a user or ar group. Optionally provide a list of options:

    sort      - dateAdded, dateModified, title, creator, type, date, publisher, 
           publicationTitle, journalAbbreviation, language, accessDate, 
           libraryCatalog, callNumber, rights, addedBy, numItems (default dateModified)
    direction - asc, desc
    limit     - integer 1-100* (default 25)
    start     - integer
    format    - perl, atom, bib, json, keys, versions , bibtex , bookmarks, 
                coins, csljson, mods, refer, rdf_bibliontology , rdf_dc ,
                rdf_zotero, ris , tei , wikipedia (default perl)

    when format => 'json'

        include   - bib, data

    when format => 'atom'
    
        content   - bib, html, json

    when format => 'bib' or content => 'bib'

        style     - chicago-note-bibliography, apa, ...  (see: https://www.zotero.org/styles/)


    itemKey    - A comma-separated list of item keys. Valid only for item requests. Up to 
                 50 items can be specified in a single request.
    itemType   - Item type search
    q          - quick search
    qmode      - titleCreatorYear, everything
    since      - integer
    tag        - Tag search

See: https://www.zotero.org/support/dev/web_api/v3/basics#user_and_group_library_urls 
for the search syntax.

Returns a Perl HASH containing the total number of hits plus the results:
    
    {
        total => '132',
        results => <data>
    }

=head2 listItems(user => $userID | group => $groupID, generator => 1 , %options)

Same as listItems but this return a generator for every record found. Use this
method to sequentially read the complete resultset. E.g.

    my $generator = $self->listItems(user => '231231', generator);

    while (my $record = $generator->()) {
        printf "%s\n" , $record->{title};
    }

The format is implicit 'perl' in this case.

=cut 
sub listItems {
    my ($self,%options) = @_;

    $self->_listItems(%options, path => 'items');
}

sub _listItems {
    my ($self,%options) = @_;

    my $userID  = $options{user};
    my $groupID = $options{group};

    croak "listItems: need user or group" unless defined $userID || defined $groupID;

    my $id   = defined $userID ? $userID : $groupID;
    my $type = defined $userID ? 'users' : 'groups';
    
    my $generator = $options{generator};
    my $path      = $options{path};
    
    delete $options{generator};
    delete $options{path};
    delete $options{user};
    delete $options{group};
    delete $options{format} if exists $options{format} && $options{format} eq 'perl';

    $options{limit} = 25 unless defined $options{limit};

    if ($generator) {
        delete $options{format};
        $options{start} = 0 unless defined $options{start};

        return sub {
            state $response = $self->_listItems_request("/$type/$id/$path", %options);
            state $idx    = 0;

            return undef unless defined $response;
            return undef if $response->{total} == 0;
            return undef if $options{start} + $idx + 1 >= $response->{total};

            unless (defined $response->{results}->[$idx]) {
                $options{start} += $options{limit};
                $response = $self->_listItems_request("/$type/$id/$path", %options);
                $idx = 0;
            }

            return undef unless defined $response;

            my $doc = $response->{results}->[$idx];
            my $id  = $doc->{key};

            $idx++;

            { _id => $id , %$doc };
        };
    }
    else {
        return $self->_listItems_request("/$type/$id/$path", %options);
    }
}

sub _listItems_request {
    my ($self,$path,%options) = @_;
    my $response = $self->_zotero_get_request($path, %options);

    return undef unless defined $response;

    my $total = $response->responseHeader('Total-Results');
    my $link  = $response->responseHeader('Link');

    $self->log->debug("> Total-Results: $total") if defined $total;
    $self->log->debug("> Link: $link") if defined $link;

    my $results  = $response->responseContent;

    return undef unless $results;

    if (! defined $options{format} || $options{format} eq 'perl') {
        $results = decode_json $results;
    }

    return {
        total => $total,
        results => $results
    };
}

=head2 listItemsTop(user => $userID | group => $groupID, %options)

The set of all top-level items in the library, excluding trashed items. 

See 'listItems(...)' functions above for all the execution options.

=cut
sub listItemsTop {
    my ($self,%options) = @_;

    $self->_listItems(%options, path => 'items/top');
}

=head2 listItemsTrash(user => $userID | group => $groupID, %options)

The set of items in the trash. 

See 'listItems(...)' functions above for all the execution options.

=cut
sub listItemsTrash {
    my ($self,%options) = @_;

    $self->_listItems(%options, path => 'items/trash');
}

=head2 getItem(itemKey => ... , user => $userID | group => $groupID, %options)

A specific item in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the item if found.

=cut
sub getItem {
    my ($self,%options) = @_;

    my $key = $options{itemKey};

    croak "getItem: need itemKey" unless defined $key;

    delete $options{itemKey};

    my $result = $self->_listItems(%options, path => "items/$key");

    return undef unless defined $result;

    $result->{results};
}

=head2 getItemChildren(itemKey => ... , user => $userID | group => $groupID, %options)

The set of all child items under a specific item.

See 'listItems(...)' functions above for all the execution options.

Returns the children if found.

=cut
sub getItemChildren {
    my ($self,%options) = @_;

    my $key = $options{itemKey};

    croak "getItem: need itemKey" unless defined $key;

    delete $options{itemKey};

    my $result = $self->_listItems(%options, path => "items/$key/children");

    return undef unless defined $result;

    $result->{results};
}

=head2 getItemTags(itemKey => ... , user => $userID | group => $groupID, %options)

The set of all tags associated with a specific item.

See 'listItems(...)' functions above for all the execution options.

Returns the tags if found.

=cut
sub getItemTags {
    my ($self,%options) = @_;

    my $key = $options{itemKey};

    croak "getItem: need itemKey" unless defined $key;

    delete $options{itemKey};

    my $result = $self->_listItems(%options, path => "items/$key/tags");

    return undef unless defined $result;

    $result->{results};
}

=head2 listTags(user => $userID | group => $groupID, [tag => $name] , %options)

The set of tags (i.e., of all types) matching a specific name.

See 'listItems(...)' functions above for all the execution options.

Returns the list of tags.

=cut
sub listTags {
    my ($self,%options) = @_;

    my $tag = $options{tag};

    delete $options{tag};

    my $path = defined $tag ? "tags/" . uri_escape($tag) : "tags";

    $self->_listItems(%options, path => $path);
}

=head2 listCollections(user => $userID | group => $groupID , %options)

The set of all collections in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of collections.

=cut
sub listCollections {
    my ($self,%options) = @_;

    $self->_listItems(%options, path => "/collections");
}

=head2 listCollectionsTop(user => $userID | group => $groupID , %options)

The set of all top-level collections in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of collections.

=cut
sub listCollectionsTop {
    my ($self,%options) = @_;

    $self->_listItems(%options, path => "collections/top");
}

=head2 getCollection(collectionKey => ... , user => $userID | group => $groupID, %options)

A specific item in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the collection if found.

=cut
sub getCollection {
    my ($self,%options) = @_;

    my $key = $options{collectionKey};

    croak "getCollection: need collectionKey" unless defined $key;

    delete $options{collectionKey};

    my $result = $self->_listItems(%options, path => "collections/$key");

    return undef unless defined $result;

    $result->{results};
}

=head2 listSubCollections(collectionKey => ...., user => $userID | group => $groupID , %options)

The set of subcollections within a specific collection in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of (sub)collections.

=cut
sub listSubCollections {
    my ($self,%options) = @_;

    my $key = $options{collectionKey};

    croak "listSubCollections: need collectionKey" unless defined $key;

    delete $options{collectionKey};

    $self->_listItems(%options, path => "collections/$key/collections");
}

=head2 listCollectionItems(collectionKey => ...., user => $userID | group => $groupID , %options)

The set of all items within a specific collection in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of items.

=cut
sub listCollectionItems {
    my ($self,%options) = @_;

    my $key = $options{collectionKey};

    croak "listCollectionItems: need collectionKey" unless defined $key;

    delete $options{collectionKey};

    $self->_listItems(%options, path => "collections/$key/items");
}

=head2 listCollectionItemsTop(collectionKey => ...., user => $userID | group => $groupID , %options)

The set of top-level items within a specific collection in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of items.

=cut
sub listCollectionItemsTop {
    my ($self,%options) = @_;

    my $key = $options{collectionKey};

    croak "listCollectionItemsTop: need collectionKey" unless defined $key;

    delete $options{collectionKey};

    $self->_listItems(%options, path => "collections/$key/items/top");
}

=head2 listCollectionItemsTags(collectionKey => ...., user => $userID | group => $groupID , %options)

The set of tags within a specific collection in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of items.

=cut
sub listCollectionItemsTags {
    my ($self,%options) = @_;

    my $key = $options{collectionKey};

    croak "listCollectionItemsTop: need collectionKey" unless defined $key;

    delete $options{collectionKey};

    $self->_listItems(%options, path => "collections/$key/tags");
}

=head2 listSearches(user => $userID | group => $groupID , %options)

The set of all saved searches in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the list of saved searches.

=cut
sub listSearches {
    my ($self,%options) = @_;

    $self->_listItems(%options, path => "searches");
}

=head2 getSearch(searchKey => ... , user => $userID | group => $groupID, %options)

A specific saved search in the library.

See 'listItems(...)' functions above for all the execution options.

Returns the saved search if found.

=cut
sub getSearch {
    my ($self,%options) = @_;

    my $key = $options{searchKey};

    croak "getSearch: need searchKey" unless defined $key;

    delete $options{searchKey};

    my $result = $self->_listItems(%options, path => "search/$key");

    return undef unless defined $result;

    $result->{results};
}

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Patrick Hochstenbach

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;


