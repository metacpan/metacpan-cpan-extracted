package Yancy;
our $VERSION = '1.003';
# ABSTRACT: A simple CMS for administrating data

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     use Mojo::Pg; # Supported backends: Pg, MySQL, SQLite, DBIx::Class
#pod     plugin Yancy => {
#pod         backend => { Pg => Mojo::Pg->new( 'postgres:///myapp' ) },
#pod         read_schema => 1,
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod =begin html
#pod
#pod <p>
#pod   <img alt="Screenshot of list of Futurama characters"
#pod     src="https://raw.github.com/preaction/Yancy/master/eg/screenshot.png?raw=true"
#pod     width="600px">
#pod   <img alt="Screenshot of editing form for a person"
#pod     src="https://raw.github.com/preaction/Yancy/master/eg/screenshot-edit.png?raw=true"
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
#pod ORM|Yancy::Backend::Dbic>
#pod
#pod =head2 Mojolicious Plugin
#pod
#pod Yancy is primarily a Mojolicious plugin to ease development and
#pod management of Mojolicious applications. Yancy provides:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod L<Helpers|Mojolicious::Plugin::Yancy/HELPERS> to access data, validate
#pod forms
#pod
#pod =item *
#pod
#pod L<Templates|Mojolicious::Plugin::Yancy/TEMPLATES> which you can override
#pod to customize the Yancy editor's appearance
#pod
#pod =back
#pod
#pod For information on how to use Yancy as a Mojolicious plugin, see
#pod L<Mojolicious::Plugin::Yancy>.
#pod
#pod =head2 Standalone App
#pod
#pod Yancy can also be run as a standalone app in the event one wants to
#pod develop applications solely using Mojolicious templates. For
#pod information on how to run Yancy as a standalone application, see
#pod L<Yancy::Help::Standalone>.
#pod
#pod =head2 REST API
#pod
#pod This application creates a REST API using the standard
#pod L<OpenAPI|http://openapis.org> API specification. The API spec document
#pod is located at C</yancy/api>.
#pod
#pod =head2 Yancy Plugins
#pod
#pod Yancy comes with plugins to enhance your website.
#pod
#pod =over
#pod
#pod =item *
#pod
#pod L<The Auth::Basic plugin|Yancy::Plugin::Auth::Basic> provides a simple,
#pod password-based authentication system for the Yancy editor and your
#pod website.
#pod
#pod =back
#pod
#pod More development will be happening here soon!
#pod
#pod =head1 CONFIGURATION
#pod
#pod See L<Yancy::Help::Config> for how to configure Yancy in both plugin and
#pod standalone mode.
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

version 1.003

=head1 SYNOPSIS

    use Mojolicious::Lite;
    use Mojo::Pg; # Supported backends: Pg, MySQL, SQLite, DBIx::Class
    plugin Yancy => {
        backend => { Pg => Mojo::Pg->new( 'postgres:///myapp' ) },
        read_schema => 1,
    };

=head1 DESCRIPTION

=for html <p>
  <img alt="Screenshot of list of Futurama characters"
    src="https://raw.github.com/preaction/Yancy/master/eg/screenshot.png?raw=true"
    width="600px">
  <img alt="Screenshot of editing form for a person"
    src="https://raw.github.com/preaction/Yancy/master/eg/screenshot-edit.png?raw=true"
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
ORM|Yancy::Backend::Dbic>

=head2 Mojolicious Plugin

Yancy is primarily a Mojolicious plugin to ease development and
management of Mojolicious applications. Yancy provides:

=over

=item *

L<Helpers|Mojolicious::Plugin::Yancy/HELPERS> to access data, validate
forms

=item *

L<Templates|Mojolicious::Plugin::Yancy/TEMPLATES> which you can override
to customize the Yancy editor's appearance

=back

For information on how to use Yancy as a Mojolicious plugin, see
L<Mojolicious::Plugin::Yancy>.

=head2 Standalone App

Yancy can also be run as a standalone app in the event one wants to
develop applications solely using Mojolicious templates. For
information on how to run Yancy as a standalone application, see
L<Yancy::Help::Standalone>.

=head2 REST API

This application creates a REST API using the standard
L<OpenAPI|http://openapis.org> API specification. The API spec document
is located at C</yancy/api>.

=head2 Yancy Plugins

Yancy comes with plugins to enhance your website.

=over

=item *

L<The Auth::Basic plugin|Yancy::Plugin::Auth::Basic> provides a simple,
password-based authentication system for the Yancy editor and your
website.

=back

More development will be happening here soon!

=head1 CONFIGURATION

See L<Yancy::Help::Config> for how to configure Yancy in both plugin and
standalone mode.

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

=for stopwords Ed J Mohammad S Anwar William Lindley

=over 4

=item *

Ed J <mohawk2@users.noreply.github.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

William Lindley <wlindley@wlindley.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

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

