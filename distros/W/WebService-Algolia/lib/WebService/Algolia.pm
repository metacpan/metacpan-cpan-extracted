package WebService::Algolia;
$WebService::Algolia::VERSION = '0.1002';
use 5.008001;
use Moo;
with 'WebService::Client';

# VERSION

use Carp;
use Method::Signatures;
use Storable qw(dclone);
use URI;

has api_key        => ( is => 'ro', required => 1                   );
has application_id => ( is => 'ro', required => 1                   );
has batch_mode     => ( is => 'rw', default => 0, init_arg => undef );

has '+base_url'    => ( is => 'ro', default =>
    method {
        'https://' . $self->application_id . '.algolia.io/1'
    }
);

method BUILD(...) {
    $self->ua->default_header('X-Algolia-Application-Id' => $self->application_id);
    $self->ua->default_header('X-Algolia-API-Key' => $self->api_key);
}

method get_indexes {
    return $self->get('/indexes');
}

method browse_index(Str $index) {
    return $self->get("/indexes/$index/browse");
}

method query_index(HashRef $query) {
    my $index = delete $query->{index};
    croak 'The \'index\' parameter is required' unless $index;
    return $self->get("/indexes/$index", $query);
}

method query_indexes(ArrayRef $queries) {
    my $requests = dclone $queries;
    $requests = [ map {
        my $index = delete $_->{index};
        croak 'The \'index\' parameter is required' unless $index;
        my $uri = URI->new;
        $uri->query_form( %$_ );
        { indexName => $index, params => substr($uri, 1) };
    } @$requests ];
    return $self->post('/indexes/*/queries', { requests => $requests });
}

method clear_index(Str $index) {
    return $self->post("/indexes/$index/clear", {});
}

method copy_index(Str $source, Str $destination) {
    return $self->post("/indexes/$source/operation", {
        operation   => 'copy',
        destination => $destination,
    });
}

method move_index(Str $source, Str $destination) {
    return $self->post("/indexes/$source/operation", {
        operation   => 'move',
        destination => $destination,
    });
}

method delete_index(Str $index) {
    return $self->delete("/indexes/$index");
}

method get_index_settings(Str $index) {
    return $self->get("/indexes/$index/settings");
}

method update_index_settings(Str $index, $settings) {
    return $self->put("/indexes/$index/settings", $settings);
}

method get_index_object(Str $index, Str $object_id) {
    return $self->get("/indexes/$index/$object_id");
}

method get_index_objects(ArrayRef $objects) {
    my $requests = dclone $objects;
    $requests = [ map {
        my $index = delete $_->{index};
        croak 'The \'index\' parameter is required' unless $index;
        my $object = delete $_->{object};
        croak 'The \'object\' parameter is required' unless $object;
        { indexName => $index, objectID => $object }
    } @$requests ];
    return $self->post('/indexes/*/objects', { requests => $requests });
}

method create_index_object(Str $index, HashRef $data) {
    return $self->post("/indexes/$index", $data);
}

method replace_index_object(Str $index, Str $object_id, HashRef $data) {
    return $self->put("/indexes/$index/$object_id", $data);
}

method update_index_object(Str $index, Str $object_id, HashRef $data) {
    return $self->post("/indexes/$index/$object_id/partial", $data);
}

method delete_index_object(Str $index, Str $object_id) {
    return $self->delete("/indexes/$index/$object_id");
}

method batch_index_objects(Str $index, ArrayRef[CodeRef] $operations) {
    $self->batch_mode(1);
    my $requests = [ map { $_->() } @$operations ];
    $self->batch_mode(0);
    return $self->post("/indexes/$index/batch", { requests => $requests });
}

method get_index_keys(Str $index = '') {
    return $index
        ? $self->get("/indexes/$index/keys")
        : $self->get('/indexes/*/keys');
}

method get_index_key(Str $index, Str $key) {
    return $self->get("/indexes/$index/keys/$key");
}

method create_index_key(Str $index, HashRef $data) {
    return $self->post("/indexes/$index/keys", $data);
}

method update_index_key(Str $index, Str $key, HashRef $data) {
    return $self->put("/indexes/$index/keys/$key", $data);
}

method delete_index_key(Str $index, Str $key) {
    return $self->delete("/indexes/$index/keys/$key");
}

method get_task_status(Str $index, Str $task_id) {
    return $self->get("/indexes/$index/task/$task_id");
}

method get_keys {
    return $self->get('/keys');
}

method get_key(Str $key) {
    return $self->get("/keys/$key");
}

method create_key(HashRef $data) {
    return $self->post('/keys', $data);
}

method update_key(Str $key, HashRef $data) {
    return $self->put("/keys/$key", $data);
}

method delete_key(Str $key) {
    return $self->delete("/keys/$key");
}

method get_logs(HashRef $params = {}) {
    return $self->get('/logs', $params);
}

method get_popular_searches(ArrayRef[Str] $indexes = []) {
    my $csv_indexes = join ',', @$indexes;
    return $self->get(_analytics_uri("/searches/$csv_indexes/popular"));
}

method get_unpopular_searches(ArrayRef[Str] $indexes = []) {
    my $csv_indexes = join ',', @$indexes;
    return $self->get(_analytics_uri("/searches/$csv_indexes/noresults"));
}

func _analytics_uri(Str $uri) {
    return "https://analytics.algolia.com/1$uri";
}

for my $func (qw/put post delete/) {
    around $func => sub {
        my ($orig, $self, @args) = @_;
        if ($self->batch_mode) {
            my ($path, $body) = @args;
            return {
                method => uc $func,
                path   => "/1$path",
                (body  => $body) x!! $body,
            };
        } else {
            return $self->$orig(@args);
        }
    };
}

# ABSTRACT: Algolia API Bindings


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Algolia - Algolia API Bindings

=head1 VERSION

version 0.1002

=head1 SYNOPSIS

    use WebService::Algolia;

    my $alg = WebService::Algolia->new(
        application_id => '12345',
        api_key        => 'abcde',
    );

    $alg->get_indexes;

=head1 DESCRIPTION

This module provides bindings for the
L<Algolia|https://www.algolia.com/doc> API.

=for markdown [![Build Status](https://travis-ci.org/aanari/WebService-Algolia.svg?branch=master)](https://travis-ci.org/aanari/WebService-Algolia)

=head1 METHODS

=head2 new

Instantiates a new WebService::Algolia client object.

    my $alg = WebService::Algolia->new(
        application_id => $application_id,
        api_key        => $api_key,
        timeout        => $retries,    # optional
        retries        => $retries,    # optional
    );

B<Parameters>

=over 4

=item - C<application_id>

I<Required>E<10> E<8>

A valid Algolia application ID for your account.

=item - C<api_key>

I<Required>E<10> E<8>

A valid Algolia api key for your account.

=item - C<timeout>

I<Optional>E<10> E<8>

The number of seconds to wait per request until timing out.  Defaults to C<10>.

=item - C<retries>

I<Optional>E<10> E<8>

The number of times to retry requests in cases when Lob returns a 5xx response.  Defaults to C<0>.

=back

=head2 get_indexes

Returns a list of all existing indexes.

B<Request:>

    get_indexes();

B<Response:>

    [{
        createdAt      => "2014-12-03T23:20:19.745Z",
        dataSize       => 42,
        entries        => 1,
        lastBuildTimeS => 0,
        name           => "foo",
        pendingTask    => bless(do{\(my $o = 0)}, "JSON::PP::Boolean"),
        updatedAt      => "2014-12-04T00:41:14.120Z",
    },
    {
        createdAt      => "2014-12-03T23:20:18.323Z",
        dataSize       => 36,
        entries        => 1,
        lastBuildTimeS => 0,
        name           => "bar",
        pendingTask    => bless(do{\(my $o = 0)}, "JSON::PP::Boolean"),
        updatedAt      => "2014-12-04T00:42:13.231Z",
    }]

=head2 browse_index

Returns all content from an index.

B<Request:>

    browse_index('foo');

B<Response:>

    {
        hits             => [{ bar => { baz => "bat" }, objectID => 5333220 }],
        hitsPerPage      => 1000,
        nbHits           => 1,
        nbPages          => 1,
        page             => 0,
        params           => "hitsPerPage=1000&attributesToHighlight=&attributesToSnippet=&attributesToRetrieve=*",
        processingTimeMS => 1,
        query            => "",
    }

=head2 query_index

Returns objects that match the query.

B<Request:>

    query_index({ index => 'foo', query => 'bat' });

B<Response:>

    {
        hits => [
            {   _highlightResult => {
                    bar => {
                        baz => {
                            matchedWords => [ "bat" ],
                            matchLevel   => "full",
                            value        => "<em>bat</em>"
                        },
                    },
                },
                bar      => { baz => "bat" },
                objectID => 5333370,
            },
        ],
        hitsPerPage      => 20,
        nbHits           => 1,
        nbPages          => 1,
        page             => 0,
        params           => "query=bat",
        processingTimeMS => 1,
        query            => "bat",
    }

=head2 query_indexes

Query multiple indexes with one API call.

B<Request:>

    query_indexes([
        { index => 'foo', query => 'baz' },
        { index => 'foo', query => 'bat' },
    ]);

B<Response:>

    {
        results => [
            {   hits             => [],
                hitsPerPage      => 20,
                index            => "foo",
                nbHits           => 0,
                nbPages          => 0,
                page             => 0,
                params           => "query=baz",
                processingTimeMS => 1,
                query            => "baz",
            },
            {   hits => [
                    {   _highlightResult => {
                            bar => {
                                baz => {
                                    matchedWords => [ "bat" ],
                                    matchLevel   => "full",
                                    value        => "<em>bat</em>"
                                },
                            },
                        },
                        bar      => { baz => "bat" },
                        objectID => 5333380,
                    },
                ],
                hitsPerPage      => 20,
                index            => "foo",
                nbHits           => 1,
                nbPages          => 1,
                page             => 0,
                params           => "query=bat",
                processingTimeMS => 1,
                query            => "bat",
            },
        ],
    }

=head2 clear_index

Deletes the index content. Settings and index specific API keys are kept untouched.

B<Request:>

    clear_index('foo');

B<Response:>

    {
        taskID    => 26036480,
        updatedAt => "2014-12-04T00:53:40.957Z",
    }

=head2 copy_index

Copies an existing index. If the destination index already exists, its specific API keys will be preserved and the source index specific API keys will be added.

B<Request:>

    copy_index('foo' => 'foo2');

B<Response:>

    {
        taskID    => 26071750,
        updatedAt => "2014-12-04T01:16:20.307Z",
    }

=head2 move_index

Moves an existing index. If the destination index already exists, its specific API keys will be preserved and the source index specific API keys will be added.

B<Request:>

    move_index('foo' => 'foo2');

B<Response:>

    {
        taskID    => 26079100,
        updatedAt => "2014-12-04T01:21:01.815Z",
    }

=head2 delete_index

Deletes an existing index.

B<Request:>

    delete_index('foo');

B<Response:>

    {
        taskID    => 26040530,
        deletedAt => "2014-12-04T00:56:00.773Z",
    }

=head2 get_index_settings

Retrieves index settings.

B<Request:>

    get_index_settings('foo');

B<Response:>

    {
        'attributeForDistinct'  => undef,
        'attributesForFaceting' => undef,
        'attributesToHighlight' => undef,
        'attributesToIndex'     => [ 'bat' ],
        'attributesToRetrieve'  => undef,
        'attributesToSnippet'   => undef,
        'customRanking'         => undef,
        'highlightPostTag'      => '</em>',
        'highlightPreTag'       => '<em>',
        'hitsPerPage'           => 20,
        'minWordSizefor1Typo'   => 4,
        'minWordSizefor2Typos'  => 8,
        'optionalWords'         => undef,
        'queryType'             => 'prefixLast',
        'ranking'               => [
            'typo',
            'geo',
            'words',
            'proximity',
            'attribute',
            'exact',
            'custom'
        ],
        'removeWordsIfNoResults'  => 'none',
        'separatorsToIndex'       => '',
        'unretrievableAttributes' => undef
    }

=head2 update_index_settings

Updates part of an index's settings.

B<Request:>

    update_index_settings('foo', { attributesToIndex => ['bat'] });

B<Response:>

    {
        taskID    => 27224430,
        updatedAt => "2014-12-04T19:52:29.54Z",
    }

=head2 create_index_object

Creates a new object in the index, and automatically assigns an Object ID.

B<Request:>

    create_index_object('foo', { bar => { baz => 'bat' }});

B<Response:>

    {
        objectID  => 5333250,
        taskID    => 26026500,
        createdAt => "2014-12-04T00:47:21.781Z",
    }

=head2 get_index_object

Returns one object from the index.

B<Request:>

    get_index_object('foo', 5333250);

B<Response:>

    {
        objectID  => 5333250,
        delicious => 'limoncello',
    }

=head2 get_index_objects

Retrieve several objects with one API call.

B<Request:>

    get_index_objects([
        { index => 'foo', object => 5333250 },
        { index => 'foo', object => 5333251 },
    ]);

B<Response:>

    {
        results => [{
            objectID  => 5333250,
            delicious => 'limoncello',
        },
        {
            objectID  => 5333251,
            terrible => 'cabbage',
        }],
    }

=head2 replace_index_object

Creates or replaces an object (if the object does not exist, it will be created). When an object already exists for the specified object ID, the whole object is replaced: existing attributes that are not replaced are deleted.

B<Request:>

    replace_index_object('foo', 5333250, { delicious => 'limoncello' });

B<Response:>

    {
        objectID  => 5333250,
        taskID    => 26034540,
        updatedAt => "2014-12-04T00:52:32.416Z",
    }

=head2 update_index_object

Updates part of an object (if the object does not exist, it will be created. You can avoid an automatic creation of the object by passing C<createIfNotExists=false> as a query argument).

B<Request:>

    update_index_object('foo', 5333251, { another => 'pilsner?' });

B<Response:>

    {
        objectID  => 5333251,
        taskID    => 29453760,
        updatedAt => "2014-12-06T02:49:40.859Z",
    }

=head2 delete_index_object

Deletes an existing object from the index.

B<Request:>

    delete_index_object('foo', 5333251);

B<Response:>

    {
        objectID  => 5333251,
        taskID    => 29453761,
        deletedAt => "2014-12-11T02:49:40.859Z",
    }

=head2 batch_index_objects

To reduce the amount of time spent on network round trips, you can create, update, or delete several objects in one call, using the batch endpoint (all operations are done in the given order).

The following methods can be passed into the C<batch_index_objects> method as anonymous subroutines: C<create_index_object>, C<update_index_object>, C<replace_index_object>, and C<delete_index_object>.

B<Request:>

    alg->batch_index_objects('foo', [
        sub { alg->create_index_object('foo', { hello => 'world' })},
        sub { alg->create_index_object('foo', { goodbye => 'world' })},
    ]);

B<Response:>

    {
        objectIDs => [5698830, 5698840],
        taskID => 40684520,
    }

B<Request:>

    alg->batch_index_objects('foo', [
        sub { alg->update_index_object('foo', 5698830, { 1 => 2 })},
        sub { alg->update_index_object('foo', 5698840, { 3 => 4 })},
    ]);

B<Response:>

    {
        objectIDs => [5698830, 5698840],
        taskID => 40684521,
    }

B<Request:>

    alg->batch_index_objects('foo', [
        sub { alg->delete_index_object('foo', 5698830 )},
        sub { alg->delete_index_object('foo', 5698840 )},
    ]);

B<Response:>

    {
        objectIDs => [5698830, 5698840],
        taskID => 40684522,
    }

=head2 get_index_keys

If an indexName is passed, retrieves API keys that have access to this index with their rights.  Otherwise, retrieves all API keys that have access to one index with their rights.

B<Request:>

    get_index_keys();

B<Response:>

    {
        keys => [
            {
                acl      => [],
                index    => "pirouette",
                validity => 0,
                value    => "181b9114149666398628faa37b31cc8d",
            },
            {
                acl      => ['browse'],
                index    => "gelato",
                validity => 0,
                value    => "1428a48214792ac9f6324a823991aa4c",
            },
        ],
    }

B<Request:>

    get_index_keys('pirouette');

B<Response:>

    {
        keys => [
            {
                acl      => [],
                validity => 0,
                value    => "181b9114149666398628faa37b31cc8d",
            }
        ],
    }

=head2 get_index_key

Returns the rights of a given index specific API key that has been created with the add index specific key API.

B<Request:>

    get_index_key('pirouette', '181b9114149666398628faa37b31cc8d');

B<Response:>

    {
        acl      => [],
        validity => 0,
        value    => "181b9114149666398628faa37b31cc8d",
    }

=head2 create_index_key

Adds a new key that can access this index.

B<Request:>

    create_index_key('pirouette', { acl => ['search']});

B<Response:>

    {
        createdAt => "2014-12-08T15:54:22.464Z",
        key       => "181b9114149666398628faa37b31cc8d",
    }

=head2 update_index_key

Updates a key that can access this index.

B<Request:>

    update_index_key('pirouette', '181b9114149666398628faa37b31cc8d', { acl => ['search', 'browse']});

B<Response:>

    {
        updatedAt => "2014-12-08T16:39:11.9Z",
        key       => "181b9114149666398628faa37b31cc8d",
    }

=head2 delete_index_key

Deletes an index specific API key that has been created with the add index specific key API.

B<Request:>

    delete_index_key('pirouette', '181b9114149666398628faa37b31cc8d');

B<Response:>

    {
        deletedAt => "2014-12-08T16:40:49.86Z",
    }

=head2 get_task_status

Retrieves the status of a given task (published or notPublished). Also returns a C<pendingTask> flag that indicates if the index has remaining task(s) running.

B<Request:>

    get_task_status('foo', 29734242);

B<Response:>

    {
        pendingTask => bless(do{\(my $o = 0)}, "JSON::PP::Boolean"),
        status => "published",
    }

=head2 get_keys

Retrieves global API keys with their rights. These keys have been created with the add global key API.

B<Request:>

    get_keys();

B<Response:>

    {
        keys => [
            {
                acl      => [],
                validity => 0,
                value    => "28b555c212728a7f462fe96c0e677539",
            },
            {
                acl      => [],
                validity => 0,
                value    => "6ef88c72a6a4fc7e660f8819f111697c",
            }
        ],
    }

=head2 get_key

Returns the rights of a given global API key that has been created with the add global Key API.

B<Request:>

    get_key('28b555c212728a7f462fe96c0e677539');

B<Response:>

    {
        acl      => [],
        validity => 0,
        value    => "28b555c212728a7f462fe96c0e677539",
    }

=head2 update_key

Updates a global API key.

B<Request:>

    update_key('28b555c212728a7f462fe96c0e677539', { acl => ['search', 'browse']});

B<Response:>

    {
        updatedAt => "2014-12-08T16:39:11.9Z",
        key       => "28b555c212728a7f462fe96c0e677539",
    }

=head2 delete_key

Deletes a global API key that has been created with the add global Key API.

B<Request:>

    delete_key('28b555c212728a7f462fe96c0e677539');

B<Response:>

    {
        deletedAt => "2014-12-08T16:40:49.86Z",
    }

=head2 get_logs

Return last logs.

B<Request:>

    get_logs();

B<Response:>

    {
        logs => [
            {
                answer             => "\n{\n  \"keys\": [\n  ]\n}\n",
                answer_code        => 200,
                ip                 => "199.91.170.132",
                method             => "GET",
                nb_api_calls       => 1,
                processing_time_ms => 1,
                query_body         => "",
                query_headers      => "TE: deflate,gzip;q=0.3\nConnection: TE, close\nHost: 9KV4OFXW8Z.algolia.io\nUser-Agent: libwww-perl/6.08\nContent-Type: application/json\nX-Algolia-API-Key: 28d*****************************\nX-Algolia-Application-Id: 9KV4OFXW8Z\n",
                sha1 => "b82f8d002ccae799f6629300497725faa670cc7b",
                timestamp => "2014-12-09T05:08:05Z",
                url => "/1/keys",
            },
            {
                answer             => "\n{\n  \"value\": \"3bfccc91bb844f5ba0fc816449a9d340\",\n  \"acl\": [\n    \"search\"\n  ],\n \"validity\": 0\n}\n",
                answer_code        => 200,
                ip                 => "199.91.170.132",
                method             => "GET",
                nb_api_calls       => 1,
                processing_time_ms => 1,
                query_body         => "",
                query_headers      => "TE: deflate,gzip;q=0.3\nConnection: TE, close\nHost: 9KV4OFXW8Z.algolia.io\nUser-Agent: libwww-perl/6.08\nContent-Type: application/json\nX-Algolia-API-Key: 28d*****************************\nX-Algolia-Application-Id: 9KV4OFXW8Z\n",
                sha1 => "4915e88a309ea42f8f0ee46c9358b57b9a37a3d9",
                timestamp => "2014-12-09T05:08:04Z",
                url => "/1/keys/3bfccc91bb844f5ba0fc816449a9d340",
            },
        ],
    }

B<Request:>

    get_logs({
        offset => 4,
        length => 2,
    });

B<Response:>

    {
        logs => [
            {
                answer             => "\n{\n  \"message\": \"Key does not exist\"\n}\n",
                answer_code        => 404,
                index              => "pirouette",
                ip                 => "50.243.54.51",
                method             => "GET",
                nb_api_calls       => 1,
                processing_time_ms => 1,
                query_body         => "",
                query_headers      => "TE: deflate,gzip;q=0.3\nConnection: TE, close\nHost: 9KV4OFXW8Z.algolia.io\nUser-Agent: libwww-perl/6.07\nContent-Type: application/json\nX-Algolia-API-Key: 28d*****************************\nX-Algolia-Application-Id: 9KV4OFXW8Z\n",
                sha1               => "e2d3de10f69d8efb16caadaa22c6312ac408ed48",
                timestamp          => "2014-12-08T16:06:32Z",
                url                => "/1/indexes/pirouette/keys/25c005baabd13ab5c3ac14a79c9d5c27",
            },
            {
                answer             => "\n{\n  \"message\": \"Key does not exist\"\n}\n",
                answer_code        => 404,
                index              => "pirouette",
                ip                 => "50.243.54.51",
                method             => "GET",
                nb_api_calls       => 1,
                processing_time_ms => 1,
                query_body         => "",
                query_headers      => "TE: deflate,gzip;q=0.3\nConnection: TE, close\nHost: 9KV4OFXW8Z.algolia.io\nUser-Agent: libwww-perl/6.07\nContent-Type: application/json\nX-Algolia-API-Key: 28d*****************************\nX-Algolia-Application-Id: 9KV4OFXW8Z\n",
                sha1               => "d0799be3ccf05d2d5a0c902f6e80917468d5e6ff",
                timestamp          => "2014-12-08T16:06:07Z",
                url                => "/1/indexes/pirouette/keys/b7fbe3bcc26322af222edf2a9ca934ee",
            },
        ],
    }

=head2 get_popular_searches

Return popular queries for a set of indices.

B<Request:>

    get_popular_searches(['foo']);

B<Response:>

    {
        lastSearchAt => "2014-12-09T05:00:00.000Z",
        searchCount  => 48,
        topSearches  => [
            {
                avgHitCount             => 0,
                avgHitCountWithoutTypos => 0,
                count                   => 32,
                query                   => "bat"
            },
        ],
    }

=head2 get_unpopular_searches

Return queries matching 0 records for a set of indices.

B<Request:>

    get_unpopular_searches(['foo']);

B<Response:>

    {
        lastSearchAt        => "2014-12-09T05:00:00.000Z",
        searchCount         => 48,
        topSearchesNoResuls => [ { count => 16, query => "baz" } ],
    }

=head1 SEE ALSO

L<https://www.algolia.com/doc> - the API documentation for L<https://www.algolia.com>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/WebService-Algolia/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
