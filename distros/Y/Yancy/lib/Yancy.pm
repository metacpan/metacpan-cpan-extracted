package Yancy;
our $VERSION = '1.066';
# ABSTRACT: The Best Web Framework Deserves the Best CMS

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     # Mojolicious
#pod     $self->plugin( Yancy => backend => 'postgresql://postgres@/mydb' );
#pod
#pod     # Mojolicious::Lite
#pod     plugin Yancy => backend => 'postgresql://postgres@/mydb'; # mysql, sqlite, dbic...
#pod
#pod     # Secure access to the admin UI with Basic authentication
#pod     my $under = $app->routes->under( '/yancy', sub( $c ) {
#pod         return 1 if $c->req->url->to_abs->userinfo eq 'Bender:rocks';
#pod         $c->res->headers->www_authenticate('Basic');
#pod         $c->render(text => 'Authentication required!', status => 401);
#pod         return undef;
#pod     });
#pod     $self->plugin( Yancy => backend => 'postgresql://postgres@/mydb', route => $under );
#pod
#pod     # ... then load the editor at http://127.0.0.1:3000/yancy
#pod
#pod =head1 DESCRIPTION
#pod
#pod =begin html
#pod
#pod <div style="display: flex">
#pod <div style="margin: 3px; flex: 1 1 50%">
#pod <img alt="Screenshot of list of Futurama characters" src="https://raw.github.com/preaction/Yancy/master/eg/doc-site/public/screenshot.png?raw=true" style="max-width: 100%" width="600">
#pod </div>
#pod <div style="margin: 3px; flex: 1 1 50%">
#pod <img alt="Screenshot of editing form for a person" src="https://raw.github.com/preaction/Yancy/master/eg/doc-site/public/screenshot-edit.png?raw=true" style="max-width: 100%" width="600">
#pod </div>
#pod </div>
#pod
#pod =end html
#pod
#pod L<Yancy> is a content management system (CMS) for L<Mojolicious>.  It
#pod includes an admin application to edit content and tools to quickly build
#pod an application.
#pod
#pod =head2 Admin App
#pod
#pod Yancy provides an application to edit content at the path C</yancy> on
#pod your website. Yancy can manage data in multiple databases using
#pod different L<backend modules|Yancy::Backend>. You can provide a URL
#pod string to tell Yancy how to connect to your database, or you can provide
#pod your database object.  Yancy supports the following databases:
#pod
#pod =head3 Postgres
#pod
#pod L<PostgreSQL|http://example.com> is supported through the L<Mojo::Pg>
#pod module.
#pod
#pod     # PostgreSQL: A Mojo::Pg connection string
#pod     plugin Yancy => backend => 'postgresql://postgres@/test';
#pod
#pod     # PostgreSQL: A Mojo::Pg object
#pod     plugin Yancy => backend => Mojo::Pg->new( 'postgresql://postgres@/test' );
#pod
#pod =head3 MySQL
#pod
#pod L<MySQL|http://example.com> is supported through the L<Mojo::mysql>
#pod module.
#pod
#pod     # MySQL: A Mojo::mysql connection string
#pod     plugin Yancy => backend => 'mysql://user@/test';
#pod
#pod     # MySQL: A Mojo::mysql object
#pod     plugin Yancy => backend => Mojo::mysql->strict_mode( 'mysql://user@/test' );
#pod
#pod =head3 SQLite
#pod
#pod L<SQLite|http://example.com> is supported through the L<Mojo::SQLite> module.
#pod This is a good option if you want to try Yancy out.
#pod
#pod     # SQLite: A Mojo::SQLite connection string
#pod     plugin Yancy => backend => 'sqlite:test.db';
#pod
#pod     # SQLite: A Mojo::SQLite object
#pod     plugin Yancy => backend => Mojo::SQLite->new( 'sqlite::temp:' );
#pod
#pod =head3 DBIx::Class
#pod
#pod If you have a L<DBIx::Class> schema, Yancy can use it to edit the content.
#pod
#pod     # DBIx::Class: A connection string
#pod     plugin Yancy => backend => 'dbic://My::Schema/dbi:SQLite:test.db';
#pod
#pod     # DBIx::Class: A DBIx::Class::Schema object
#pod     plugin Yancy => backend => My::Schema->connect( 'dbi:SQLite:test.db' );
#pod
#pod =head2 Content Tools
#pod
#pod =head3 Schema Information and Validation
#pod
#pod Yancy scans your database to determine what kind of data is inside, but
#pod Yancy also accepts a L<JSON Schema|http://example.com> to add more
#pod information about your data. You can add descriptions, examples, and
#pod other documentation that will appear in the admin application. You can
#pod also add type, format, and other validation information, which Yancy
#pod will use to validate input from users. See L<Yancy::Help::Config/Schema>
#pod for how to define your schema.
#pod
#pod     plugin Yancy => backend => 'postgres://postgres@/test',
#pod         schema => {
#pod             employees => {
#pod                 title => 'Employees',
#pod                 description => 'Our crack team of loyal dregs.',
#pod                 properties => {
#pod                     address => {
#pod                         description => 'Where to notify next-of-kin.',
#pod                         # Regexp to validate this field
#pod                         pattern => '^\d+ \S+',
#pod                     },
#pod                     email => {
#pod                         # Use the browser's native e-mail input
#pod                         format => 'email',
#pod                     },
#pod                 },
#pod             },
#pod         };
#pod
#pod =head3 Data Helpers
#pod
#pod L<Mojolicious::Plugin::Yancy> provides helpers to work with your database content.
#pod These use the validations provided in the schema to validate user input. These
#pod helpers can be used in your route handlers to quickly add basic Create, Read, Update,
#pod and Delete (CRUD) functionality. See L<Mojolicious::Plugin::Yancy/HELPERS> for a list
#pod of provided helpers.
#pod
#pod     # View a list of blog entries
#pod     get '/' => sub( $c ) {
#pod         my @blog_entries = $c->yancy->list(
#pod             blog_entries =>
#pod             { published => 1 },
#pod             { order_by => { -desc => 'published_date' } },
#pod         );
#pod         $c->render(
#pod             'blog_list',
#pod             items => \@blog_entries,
#pod         );
#pod     };
#pod
#pod     # View a single blog entry
#pod     get '/blog/:blog_entry_id' => sub( $c ) {
#pod         my $blog_entry = $c->yancy->get(
#pod             blog_entries => $c->param( 'blog_entry_id' ),
#pod         );
#pod         $c->render(
#pod             'blog_entry',
#pod             item => $blog_entry,
#pod         );
#pod     };
#pod
#pod =head3 Forms
#pod
#pod The L<Yancy::Plugin::Form> plugin can generate input fields or entire
#pod forms based on your schema information. The annotations in your schema
#pod appear in the forms to help users fill them out. Additionally, with the
#pod L<Yancy::Plugin::Form::Bootstrap4> module, Yancy can create forms using
#pod L<Twitter Bootstrap|http://example.com> components.
#pod
#pod     # Load the form plugin
#pod     app->yancy->plugin( 'Form::Bootstrap4' );
#pod
#pod     # Edit a blog entry
#pod     any [ 'GET', 'POST' ], '/edit/:blog_entry_id' => sub( $c ) {
#pod         if ( $c->req->method eq 'GET' ) {
#pod             my $blog_entry = $c->yancy->get(
#pod                 blog_entries => $c->param( 'blog_entry_id' ),
#pod             );
#pod             return $c->render(
#pod                 'blog_entry',
#pod                 item => $blog_entry,
#pod             );
#pod         }
#pod         my $id = $c->param( 'blog_entry_id' );
#pod         my $item = $c->req->params->to_hash;
#pod         delete $item->{csrf_token}; # See https://docs.mojolicious.org/Mojolicious/Guides/Rendering#Cross-site-request-forgery
#pod         $c->yancy->set( blog_entries => $id, $c->req->params->to_hash );
#pod         $c->redirect_to( '/blog/' . $id );
#pod     };
#pod
#pod     __DATA__
#pod     @@ blog_form.html.ep
#pod     %= $c->yancy->form->form_for( 'blog_entries', item => stash 'item' )
#pod
#pod =head3 Controllers
#pod
#pod Yancy can add basic CRUD operations without writing the code yourself. The
#pod L<Yancy::Controller::Yancy> module uses the schema information to show, search,
#pod edit, create, and delete database items.
#pod
#pod     # A rewrite of the routes above to use Yancy::Controller::Yancy
#pod
#pod     # View a list of blog entries
#pod     get '/' => {
#pod         controller => 'yancy',
#pod         action => 'list',
#pod         schema => 'blog_entries',
#pod         filter => { published => 1 },
#pod         order_by => { -desc => 'published_date' },
#pod     } => 'blog.list';
#pod
#pod     # View a single blog entry
#pod     get '/blog/:blog_entry_id' => {
#pod         controller => 'yancy',
#pod         action => 'get',
#pod         schema => 'blog_entries',
#pod     } => 'blog.get';
#pod
#pod     # Load the form plugin
#pod     app->yancy->plugin( 'Form::Bootstrap4' );
#pod
#pod     # Edit a blog entry
#pod     any [ 'GET', 'POST' ], '/edit/:blog_entry_id' => {
#pod         controller => 'yancy',
#pod         action => 'set',
#pod         schema => 'blog_entries',
#pod         template => 'blog_form',
#pod         redirect_to => 'blog.get',
#pod     } => 'blog.edit';
#pod
#pod     __DATA__
#pod     @@ blog_form.html.ep
#pod     %= $c->yancy->form->form_for( 'blog_entries' )
#pod
#pod =head3 Plugins
#pod
#pod Yancy also has plugins for...
#pod
#pod =over
#pod
#pod =item * User authentication: L<Yancy::Plugin::Auth>
#pod
#pod =item * File management: L<Yancy::Plugin::File>
#pod
#pod =back
#pod
#pod More development will be happening here soon!
#pod
#pod =head1 GUIDES
#pod
#pod For in-depth documentation on Yancy, see the following guides:
#pod
#pod =over
#pod
#pod =item * L<Yancy::Help::Config> - How to configure Yancy
#pod
#pod =item * L<Yancy::Help::Cookbook> - How to cook various apps with Yancy
#pod
#pod =item * L<Yancy::Help::Auth> - How to authenticate and authorize users
#pod
#pod =item * L<Yancy::Help::Standalone> - How to use Yancy without a Mojolicious app
#pod
#pod =item * L<Yancy::Help::Upgrading> - How to upgrade from previous versions
#pod
#pod =back
#pod
#pod =head1 OTHER RESOURCES
#pod
#pod =head2 Example Applications
#pod
#pod The L<Yancy Git repository on Github|http://github.com/preaction/Yancy>
#pod includes some example applications you can use to help build your own
#pod websites. L<View the example application directory|https://github.com/preaction/Yancy/tree/master/eg>.
#pod
#pod =head1 BUNDLED PROJECTS
#pod
#pod This project bundles some other projects with the following licenses:
#pod
#pod =over
#pod
#pod =item * L<jQuery|http://jquery.com> (version 3.2.1) Copyright JS Foundation and other contributors (MIT License)
#pod
#pod =item * L<Bootstrap|http://getbootstrap.com> (version 4.3.1) Copyright 2011-2019 the Bootstrap Authors and Twitter, Inc. (MIT License)
#pod
#pod =item * L<Popper.js|https://popper.js.org> (version 1.13.0) Copyright 2017 Federico Zivolo (MIT License)
#pod
#pod =item * L<FontAwesome|http://fontawesome.io> (version 4.7.0) Copyright Dave Gandy (SIL OFL 1.1 and MIT License)
#pod
#pod =item * L<Vue.js|http://vuejs.org> (version 2.5.3) Copyright 2013-2018, Yuxi (Evan) You (MIT License)
#pod
#pod =item * L<marked|https://github.com/chjj/marked> (version 0.3.12) Copyright 2011-2018, Christopher Jeffrey (MIT License)
#pod
#pod =back
#pod
#pod The bundled versions of these modules may change. If you rely on these in your own app,
#pod be sure to watch the changelog for version updates.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>
#pod
#pod =cut

use Mojo::Base 'Mojolicious';
use Mojo::File qw( path );

# Default home should be the current working directory so that config,
# templates, and static files can be found.
has home => sub {
    return !$ENV{MOJO_HOME} ? path : $_[0]->SUPER::home;
};

sub startup {
    my ( $app ) = @_;
    $app->plugin( Config => { default => { } } );
    $app->plugin( 'Yancy', $app->config );

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

Yancy - The Best Web Framework Deserves the Best CMS

=head1 VERSION

version 1.066

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin( Yancy => backend => 'postgresql://postgres@/mydb' );

    # Mojolicious::Lite
    plugin Yancy => backend => 'postgresql://postgres@/mydb'; # mysql, sqlite, dbic...

    # Secure access to the admin UI with Basic authentication
    my $under = $app->routes->under( '/yancy', sub( $c ) {
        return 1 if $c->req->url->to_abs->userinfo eq 'Bender:rocks';
        $c->res->headers->www_authenticate('Basic');
        $c->render(text => 'Authentication required!', status => 401);
        return undef;
    });
    $self->plugin( Yancy => backend => 'postgresql://postgres@/mydb', route => $under );

    # ... then load the editor at http://127.0.0.1:3000/yancy

=head1 DESCRIPTION

=encoding utf8

=for html <div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Screenshot of list of Futurama characters" src="https://raw.github.com/preaction/Yancy/master/eg/doc-site/public/screenshot.png?raw=true" style="max-width: 100%" width="600">
</div>
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Screenshot of editing form for a person" src="https://raw.github.com/preaction/Yancy/master/eg/doc-site/public/screenshot-edit.png?raw=true" style="max-width: 100%" width="600">
</div>
</div>

L<Yancy> is a content management system (CMS) for L<Mojolicious>.  It
includes an admin application to edit content and tools to quickly build
an application.

=head2 Admin App

Yancy provides an application to edit content at the path C</yancy> on
your website. Yancy can manage data in multiple databases using
different L<backend modules|Yancy::Backend>. You can provide a URL
string to tell Yancy how to connect to your database, or you can provide
your database object.  Yancy supports the following databases:

=head3 Postgres

L<PostgreSQL|http://example.com> is supported through the L<Mojo::Pg>
module.

    # PostgreSQL: A Mojo::Pg connection string
    plugin Yancy => backend => 'postgresql://postgres@/test';

    # PostgreSQL: A Mojo::Pg object
    plugin Yancy => backend => Mojo::Pg->new( 'postgresql://postgres@/test' );

=head3 MySQL

L<MySQL|http://example.com> is supported through the L<Mojo::mysql>
module.

    # MySQL: A Mojo::mysql connection string
    plugin Yancy => backend => 'mysql://user@/test';

    # MySQL: A Mojo::mysql object
    plugin Yancy => backend => Mojo::mysql->strict_mode( 'mysql://user@/test' );

=head3 SQLite

L<SQLite|http://example.com> is supported through the L<Mojo::SQLite> module.
This is a good option if you want to try Yancy out.

    # SQLite: A Mojo::SQLite connection string
    plugin Yancy => backend => 'sqlite:test.db';

    # SQLite: A Mojo::SQLite object
    plugin Yancy => backend => Mojo::SQLite->new( 'sqlite::temp:' );

=head3 DBIx::Class

If you have a L<DBIx::Class> schema, Yancy can use it to edit the content.

    # DBIx::Class: A connection string
    plugin Yancy => backend => 'dbic://My::Schema/dbi:SQLite:test.db';

    # DBIx::Class: A DBIx::Class::Schema object
    plugin Yancy => backend => My::Schema->connect( 'dbi:SQLite:test.db' );

=head2 Content Tools

=head3 Schema Information and Validation

Yancy scans your database to determine what kind of data is inside, but
Yancy also accepts a L<JSON Schema|http://example.com> to add more
information about your data. You can add descriptions, examples, and
other documentation that will appear in the admin application. You can
also add type, format, and other validation information, which Yancy
will use to validate input from users. See L<Yancy::Help::Config/Schema>
for how to define your schema.

    plugin Yancy => backend => 'postgres://postgres@/test',
        schema => {
            employees => {
                title => 'Employees',
                description => 'Our crack team of loyal dregs.',
                properties => {
                    address => {
                        description => 'Where to notify next-of-kin.',
                        # Regexp to validate this field
                        pattern => '^\d+ \S+',
                    },
                    email => {
                        # Use the browser's native e-mail input
                        format => 'email',
                    },
                },
            },
        };

=head3 Data Helpers

L<Mojolicious::Plugin::Yancy> provides helpers to work with your database content.
These use the validations provided in the schema to validate user input. These
helpers can be used in your route handlers to quickly add basic Create, Read, Update,
and Delete (CRUD) functionality. See L<Mojolicious::Plugin::Yancy/HELPERS> for a list
of provided helpers.

    # View a list of blog entries
    get '/' => sub( $c ) {
        my @blog_entries = $c->yancy->list(
            blog_entries =>
            { published => 1 },
            { order_by => { -desc => 'published_date' } },
        );
        $c->render(
            'blog_list',
            items => \@blog_entries,
        );
    };

    # View a single blog entry
    get '/blog/:blog_entry_id' => sub( $c ) {
        my $blog_entry = $c->yancy->get(
            blog_entries => $c->param( 'blog_entry_id' ),
        );
        $c->render(
            'blog_entry',
            item => $blog_entry,
        );
    };

=head3 Forms

The L<Yancy::Plugin::Form> plugin can generate input fields or entire
forms based on your schema information. The annotations in your schema
appear in the forms to help users fill them out. Additionally, with the
L<Yancy::Plugin::Form::Bootstrap4> module, Yancy can create forms using
L<Twitter Bootstrap|http://example.com> components.

    # Load the form plugin
    app->yancy->plugin( 'Form::Bootstrap4' );

    # Edit a blog entry
    any [ 'GET', 'POST' ], '/edit/:blog_entry_id' => sub( $c ) {
        if ( $c->req->method eq 'GET' ) {
            my $blog_entry = $c->yancy->get(
                blog_entries => $c->param( 'blog_entry_id' ),
            );
            return $c->render(
                'blog_entry',
                item => $blog_entry,
            );
        }
        my $id = $c->param( 'blog_entry_id' );
        my $item = $c->req->params->to_hash;
        delete $item->{csrf_token}; # See https://docs.mojolicious.org/Mojolicious/Guides/Rendering#Cross-site-request-forgery
        $c->yancy->set( blog_entries => $id, $c->req->params->to_hash );
        $c->redirect_to( '/blog/' . $id );
    };

    __DATA__
    @@ blog_form.html.ep
    %= $c->yancy->form->form_for( 'blog_entries', item => stash 'item' )

=head3 Controllers

Yancy can add basic CRUD operations without writing the code yourself. The
L<Yancy::Controller::Yancy> module uses the schema information to show, search,
edit, create, and delete database items.

    # A rewrite of the routes above to use Yancy::Controller::Yancy

    # View a list of blog entries
    get '/' => {
        controller => 'yancy',
        action => 'list',
        schema => 'blog_entries',
        filter => { published => 1 },
        order_by => { -desc => 'published_date' },
    } => 'blog.list';

    # View a single blog entry
    get '/blog/:blog_entry_id' => {
        controller => 'yancy',
        action => 'get',
        schema => 'blog_entries',
    } => 'blog.get';

    # Load the form plugin
    app->yancy->plugin( 'Form::Bootstrap4' );

    # Edit a blog entry
    any [ 'GET', 'POST' ], '/edit/:blog_entry_id' => {
        controller => 'yancy',
        action => 'set',
        schema => 'blog_entries',
        template => 'blog_form',
        redirect_to => 'blog.get',
    } => 'blog.edit';

    __DATA__
    @@ blog_form.html.ep
    %= $c->yancy->form->form_for( 'blog_entries' )

=head3 Plugins

Yancy also has plugins for...

=over

=item * User authentication: L<Yancy::Plugin::Auth>

=item * File management: L<Yancy::Plugin::File>

=back

More development will be happening here soon!

=head1 GUIDES

For in-depth documentation on Yancy, see the following guides:

=over

=item * L<Yancy::Help::Config> - How to configure Yancy

=item * L<Yancy::Help::Cookbook> - How to cook various apps with Yancy

=item * L<Yancy::Help::Auth> - How to authenticate and authorize users

=item * L<Yancy::Help::Standalone> - How to use Yancy without a Mojolicious app

=item * L<Yancy::Help::Upgrading> - How to upgrade from previous versions

=back

=head1 OTHER RESOURCES

=head2 Example Applications

The L<Yancy Git repository on Github|http://github.com/preaction/Yancy>
includes some example applications you can use to help build your own
websites. L<View the example application directory|https://github.com/preaction/Yancy/tree/master/eg>.

=head1 BUNDLED PROJECTS

This project bundles some other projects with the following licenses:

=over

=item * L<jQuery|http://jquery.com> (version 3.2.1) Copyright JS Foundation and other contributors (MIT License)

=item * L<Bootstrap|http://getbootstrap.com> (version 4.3.1) Copyright 2011-2019 the Bootstrap Authors and Twitter, Inc. (MIT License)

=item * L<Popper.js|https://popper.js.org> (version 1.13.0) Copyright 2017 Federico Zivolo (MIT License)

=item * L<FontAwesome|http://fontawesome.io> (version 4.7.0) Copyright Dave Gandy (SIL OFL 1.1 and MIT License)

=item * L<Vue.js|http://vuejs.org> (version 2.5.3) Copyright 2013-2018, Yuxi (Evan) You (MIT License)

=item * L<marked|https://github.com/chjj/marked> (version 0.3.12) Copyright 2011-2018, Christopher Jeffrey (MIT License)

=back

The bundled versions of these modules may change. If you rely on these in your own app,
be sure to watch the changelog for version updates.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Boris Däppen Ed J Erik Johansen Josh Rabinowitz Mohammad S Anwar Pavel Serikov Rajesh Mallah William Lindley Wojtek Bażant

=over 4

=item *

Boris Däppen <bdaeppen.perl@gmail.com>

=item *

Ed J <mohawk2@users.noreply.github.com>

=item *

Erik Johansen <uniejo@users.noreply.github.com>

=item *

Josh Rabinowitz <joshr@joshr.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Pavel Serikov <pavelsr@cpan.org>

=item *

Rajesh Mallah <mallah.rajesh@gmail.com>

=item *

William Lindley <wlindley@wlindley.com>

=item *

Wojtek Bażant <wojciech.bazant+ebi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

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

