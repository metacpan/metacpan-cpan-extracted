package Disbatch::Web::Tasks;
$Disbatch::Web::Tasks::VERSION = '4.102';
use 5.12.0;
use warnings;

use Disbatch::Web;	# exports: parse_params send_json_options template
use Limper::SendJSON;
use Limper;
use MongoDB::OID 1.0.4;
use Safe::Isa;
use Time::Moment;
use Try::Tiny;

my $disbatch;

sub init {
    ($disbatch, my $args) = @_;
}

sub deserialize_oid {
    my ($object) = @_;
    if (ref $object eq 'HASH') {
        return MongoDB::OID->new(value => $object->{'$oid'}) if exists $object->{'$oid'};
        $object->{$_} = deserialize_oid($object->{$_}) for keys %$object;
    } elsif (ref $object eq 'ARRAY') {
        $_ = deserialize_oid($_) for @$object;
    }
    $object;
}

# NOTE: search() was "post '/tasks/search'" but for some reason it conflicts with the next route and i don't feel like fixing Limper rn
# see https://metacpan.org/pod/MongoDB::Collection#find
sub search {
    undef $disbatch->{mongo};
    my $params = parse_params;

    my $LIMIT = 100;

    $params->{filter} //= {};
    $params->{options} //= {};
    $params->{count} //= 0;
    $params->{terse} //= 1;
    $params->{pretty} //= 0;
    unless (ref $params->{filter} eq 'HASH' and ref $params->{options} eq 'HASH') {
        status 400;
        return send_json { error => 'filter and options must be name/value objects' }, send_json_options;
    }
    $params->{options}{limit} //= $LIMIT;
    if ($params->{options}{limit} > $LIMIT) {
        status 400;
        return send_json { error => "limit cannot exceed $LIMIT" }, send_json_options;
    }

    $params->{filter}{queue} = { '$oid' => $params->{filter}{queue} } if defined $params->{filter}{queue} and !ref $params->{filter}{queue};

    my $oid_error = try { $params->{filter} = deserialize_oid($params->{filter}); undef } catch { "Bad OID passed: $_" };
    if (defined $oid_error) {
        Limper::warning $oid_error;
        status 400;
        return send_json { error => $oid_error }, send_json_options;
    }

    # Turn value into a Time::Moment object if it looks like it includes milliseconds. Will break in the year 2286.
    for my $type (qw/ctime mtime/) {
        $params->{filter}{$type} = Time::Moment->from_epoch($params->{filter}{$type} / 1000) if ($params->{filter}{$type} // 0) > 9999999999;
    }

    if ($params->{count}) {
        my $count = try { $disbatch->tasks->count($params->{filter}) } catch { Limper::warning $_; $_; };
        if (ref $count) {
            status 400;
            return send_json { error => "$count" }, send_json_options;
        }
        return send_json { count => $count }, send_json_options;
    }
    my ($error, @tasks) = try { undef, $disbatch->tasks->find($params->{filter}, $params->{options})->all } catch { Limper::warning "Could not find tasks: $_"; $_ };
    if (defined $error) {
        Limper::warning $error;
        status 400;
        return send_json { error => $error }, send_json_options;
    }

    for my $task (@tasks) {
        for my $type (qw/stdout stderr/) {
            if ($params->{terse}) {
                $task->{$type} = '[terse mode]' if defined $task->{$type} and !$task->{$type}->$_isa('MongoDB::OID') and $task->{$type};
            } elsif ($task->{$type}->$_isa('MongoDB::OID')) {
                $task->{$type} = try { $disbatch->get_gfs($task->{$type}) } catch { Limper::warning "Could not get task $task->{_id} $type: $_"; $task->{$type} };
            }
        }
        for my $type (qw/ctime mtime/) {
            $task->{$type} = $task->{$type}->hires_epoch if ref $task->{$type} eq 'DateTime';
        }
    }

    send_json \@tasks, send_json_options, pretty => $params->{pretty};
};

post qr'^/tasks/(?<queue>[^/]+)$' => sub {
    if ($+{queue} eq 'search') {
        search();
    } else {
        Disbatch::Web::post_tasks({ queue => $+{queue} });
    }
};

post qr'^/tasks/(?<queue>.+?)/(?<collection>.+)$' => sub {
    Disbatch::Web::post_tasks({ queue => $+{queue}, collection => $+{collection} });
};

1;

=encoding utf8

=head1 NAME

Disbatch::Web::Tasks - Disbatch::Web routes for deprecated task search and creation.

=head1 VERSION

version 4.102

=head1 DEPRECATION NOTICE

This is deprecated as of Disbatch 4.2 and may be removed in Disbatch 4.4.

=head1 NOTE

These routes were formerly in L<Disbatch::Web>, but moved here. They are not loaded by default.

=head1 SUBROUTINES

=over 2

=item init($disbatch, $args)

Parameters: a C<Disbatch::Web> object (C<$args> is ignored).

Sets package global C<$disbatch>.

Returns nothing.

=item deserialize_oid($object)

Parameters: decoded JSON filter for the search (or a sub-value from it)

If the object has the field C<$oid>, it is turned into a C<MongoDB::OID> object.

Returns the modified object.

=item search()

Parameters: none (but parses request parameters, see C<POST /tasks/search> below)

Performs task search.

Returns result as JSON, setting HTTP status to C<400> on error.

=back

=head1 JSON ROUTES

=over 2

=item POST /tasks/search

Parameters: C<< { "filter": filter, "options": options, "count": count, "terse": terse } >>

All parameters are optional.

C<filter> is a filter expression (query) object.

C<options> is an object of desired options to L<MongoDB::Collection#find>.

If not set, C<options.limit> will be C<100>. This will fail if you try to set it above C<100>.

C<count> is a boolean. Instead of an array of task documents, the count of task documents matching the query will be returned.

C<terse> is a boolean. If C<true>, the the GridFS id or C<"[terse mode]"> will be returned for C<stdout> and C<stderr> of each document.
If C<false>, the full content of C<stdout> and C<stderr> will be returned. Default is C<true>.

Returns: Array of task Objects or C<< { "count": $count } >> on success; C<< { "error": "filter and options must be name/value objects" } >>,
C<< { "error": "limit cannot exceed 100" } >>, or C<< { "error": "Bad OID passed: $error" } >> on input error;
or C<< { "error": "$error" } >> on count or search error.

Sets HTTP status to C<400> on error.

Note: replaces /search-tasks-json

=item POST /tasks/:queue

URL: C<:queue> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<name> if it does not.

Parameters: an array of task params objects

Returns: C<< { ref $res: Object } >> on success; C<< { "error": "params must be a JSON array of task params" } >>
or C<< { "error": "queue not found" } >> on input error;  or C<< { ref $res: Object, "error": "Unknown error" } >> on MongoDB error.

Sets HTTP status to C<400> on error.

Note: replaces /queue-create-tasks-json

=item POST /tasks/:queue/:collection

URL: C<:queue> is the C<_id> if it matches C</\A[0-9a-f]{24}\z/>, or C<name> if it does not. C<:collection> is a MongoDB collection name.

Parameters: C<< { "filter": filter, "params": params } >>

C<filter> is a filter expression (query) object for the C<:collection> collection.

C<params> is an object of task params. To insert a document value from a query into the params, prefix the desired key name with C<document.> as a value.

Returns: C<< { ref $res: Object } >> on success; C<< { "error": "filter and params required and must be name/value objects" } >>
or C<< { "error": "queue not found" } >> on input error; C<< { "error": "Could not iterate on collection $collection: $error" } >> on query error,
or C<< { ref $res: Object, "error": "Unknown error" } >> on MongoDB error.

Sets HTTP status to C<400> on error.

Note: replaces /queue-create-tasks-from-query-json

=back

=head1 SEE ALSO

L<Disbatch::Web>

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016, 2019 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
