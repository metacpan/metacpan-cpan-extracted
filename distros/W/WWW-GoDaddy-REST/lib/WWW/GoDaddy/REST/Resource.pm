package WWW::GoDaddy::REST::Resource;

use Carp;
use List::MoreUtils qw( natatime );
use Moose;
use URI;
use URI::QueryParam;
use WWW::GoDaddy::REST::Util qw( abs_url json_instance json_encode json_decode is_json );

use constant DEFAULT_IMPL_CLASS => 'WWW::GoDaddy::REST::Resource';
use overload '""'               => \&to_string;

has 'client' => (
    is       => 'rw',
    isa      => 'WWW::GoDaddy::REST',
    required => 1
);

has 'fields' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'http_response' => (
    is       => 'ro',
    isa      => 'Maybe[HTTP::Response]',
    required => 0
);

sub save {
    my $self      = shift;
    my $http_opts = shift;
    my $url = $self->link('self') || $self->client->schema( $self->type )->query_url( $self->id );
    return $self->client->http_request_as_resource( 'PUT', $url, $self, $http_opts );
}

sub delete {
    my $self      = shift;
    my $http_opts = shift;
    my $url = $self->link('self') || $self->client->schema( $self->type )->query_url( $self->id );
    return $self->client->http_request_as_resource( 'DELETE', $url, $self, $http_opts );
}

sub follow_link {
    my $self      = shift;
    my $link_name = shift;
    my $http_opts = shift;

    my $link_url = $self->link($link_name);
    if ( !$link_url ) {
        my @valid_links = keys %{ $self->links() };
        croak("$link_name is not a valid link name. Did you mean one of these? @valid_links");
    }

    return $self->client->http_request_as_resource( 'GET', $link_url, undef, $http_opts );
}

sub do_action {
    my $self      = shift;
    my $action    = shift;
    my $params    = shift;
    my $http_opts = shift;

    my $action_url = $self->action($action);
    if ( !$action_url ) {
        if ( $self->id ) {

            # try and find an action in the schema as fallback
            my $schema = $self->schema();
            my $resource_actions = $schema->f('resourceActions') || {};
            if ( exists $resource_actions->{$action} ) {
                my $self_uri = URI->new( $self->link('self') || $schema->query_url( $self->id ) );
                $self_uri->query("$action");
                $action_url = "$self_uri";
            }
        }
        if ( !$action_url ) {
            croak("$action is not a valid action name.");
        }
    }

    return $self->client->http_request_as_resource( 'POST', $action_url, $params, $http_opts );

}

sub items {
    my $self = shift;
    return ($self);
}

sub id {
    return shift->f('id');
}

sub type {
    return shift->f('type');
}

sub resource_type {
    return shift->f('resourceType');
}

sub type_fq {
    my $self = shift;

    my $base_url = $self->schemas_url;

    return abs_url( $base_url, $self->type );
}

sub resource_type_fq {
    my $self = shift;

    return unless $self->resource_type;

    return abs_url( $self->schemas_url, $self->resource_type );
}

sub schema {
    my $self = shift;
    my $schema
        = $self->client->schema( $self->resource_type_fq )
        || $self->client->schema( $self->type_fq )
        || $self->client->schema( $self->type );
    return $schema;
}

sub link {
    my $self = shift;
    my $name = shift;

    my $links = $self->links();
    if ( exists $links->{$name} ) {
        return $links->{$name};
    }
    return undef;
}

sub links {
    return shift->f('links');
}

sub action {
    my $self = shift;
    my $name = shift;

    my $actions = $self->actions();
    if ( exists $actions->{$name} ) {
        return $actions->{$name};
    }
    return undef;
}

sub actions {
    return shift->f('actions') || {};
}

sub f {
    return shift->field(@_);
}

sub f_as_resources {
    my $self     = shift;
    my $field    = shift;
    my $raw_data = $self->f($field);

    my ( $container, $type );

    # if the 'field' is data, skip detection and use the resource type
    if ( $field eq 'data' ) {
        ( $container, $type ) = ( 'array', $self->resource_type );
    }
    else {
        ( $container, $type ) = $self->schema->resource_field_type($field);
    }
    my %defaults = (
        client        => $self->client,
        http_response => $self->http_response
    );

    my $type_schema = $self->client->schema($type);
    if ($type_schema) {
        if ( $container && $container eq 'map' ) {
            my %ret;
            foreach ( my ( $k, $v ) = each %{$raw_data} ) {
                $v->{type} ||= $type_schema->id;
                $ret{$k} = $self->new_subclassed( { %defaults, fields => $v } );
            }
            return \%ret;
        }
        elsif ( $container && $container eq 'array' ) {
            my @ret;
            foreach my $v ( @{$raw_data} ) {
                $v->{type} ||= $type_schema->id;
                push @ret, $self->new_subclassed( { %defaults, fields => $v } );
            }
            return \@ret;
        }
        elsif ( ref($raw_data) eq 'HASH' ) {
            my %ret = %{$raw_data};
            $ret{type} ||= $type_schema->id;
            return $self->new_subclassed( { %defaults, fields => \%ret } );
        }
    }

    # just return the raw data if not returned otherwise
    return $raw_data;

}

sub field {
    my $self = shift;
    if ( @_ <= 1 ) {
        return $self->_get_field(@_);
    }
    else {
        return $self->_set_field(@_);
    }
}

sub schemas_url {
    my $self = shift;

    my $found;

    my $http_resp = $self->http_response;
    my $link      = $self->link('schemas');

    if ( $http_resp && $http_resp->header('X-API-Schemas') ) {
        return $http_resp->header('X-API-Schemas');
    }

    return $self->client->schemas_url;
}

sub _get_field {
    my $self = shift;
    my $name = shift;

    if ( !exists $self->fields->{$name} ) {
        return undef;
    }
    return $self->fields->{$name};

}

sub _set_field {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    $self->fields->{$name} = $value;
    return $self->fields->{$name};
}

sub new_subclassed {
    my $class  = shift;
    my $params = shift;

    my $data = $params->{fields};

    my $impl = DEFAULT_IMPL_CLASS;
    if ( ref($data) eq "HASH" ) {
        my $type_short = $params->{fields}->{type} || '';
        my $type_long = $type_short ? $params->{client}->schemas_url($type_short) : '';

        $impl = $class->find_implementation( ( $type_long, $type_short ) ) || DEFAULT_IMPL_CLASS;
        eval "require $impl;";
    }
    else {

        # hmm, the json response didn't seem to be a hashref...
        # well in this case, there are not really any fields
        # so the caller will have to check the http_response
        # content
        $params->{fields} = {};
    }

    return $impl->new($params);

}

sub TO_JSON {
    my $self = shift;
    return $self->data;
}

sub data {
    my $self = shift;

    my %fields = %{ $self->fields || {} };
    if (%fields) {
        return \%fields;
    }
    elsif ( $self->http_response ) {
        my $content = $self->http_response->decoded_content;
        return is_json($content) ? json_decode($content) : $content;
    }
    return {};
}

sub to_string {
    my $self   = shift;
    my $pretty = shift;

    my $JSON = json_instance();
    if ($pretty) {
        $JSON->pretty(1);
    }
    return json_encode( $self, $JSON );
}

my %SCHEMA_TO_IMPL = (
    'collection' => 'WWW::GoDaddy::REST::Collection',
    'schema'     => 'WWW::GoDaddy::REST::Schema',
);

sub find_implementation {
    my $class    = shift;
    my @look_for = @_;

    foreach (@look_for) {
        if ( exists $SCHEMA_TO_IMPL{$_} ) {
            return $SCHEMA_TO_IMPL{$_};
        }
    }
    return;
}

sub register_implementation {
    my $class = shift;

    if ( @_ % 2 != 0 ) {
        croak("Expecting even number of parameters");
    }

    my $iterator = natatime 2, @_;
    while ( my ( $schema, $subclass ) = $iterator->() ) {
        $SCHEMA_TO_IMPL{$schema} = $subclass;
    }
    return;
}

1;

=head1 NAME

WWW::GoDaddy::REST::Resource - Represent a REST resource

=head1 SYNOPSIS

  $client = WWW::GoDaddy::REST->new(...);

  $resource = WWW::GoDaddy::REST::Resource->new({
    client => $client,
    fields => {
        'type'  => 'automobile',
        'id'    => '1001',
        'make'  => 'Tesla',
        'model' => 'S'
        'links' => {
            'self'    => 'https://example.com/v1/automobiles/1001',
            'schemas' => 'https://example.com/v1/schemas'
        },
        'actions' => {
            'charge' => 'https://example.com/v1/automobiles/1001?charge'
        }
        # ...
        # see: https://github.com/godaddy/gdapi/blob/master/specification.md
    },
  });

  $resource->f('id'); # get 1001
  $resource->f('id','2000'); # set to 2000 and return 2000

  # follow a link in links section
  $schemas_resource = $resource->follow_link('schemas');

  # perform an action in the actions section
  $result_resource  = $resource->do_action('charge',{ 'with' => 'quick_charger' });

=head1 DESCRIPTION

Base class used to represent a REST resource.

=head1 CLASS METHODS

=over 4

=item new

Given a hash reference of L<"ATTRIBUTES"> and values, return a new instance
of this object.

It is likely more important that you use the C<new_subclassed> class method.

Example:

  my $resource = WWW::GoDaddy::REST::Resource->new({
    client => WWW::GoDaddy::REST->new(...),
    fields => {
        id => '...',
        ...
    },
  });

=item new_subclassed

This takes the same paramegers as C<new> and is the preferred construction
method.  This tries to find the appropriate subclass of
C<WWW::GoDaddy::REST::Resource> and passes along the paramegers to the C<new>
method of that subclass instead.

See also: C<new>

=item find_implementation

Given a list of schema type names, find the best implementation sub class.

Returns the string of the class name. If no good subclass candidate is found,
returns undef.

Example:

  find_implementation( 'schema' );
  # WWW::GoDaddy::REST::Schema

=item register_implementation

Register a subclass handler for a schema type given a schema name and the
name of a L<WWW::GoDaddy::REST::Resource> subclass.

This can take as many schema => resource class pairs as you want.

Example:

  WWW::GoDaddy::REST::Resource->register_subclass( 'account' => 'My::AccountRes' );
  WWW::GoDaddy::REST::Resource->register_subclass( 'foo' => 'Bar', 'baz' => 'Buzz' );

=back

=head1 ATTRIBUTES

=over 4

=item client

Instance of L<WWW::GoDaddy::REST> associated with the resource.

=item fields

Hash reference containing the raw data for the underlying resource.

Several methods delegate to this underlying structure such as C<f>, 
and C<field>.

=item http_response

Optionally present instance of an L<HTTP::Response> object so that
you can inspect the HTTP information related to the resource.

=back

=head1 METHODS

=over 4

=item f

Get or set a field by name. You may also use the longer name C<field>.

When performing a set, it also returns the new value that was set.

Example:

  $res->f('field_name');       # get
  $res->f('field_name','new'); # set

=item f_as_resources

Get a field by name.  If it is a resource, this will turn it into an
object instead of giving you the raw hash reference as the return value.

Note, if the field is a 'map' or 'array' of resources, every item in
those lists will be 'resourcified'.

If this is not a resource, then it does return the raw value.

Example:

  # return value is a WWW::GoDaddy::REST::Resource, not a hash ref
  $driver = $car->f('driver');

See C<f> if you want the raw value.  This will return the raw value, if
the value does not look like a resource.

=item field

Get or set a field by name.  You may also use the shorter name C<f>.

When performing a set, it also returns the new value that was set.

Example:

  $res->field('field_name');       # get
  $res->fieldf('field_name','new'); # set

=item save

Does a PUT at this resources URI.  Returns a new resource object.

Example:

  $r2 = $r1->save();

=item delete

Does a DELETE on this resource.  Returns a new resource object.  This
return value likely is only useful to get at the C<http_response> attribute.

=item do_action

Does a POST with the supplied data on the action URL with the given name.

If the action with the provided name does not exist, this method will
die.  See also: C<action> and C<actions>

Example:

  $r2 = $r1->do_action('some_action',{ a => 'a_v' });

=item follow_link

Gets the resource by following the link URL with the provided name.

If the link with the provided name does not exist, this method will
die.  See also: C<link> and C<link>

Example:

  $r2 = $r1->follow_link('some_link');

=item id

Return the id of this instance

=item type

Return the name of the schema type that this object belongs to.

=item type_fq

Return the full URI to the schema type that this object belongs to.

=item resource_type

Return the name of the schema type that this collection's objects belong to.

=item resource_type_fq

Return the full URI to the schema type that this collection's objects belong to.

=item schemas_url

Returns the URL for the schema collection.  This differs from the
client C<schemas_url> method since it has more places to look for hints
of the schemas collection url (headers, json response etc).

Example:

  $r->schemas_url();

=item schema

Find and return the L<WWW::GoDaddy::REST::Schema> object that this is.

=item link

Return the link URL for the given name or undef if it does not exist.

Example:

  # https://example.com/v1/thing/...
  $r->link('self');
  # 'https://example.com/v1/me/1'

=item links

Return the hashref that contains the link => url information

Example:

  $r->links();
  # {
  #     'self'      => 'https://example.com/v1/me/1',
  #     'some_link' => 'https://example.com/v1/me/1/some_link'
  # }

=item action

Return the action URL for the given name.

Example:

  $r->action('custom_action');
  # https://example.com/v1/thing/1001?some_action

=item actions

Return the hashref that contains the action => url information

Example:

  $r->actions();
  # {
  #     'custom_action' => 'https://example.com/v1/thing/1001?some_action'
  # }

=item items

Returns a list of resources that this resource contains.  This implementation
simply returns a list of 'self'.  It is here to be consistent with the 
implementation found in L<WWW::GoDaddy::REST::Collection>.

Example:

  @items = $resource->items();

=item TO_JSON

Returns a hashref that represents this object.  This exists to make using the
L<JSON> module more convenient.  This does NOT return a JSON STRING, just a 
perl data structure.

See C<to_string>.

=item to_string

Returns a JSON string that represents this object.  This takes an optional
parameter, "pretty".  If true, the json output will be prettified. This defaults
to false.

=item data

The resource is returned as a perl data structure.  Note, if there are no
C<fields>, then the http_respons is consulted, if json data is found in
the content, that is returned (for instance, a plane old string or integer).

=back

=head1 AUTHOR

David Bartle, C<< <davidb@mediatemple.net> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Go Daddy Operating Company, LLC

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.


=cut
