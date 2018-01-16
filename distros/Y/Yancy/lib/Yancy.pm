package Yancy;
our $VERSION = '0.011';
# ABSTRACT: A simple CMS for administrating data

#pod =head1 SYNOPSIS
#pod
#pod     ### Standalone app
#pod     $ yancy daemon
#pod
#pod     ### Mojolicious plugin
#pod     use Mojolicious::Lite;
#pod     plugin Yancy => { ... };
#pod
#pod =head1 DESCRIPTION
#pod
#pod =begin html
#pod
#pod <p>
#pod   <img alt="Screenshot"
#pod     src="https://raw.github.com/preaction/Yancy/master/eg/screenshot.png?raw=true"
#pod     width="600px">
#pod </p>
#pod
#pod =end html
#pod
#pod L<Yancy> is a simple content management system (CMS) for administering
#pod content in a database. Yancy accepts a configuration file that describes
#pod the data in the database and builds a website that lists all of the
#pod available data and allows a user to edit data, delete data, and add new
#pod data.
#pod
#pod Yancy uses L<JSON Schema|http://json-schema.org> to define the data in
#pod the database. The schema is added to an L<OpenAPI
#pod specification|http://openapis.org> which creates a L<REST
#pod API|https://en.wikipedia.org/wiki/Representational_state_transfer> for
#pod your data.
#pod
#pod Yancy can be run in a standalone mode (which can be placed behind
#pod a proxy), or can be embedded as a plugin into any application that uses
#pod the L<Mojolicious> web framework.
#pod
#pod Yancy can manage data in multiple databases using different backends
#pod (L<Yancy::Backend> modules). Backends exist for L<Postgres via
#pod Mojo::Pg|Yancy::Backend::Pg>, L<MySQL via
#pod Mojo::mysql|Yancy::Backend::Mysql>, L<SQLite via
#pod Mojo::SQLite|Yancy::Backend::Sqlite>, and L<DBIx::Class, a Perl
#pod ORM|Yancy::Backend::DBIC>
#pod
#pod =head2 Standalone App
#pod
#pod To run Yancy as a standalone application, you must create a C<yancy.conf>
#pod configuration file that defines how to connect to your database and what
#pod the data inside looks like. See L</CONFIGURATION> for details.
#pod
#pod B<NOTE:> Yancy does not have authentication or authorization built-in.
#pod If you want to control which users have access to data, you should use
#pod an HTTP proxy with these features.
#pod
#pod Once the application is started, you can navigate to C<<
#pod http://127.0.0.1:3000/yancy >> to see the Yancy administration app.
#pod Navigate to C<< http://127.0.0.1:3000/ >> to see the getting started
#pod page.
#pod
#pod =head3 Rendering Content
#pod
#pod In the standalone app, all paths besides the C</yancy> application are
#pod treated as paths to templates. If a specific template path is not found,
#pod Yancy will search for an C<index> template in the same directory. If that
#pod template is not found, an error is returned.
#pod
#pod The templates are found in the C<templates> directory. You can change
#pod the root directory that contains the C<templates> directory by setting
#pod the C<MOJO_HOME> environment variable.
#pod
#pod Template names must end with C<< .format.ep >> where C<format> is the
#pod content type (C<html> is the default). You can render plain text (C<txt>),
#pod JSON (C<json>), XML (C<xml>), and others.
#pod
#pod Database content can be read by using the database helpers that Yancy
#pod provides.
#pod
#pod =over
#pod
#pod =item * C<< yancy->list( $collection ) >> - Get a list of items
#pod
#pod =item * C<< yancy->get( $collection, $id ) >> - Get a single item
#pod
#pod =item * C<< yancy->set( $collection, $id, $data ) >> - Update an item
#pod
#pod =item * C<< yancy->delete( $collection, $id ) >> - Delete an item
#pod
#pod =item * C<< yancy->create( $collection, $data ) >> - Create an item
#pod
#pod =back
#pod
#pod Some example template code:
#pod
#pod     %# Get a list of people
#pod     % my @people = app->yancy->list( 'people' );
#pod
#pod     %# Show a list of people names 
#pod     <ul>
#pod         % for my $person ( @people ) {
#pod             <li><%= $person->{name} %></li>
#pod         % }
#pod     </ul>
#pod
#pod     %# Get a single person with ID 1
#pod     % my $person = app->yancy->get( 'people', 1 );
#pod
#pod     %# Write the person's name to the page
#pod     <p>Hi, my name is <%= $person->{name} %>.</p>
#pod
#pod More information about L<Mojolicious> helpers is available at
#pod L<Mojolicious::Guides::Rendering>.
#pod
#pod =head3 Plugins
#pod
#pod In standalone mode, you can configure plugins in the Yancy configuration
#pod file. Plugins can be standard L<Mojolicious::Plugins> (with a name
#pod starting with C<Mojolicious::Plugin>, or they can be specifically for
#pod Yancy (by extending L<Mojolicious::Plugin> and having a name starting
#pod with C<Yancy::Plugin>).
#pod
#pod Plugins are configured as an array of arrays under the `plugins` key.
#pod Each inner array should have the plugin's name and any arguments the
#pod plugin requires, like so:
#pod
#pod     {
#pod         plugins => [
#pod             [ 'PodRenderer' ],
#pod             [ CGI => [ "/cgi-bin/script" => "/path/to/cgi/script.pl" ] ],
#pod         ],
#pod     }
#pod
#pod =head2 Mojolicious Plugin
#pod
#pod For information on how to use Yancy as a Mojolicious plugin, see
#pod L<Mojolicious::Plugin::Yancy>.
#pod
#pod =head2 REST API
#pod
#pod This application creates a REST API using the standard
#pod L<OpenAPI|http://openapis.org> API specification. The API spec document
#pod is located at C</yancy/api>.
#pod
#pod =head1 CONFIGURATION
#pod
#pod The Yancy configuration file is a Perl data structure. The individual
#pod parts are described below. An example configuration file looks like:
#pod
#pod     {
#pod         backend => 'pg://user@example.com/mydb',
#pod         collections => {
#pod             people => {
#pod                 type => 'object',
#pod                 properties => {
#pod                     id => {
#pod                         type => 'integer',
#pod                         readOnly => 1,
#pod                     },
#pod                     name => { type => 'string' },
#pod                     email => { type => 'string' },
#pod                 },
#pod             },
#pod         },
#pod     }
#pod
#pod =head2 Database Backend
#pod
#pod The C<backend> URL defines what database to use and how to connect to
#pod it. Each backend has its own format of URL, and some examples are shown
#pod below. See your backend's documentation for more information.
#pod
#pod =over
#pod
#pod =item L<Postgres backend|Yancy::Backend::Pg>
#pod
#pod     backend => 'pg://user@example.com/mydb',
#pod
#pod =item L<MySQL backend|Yancy::Backend::Mysql>
#pod
#pod     backend => 'mysql://user@localhost/mydb',
#pod
#pod =item L<SQLite backend|Yancy::Backend::Sqlite>
#pod
#pod     backend => 'sqlite:filename.db',
#pod
#pod =item L<DBIx::Class backend|Yancy::Backend::Dbic>
#pod
#pod     backend => 'dbic://My::Schema/dbi:SQLite:file.db',
#pod
#pod =back
#pod
#pod =head2 Data Collections
#pod
#pod The C<collections> data structure defines what data is in the database.
#pod Each key in this structure refers to the name of a collection, and the
#pod value describe the fields for items inside the collection.
#pod
#pod Each backend may define a collection differently. For a relational
#pod database like Postgres or MySQL, a collection is a table, and the fields
#pod are columns. For an ORM like DBIx::Class, the collections are ResultSet
#pod objects. For a document store like MongoDB, the collections are
#pod collections. See your backend's documentation for more information.
#pod
#pod Collections are configured using L<JSON Schema|http://json-schema.org>.
#pod The JSON Schema defines what fields (properties) an item has, and what
#pod type of data those field have. The JSON Schema also can define
#pod constraints like required fields or validate strings with regular
#pod expressions. The schema can also contain metadata like a C<title>,
#pod C<description>, and even an C<example> value. For more information on
#pod what can be defined, see L<the docs on JSON Schema|http://json-schema.org>.
#pod
#pod For a collection named C<people> that has 3 fields (an integer C<id> and
#pod two strings, C<name> and C<email>), a minimal JSON schema will look like
#pod this:
#pod
#pod     collections => {
#pod         people => {
#pod             properties => {
#pod                 id => {
#pod                     type => 'integer',
#pod                     readOnly => 1,
#pod                 },
#pod                 name => {
#pod                     type => 'string',
#pod                 },
#pod                 email => {
#pod                     type => 'string',
#pod                 },
#pod             },
#pod         },
#pod     },
#pod
#pod =head3 Generated Forms
#pod
#pod Yancy generates input elements based on the C<type>, and C<format> of
#pod the object's properties.
#pod
#pod =over
#pod
#pod =item * C<< type => "boolean" >> - A Yes/No field
#pod
#pod =item * C<< type => "integer" >> - A number field (C<< <input type="number" > >>)
#pod
#pod =item * C<< type => "number" >> - A number field (C<< <input type="number" > >>)
#pod
#pod =item * C<< type => "string", format => "date" >> - A date field (C<< <input type="date"> >>)
#pod
#pod =item * C<< type => "string", format => "date-time" >> - A date/time field (C<< <input type="datetime-local"> >>)
#pod
#pod =item * C<< type => "string", format => "email" >> - A e-mail address (C<< <input type="email"> >>)
#pod
#pod =item * C<< type => "string", format => "url" >> - A URL input (C<< <input type="url"> >>)
#pod
#pod =item * C<< type => "string", format => "tel" >> - A telephone number (C<< <input type="tel"> >>)
#pod
#pod =back
#pod
#pod Fields with an C<enum> property will be translated to C<< <select> >>
#pod elements.
#pod
#pod Other schema attributes will be translated as necessary to the HTML
#pod input fields:
#pod
#pod =over
#pod
#pod =item * C<title> will be used to label the input field
#pod
#pod =item * C<readOnly>
#pod
#pod =item * C<pattern>
#pod
#pod =item * C<minimum>
#pod
#pod =item * C<maximum>
#pod
#pod =item * C<minLength>
#pod
#pod =item * C<maxLength>
#pod
#pod =back
#pod
#pod A Markdown editor can be enabled by using C<< type => "string", format
#pod => "markdown" >>.  The Markdown can then be saved as HTML in another
#pod field by adding C<< x-html-field => $field_name >>.
#pod
#pod =head3 Required Values
#pod
#pod JSON Schema allows marking properties as required using the C<required>
#pod property, which must be an array of property names.
#pod
#pod     collections => {
#pod         people => {
#pod             required => [ 'name', 'email' ],
#pod             properties => {
#pod                 id => {
#pod                     type => 'integer',
#pod                     readOnly => 1,
#pod                 },
#pod                 name => {
#pod                     type => 'string',
#pod                 },
#pod                 email => {
#pod                     type => 'string',
#pod                 },
#pod             },
#pod         },
#pod     },
#pod
#pod Required values will be marked as such in the HTML.
#pod
#pod =head3 Example Values
#pod
#pod Setting an example value makes it easier to add new data. When a user
#pod tries to add a new item, Yancy will fill in the data from the C<example>
#pod key of the collection. This key holds an example object using fake data.
#pod As an example of our C<people> collection:
#pod
#pod     people => {
#pod         example => {
#pod             name => 'Philip J. Fry',
#pod             email => 'fry@aol.com',
#pod         },
#pod         properties => { ... },
#pod     },
#pod
#pod =head3 Extended Collection Configuration
#pod
#pod There are some extended fields you can add to your collection definition
#pod to control how it is treated by Yancy.
#pod
#pod =over
#pod
#pod =item x-hidden
#pod
#pod If this is true, the collection will be hidden from the list in the Yancy
#pod web app. This does not prevent using the API to edit this data.
#pod
#pod =item x-id-field
#pod
#pod This key sets the name of the collection's ID field to use to uniquely
#pod identify individual items. By default, Yancy assumes the ID field is
#pod named C<id>. If your collection uses some other identifier (e-mail
#pod address or username for example), you should set this configuration key.
#pod
#pod     people => {
#pod         'x-id-field' => 'email',
#pod         properties => { ... },
#pod     },
#pod
#pod =item x-list-columns
#pod
#pod This key should be an array of columns to display on the list view, in
#pod order. This helps put useful information on the list page.
#pod
#pod     people => {
#pod         'x-list-columns' => [ 'name', 'email' ],
#pod         properties => { ... },
#pod     },
#pod
#pod =back
#pod
#pod =head3 Extended Field Configuration
#pod
#pod There are some extended fields you can add to a field configuration
#pod to control how it is treated by Yancy.
#pod
#pod =over
#pod
#pod =item x-hidden
#pod
#pod If true, thie field will be hidden from the rich editing form.
#pod
#pod =item x-filter
#pod
#pod This key is an array of filter names to run on the field when setting or
#pod creating an item. Filters can allow for hashing passwords, for example.
#pod Filters are added by plugins or during configuration of
#pod L<Mojolicious::Plugin::Yancy>. See
#pod L<Mojolicious::Plugin::Yancy/yancy.filter.add> for how to add a filter.
#pod
#pod =back
#pod
#pod =head2 Additional Configuration
#pod
#pod There are additional configuration keys to alter how Yancy works.
#pod
#pod =head3 C<controller_class>
#pod
#pod To customize how Yancy responds to API requests with data, you can create
#pod a custom controller and set the class here. For details how to create
#pod a custom controller, see L<Yancy::Controller::Yancy>.
#pod
#pod =head3 C<read_schema>
#pod
#pod When this is set, Yancy will read your backend to see what collections
#pod you have available. Any collections and fields that you do not configure
#pod will be assigned default configuration from your database schema. You
#pod can use the configuration to override information that Yancy gets
#pod incorrect.
#pod
#pod B<NOTE:> This exposes all the data in your schema to Yancy's API, which allows
#pod anyone to edit the data. If you do not want anyone to edit the data, use
#pod L<the plugin's route configuration|Mojolicious::Plugin::Yancy/CONFIGURATION> to
#pod add authentication to Yancy.
#pod
#pod =head1 BUNDLED PROJECTS
#pod
#pod This project bundles some other projects with the following licenses:
#pod
#pod =over
#pod
#pod =item * L<jQuery|http://jquery.com> Copyright JS Foundation and other contributors (MIT License)
#pod
#pod =item * L<Bootstrap|http://getbootstrap.com> Copyright 2011-2017 the Bootstrap Authors and Twitter, Inc. (MIT License)
#pod
#pod =item * L<Popper.js|https://popper.js.org> Copyright 2016 Federico Zivolo (MIT License)
#pod
#pod =item * L<FontAwesome|http://fontawesome.io> Copyright Dave Gandy (SIL OFL 1.1 and MIT License)
#pod
#pod =item * L<Vue.js|http://vuejs.org> Copyright 2013-2018, Yuxi (Evan) You (MIT License)
#pod
#pod =item * L<marked|https://github.com/chjj/marked> Copyright 2011-2018, Christopher Jeffrey (MIT License)
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<JSON schema|http://json-schema.org>, L<Mojolicious>
#pod
#pod =cut

use Mojo::Base 'Mojolicious';

sub startup {
    my ( $app ) = @_;
    $app->plugin( Config => { default => { } } );
    $app->plugin( 'Yancy', {
        %{ $app->config },
        route => $app->routes->any('/yancy'),
    } );

    unshift @{$app->plugins->namespaces}, 'Yancy::Plugin';
    for my $plugin ( @{ $app->config->{plugins} } ) {
        $app->plugin( @$plugin );
    }

    $app->routes->get('/*path', { path => 'index' } )
    ->to( cb => sub {
        my ( $c ) = @_;
        my $path = $c->stash( 'path' );
        return if $c->render_maybe( $path );
        $path =~ s{(^|/)[^/]+$}{${1}index};
        return $c->render( $path );
    } );
    # Add default not_found renderer
    push @{$app->renderer->classes}, 'Yancy';
}

1;

=pod

=head1 NAME

Yancy - A simple CMS for administrating data

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    ### Standalone app
    $ yancy daemon

    ### Mojolicious plugin
    use Mojolicious::Lite;
    plugin Yancy => { ... };

=head1 DESCRIPTION

=for html <p>
  <img alt="Screenshot"
    src="https://raw.github.com/preaction/Yancy/master/eg/screenshot.png?raw=true"
    width="600px">
</p>

L<Yancy> is a simple content management system (CMS) for administering
content in a database. Yancy accepts a configuration file that describes
the data in the database and builds a website that lists all of the
available data and allows a user to edit data, delete data, and add new
data.

Yancy uses L<JSON Schema|http://json-schema.org> to define the data in
the database. The schema is added to an L<OpenAPI
specification|http://openapis.org> which creates a L<REST
API|https://en.wikipedia.org/wiki/Representational_state_transfer> for
your data.

Yancy can be run in a standalone mode (which can be placed behind
a proxy), or can be embedded as a plugin into any application that uses
the L<Mojolicious> web framework.

Yancy can manage data in multiple databases using different backends
(L<Yancy::Backend> modules). Backends exist for L<Postgres via
Mojo::Pg|Yancy::Backend::Pg>, L<MySQL via
Mojo::mysql|Yancy::Backend::Mysql>, L<SQLite via
Mojo::SQLite|Yancy::Backend::Sqlite>, and L<DBIx::Class, a Perl
ORM|Yancy::Backend::DBIC>

=head2 Standalone App

To run Yancy as a standalone application, you must create a C<yancy.conf>
configuration file that defines how to connect to your database and what
the data inside looks like. See L</CONFIGURATION> for details.

B<NOTE:> Yancy does not have authentication or authorization built-in.
If you want to control which users have access to data, you should use
an HTTP proxy with these features.

Once the application is started, you can navigate to C<<
http://127.0.0.1:3000/yancy >> to see the Yancy administration app.
Navigate to C<< http://127.0.0.1:3000/ >> to see the getting started
page.

=head3 Rendering Content

In the standalone app, all paths besides the C</yancy> application are
treated as paths to templates. If a specific template path is not found,
Yancy will search for an C<index> template in the same directory. If that
template is not found, an error is returned.

The templates are found in the C<templates> directory. You can change
the root directory that contains the C<templates> directory by setting
the C<MOJO_HOME> environment variable.

Template names must end with C<< .format.ep >> where C<format> is the
content type (C<html> is the default). You can render plain text (C<txt>),
JSON (C<json>), XML (C<xml>), and others.

Database content can be read by using the database helpers that Yancy
provides.

=over

=item * C<< yancy->list( $collection ) >> - Get a list of items

=item * C<< yancy->get( $collection, $id ) >> - Get a single item

=item * C<< yancy->set( $collection, $id, $data ) >> - Update an item

=item * C<< yancy->delete( $collection, $id ) >> - Delete an item

=item * C<< yancy->create( $collection, $data ) >> - Create an item

=back

Some example template code:

    %# Get a list of people
    % my @people = app->yancy->list( 'people' );

    %# Show a list of people names 
    <ul>
        % for my $person ( @people ) {
            <li><%= $person->{name} %></li>
        % }
    </ul>

    %# Get a single person with ID 1
    % my $person = app->yancy->get( 'people', 1 );

    %# Write the person's name to the page
    <p>Hi, my name is <%= $person->{name} %>.</p>

More information about L<Mojolicious> helpers is available at
L<Mojolicious::Guides::Rendering>.

=head3 Plugins

In standalone mode, you can configure plugins in the Yancy configuration
file. Plugins can be standard L<Mojolicious::Plugins> (with a name
starting with C<Mojolicious::Plugin>, or they can be specifically for
Yancy (by extending L<Mojolicious::Plugin> and having a name starting
with C<Yancy::Plugin>).

Plugins are configured as an array of arrays under the `plugins` key.
Each inner array should have the plugin's name and any arguments the
plugin requires, like so:

    {
        plugins => [
            [ 'PodRenderer' ],
            [ CGI => [ "/cgi-bin/script" => "/path/to/cgi/script.pl" ] ],
        ],
    }

=head2 Mojolicious Plugin

For information on how to use Yancy as a Mojolicious plugin, see
L<Mojolicious::Plugin::Yancy>.

=head2 REST API

This application creates a REST API using the standard
L<OpenAPI|http://openapis.org> API specification. The API spec document
is located at C</yancy/api>.

=head1 CONFIGURATION

The Yancy configuration file is a Perl data structure. The individual
parts are described below. An example configuration file looks like:

    {
        backend => 'pg://user@example.com/mydb',
        collections => {
            people => {
                type => 'object',
                properties => {
                    id => {
                        type => 'integer',
                        readOnly => 1,
                    },
                    name => { type => 'string' },
                    email => { type => 'string' },
                },
            },
        },
    }

=head2 Database Backend

The C<backend> URL defines what database to use and how to connect to
it. Each backend has its own format of URL, and some examples are shown
below. See your backend's documentation for more information.

=over

=item L<Postgres backend|Yancy::Backend::Pg>

    backend => 'pg://user@example.com/mydb',

=item L<MySQL backend|Yancy::Backend::Mysql>

    backend => 'mysql://user@localhost/mydb',

=item L<SQLite backend|Yancy::Backend::Sqlite>

    backend => 'sqlite:filename.db',

=item L<DBIx::Class backend|Yancy::Backend::Dbic>

    backend => 'dbic://My::Schema/dbi:SQLite:file.db',

=back

=head2 Data Collections

The C<collections> data structure defines what data is in the database.
Each key in this structure refers to the name of a collection, and the
value describe the fields for items inside the collection.

Each backend may define a collection differently. For a relational
database like Postgres or MySQL, a collection is a table, and the fields
are columns. For an ORM like DBIx::Class, the collections are ResultSet
objects. For a document store like MongoDB, the collections are
collections. See your backend's documentation for more information.

Collections are configured using L<JSON Schema|http://json-schema.org>.
The JSON Schema defines what fields (properties) an item has, and what
type of data those field have. The JSON Schema also can define
constraints like required fields or validate strings with regular
expressions. The schema can also contain metadata like a C<title>,
C<description>, and even an C<example> value. For more information on
what can be defined, see L<the docs on JSON Schema|http://json-schema.org>.

For a collection named C<people> that has 3 fields (an integer C<id> and
two strings, C<name> and C<email>), a minimal JSON schema will look like
this:

    collections => {
        people => {
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                },
                name => {
                    type => 'string',
                },
                email => {
                    type => 'string',
                },
            },
        },
    },

=head3 Generated Forms

Yancy generates input elements based on the C<type>, and C<format> of
the object's properties.

=over

=item * C<< type => "boolean" >> - A Yes/No field

=item * C<< type => "integer" >> - A number field (C<< <input type="number" > >>)

=item * C<< type => "number" >> - A number field (C<< <input type="number" > >>)

=item * C<< type => "string", format => "date" >> - A date field (C<< <input type="date"> >>)

=item * C<< type => "string", format => "date-time" >> - A date/time field (C<< <input type="datetime-local"> >>)

=item * C<< type => "string", format => "email" >> - A e-mail address (C<< <input type="email"> >>)

=item * C<< type => "string", format => "url" >> - A URL input (C<< <input type="url"> >>)

=item * C<< type => "string", format => "tel" >> - A telephone number (C<< <input type="tel"> >>)

=back

Fields with an C<enum> property will be translated to C<< <select> >>
elements.

Other schema attributes will be translated as necessary to the HTML
input fields:

=over

=item * C<title> will be used to label the input field

=item * C<readOnly>

=item * C<pattern>

=item * C<minimum>

=item * C<maximum>

=item * C<minLength>

=item * C<maxLength>

=back

A Markdown editor can be enabled by using C<< type => "string", format
=> "markdown" >>.  The Markdown can then be saved as HTML in another
field by adding C<< x-html-field => $field_name >>.

=head3 Required Values

JSON Schema allows marking properties as required using the C<required>
property, which must be an array of property names.

    collections => {
        people => {
            required => [ 'name', 'email' ],
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                },
                name => {
                    type => 'string',
                },
                email => {
                    type => 'string',
                },
            },
        },
    },

Required values will be marked as such in the HTML.

=head3 Example Values

Setting an example value makes it easier to add new data. When a user
tries to add a new item, Yancy will fill in the data from the C<example>
key of the collection. This key holds an example object using fake data.
As an example of our C<people> collection:

    people => {
        example => {
            name => 'Philip J. Fry',
            email => 'fry@aol.com',
        },
        properties => { ... },
    },

=head3 Extended Collection Configuration

There are some extended fields you can add to your collection definition
to control how it is treated by Yancy.

=over

=item x-hidden

If this is true, the collection will be hidden from the list in the Yancy
web app. This does not prevent using the API to edit this data.

=item x-id-field

This key sets the name of the collection's ID field to use to uniquely
identify individual items. By default, Yancy assumes the ID field is
named C<id>. If your collection uses some other identifier (e-mail
address or username for example), you should set this configuration key.

    people => {
        'x-id-field' => 'email',
        properties => { ... },
    },

=item x-list-columns

This key should be an array of columns to display on the list view, in
order. This helps put useful information on the list page.

    people => {
        'x-list-columns' => [ 'name', 'email' ],
        properties => { ... },
    },

=back

=head3 Extended Field Configuration

There are some extended fields you can add to a field configuration
to control how it is treated by Yancy.

=over

=item x-hidden

If true, thie field will be hidden from the rich editing form.

=item x-filter

This key is an array of filter names to run on the field when setting or
creating an item. Filters can allow for hashing passwords, for example.
Filters are added by plugins or during configuration of
L<Mojolicious::Plugin::Yancy>. See
L<Mojolicious::Plugin::Yancy/yancy.filter.add> for how to add a filter.

=back

=head2 Additional Configuration

There are additional configuration keys to alter how Yancy works.

=head3 C<controller_class>

To customize how Yancy responds to API requests with data, you can create
a custom controller and set the class here. For details how to create
a custom controller, see L<Yancy::Controller::Yancy>.

=head3 C<read_schema>

When this is set, Yancy will read your backend to see what collections
you have available. Any collections and fields that you do not configure
will be assigned default configuration from your database schema. You
can use the configuration to override information that Yancy gets
incorrect.

B<NOTE:> This exposes all the data in your schema to Yancy's API, which allows
anyone to edit the data. If you do not want anyone to edit the data, use
L<the plugin's route configuration|Mojolicious::Plugin::Yancy/CONFIGURATION> to
add authentication to Yancy.

=head1 BUNDLED PROJECTS

This project bundles some other projects with the following licenses:

=over

=item * L<jQuery|http://jquery.com> Copyright JS Foundation and other contributors (MIT License)

=item * L<Bootstrap|http://getbootstrap.com> Copyright 2011-2017 the Bootstrap Authors and Twitter, Inc. (MIT License)

=item * L<Popper.js|https://popper.js.org> Copyright 2016 Federico Zivolo (MIT License)

=item * L<FontAwesome|http://fontawesome.io> Copyright Dave Gandy (SIL OFL 1.1 and MIT License)

=item * L<Vue.js|http://vuejs.org> Copyright 2013-2018, Yuxi (Evan) You (MIT License)

=item * L<marked|https://github.com/chjj/marked> Copyright 2011-2018, Christopher Jeffrey (MIT License)

=back

=head1 SEE ALSO

L<JSON schema|http://json-schema.org>, L<Mojolicious>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Mohammad S Anwar William Lindley

=over 4

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

William Lindley <wlindley@wlindley.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ not_found.development.html.ep
% layout 'yancy';
<main id="app" class="container-fluid" style="margin-top: 10px">
    <div class="row">
        <div class="col-md-12">
            <h1>Welcome to Yancy</h1>
            <p>This is the default not found page.</p>

            <h2>Getting Started</h2>
            <p>To edit your data, go to <a href="/yancy">/yancy</a>.</p>
            <p>Add your templates to <tt><%= app->home->child( 'templates' ) %></tt>. Each template becomes a URL in your
            site:</p>
            <ul>
                <li><tt><%= app->home->child( 'templates', 'foo.html.ep' ) %></tt> becomes <a href="/foo">/foo</a>.</li>
                <li><tt><%= app->home->child( 'templates', 'foo', 'bar.html.ep' ) %></tt> becomes <a href="/foo/bar">/foo/bar</a>.</li>
            </ul>
            <p>To disable this page, run Yancy in production mode with <kbd>-m production</kbd>.</p>
        </div>
    </div>
</main>

