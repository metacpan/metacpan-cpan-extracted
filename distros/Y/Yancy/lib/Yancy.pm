package Yancy;
our $VERSION = '1.073';
# ABSTRACT: The Best Web Framework Deserves the Best CMS

# "Mr. Fry: Son, your name is Yancy, just like me and my grandfather and
# so on. All the way back to minuteman Yancy Fry, who blasted commies in
# the American Revolution."

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod Yancy is a simple content management system (CMS) for the L<Mojolicious> web framework.
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
#pod Get started with L<the Yancy documentation|Yancy::Guides>!
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
    unshift @{$app->plugins->namespaces}, 'Yancy::Plugin';

    $app->plugin( Config => { default => { } } );
    $app->plugin( 'Yancy', $app->config );

    # XXX: Add default migrations

    # Add default not_found renderer
    push @{$app->renderer->classes}, 'Yancy';
}

1;

=pod

=head1 NAME

Yancy - The Best Web Framework Deserves the Best CMS

=head1 VERSION

version 1.073

=head1 DESCRIPTION

Yancy is a simple content management system (CMS) for the L<Mojolicious> web framework.

=encoding utf8

=for html <div style="display: flex">
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Screenshot of list of Futurama characters" src="https://raw.github.com/preaction/Yancy/master/eg/doc-site/public/screenshot.png?raw=true" style="max-width: 100%" width="600">
</div>
<div style="margin: 3px; flex: 1 1 50%">
<img alt="Screenshot of editing form for a person" src="https://raw.github.com/preaction/Yancy/master/eg/doc-site/public/screenshot-edit.png?raw=true" style="max-width: 100%" width="600">
</div>
</div>

Get started with L<the Yancy documentation|Yancy::Guides>!

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

=for stopwords Boris Däppen Ed J Erik Johansen flash548 Josh Rabinowitz Mohammad S Anwar Pavel Serikov Rajesh Mallah Roy Storey William Lindley Wojtek Bażant

=over 4

=item *

Boris Däppen <bdaeppen.perl@gmail.com>

=item *

Ed J <mohawk2@users.noreply.github.com>

=item *

Erik Johansen <github@uniejo.dk>

=item *

Erik Johansen <uniejo@users.noreply.github.com>

=item *

flash548 <59771551+flash548@users.noreply.github.com>

=item *

Josh Rabinowitz <joshr@joshr.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Pavel Serikov <pavelsr@cpan.org>

=item *

Rajesh Mallah <mallah.rajesh@gmail.com>

=item *

Roy Storey <kiwiroy@users.noreply.github.com>

=item *

William Lindley <wlindley@wlindley.com>

=item *

Wojtek Bażant <wojciech.bazant+ebi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

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

