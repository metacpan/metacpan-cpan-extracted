package Wishlist;
use Mojo::Base 'Mojolicious';

use File::Share;
use Mojo::File;
use Mojo::Home;
use Mojo::SQLite;
use LinkEmbedder;
use Wishlist::Model;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

has dist_dir => sub {
  return Mojo::File->new(
    File::Share::dist_dir('Wishlist')
  );
};

has home => sub {
  my $home = $ENV{WISHLIST_HOME};
  return Mojo::Home->new($home ? $home : ())->to_abs;
};

has site_name => sub {
  my $app = shift;
  return $app->config->{site_name} || 'Mojo Wishlist';
};

has sqlite => sub {
  my $app = shift;

  # determine the storage location
  my $file = $app->config->{database} || 'wishlist.db';
  unless ($file =~ /^:/) {
    $file = Mojo::File->new($file);
    unless ($file->is_abs) {
      $file = $app->home->child("$file");
    }
  }

  my $sqlite = Mojo::SQLite->new
    ->from_filename("$file")
    ->auto_migrate(1);

  # attach migrations file
  $sqlite->migrations->from_file(
    $app->dist_dir->child('wishlist.sql')
  )->name('wishlist');

  return $sqlite;
};

sub startup {
  my $app = shift;

  $app->plugin('Config' => {
    file => $ENV{WISHLIST_CONFIG},
    default => {},
  });

  if (my $secrets = $app->config->{secrets}) {
    $app->secrets($secrets);
  }

  $app->renderer->paths([
    $app->dist_dir->child('templates'),
  ]);

  $app->helper(link => sub {
    my $c = shift;
    state $le = LinkEmbedder->new;
    return $le->get(@_);
  });

  $app->helper(model => sub {
    my $c = shift;
    return Wishlist::Model->new(
      sqlite => $c->app->sqlite,
    );
  });

  $app->helper(user => sub {
    my ($c, $username) = @_;
    $username ||= $c->stash->{username} || $c->session->{username};
    return {} unless $username;
    return $c->model->user($username) || {};
  });

  $app->helper(users => sub {
    my $c = shift;
    return $c->model->all_users;
  });

  my $r = $app->routes;
  $r->get('/' => sub {
    my $c = shift;
    my $template = $c->session->{username} ? 'list' : 'login';
    $c->render($template);
  });

  $r->get('/list/:username')->to(template => 'list')->name('list');

  $r->get('/add')->to('List#show_add')->name('show_add');
  $r->post('/add')->to('List#do_add')->name('do_add');

  $r->post('/update')->to('List#update')->name('update');
  $r->post('/remove')->to('List#remove')->name('remove');

  $r->get('/register')->to(template => 'register')->name('show_register');
  $r->post('/register')->to('Access#register')->name('do_register');
  $r->post('/login')->to('Access#login')->name('login');
  $r->any('/logout')->to('Access#logout')->name('logout');

}

1;

=head1 NAME

Wishlist - A multi-user web application for tracking wanted items.

=head1 SYNOPSIS

  $ wishlist daemon
  $ wishlist prefork
  $ hypnotoad `which wishlist`

=head1 DESCRIPTION

L<Wishlist> is a L<Mojolicious> application for storing and sharing wishlists derived from external urls.
Users paste urls and the app fetches data from those sites.
Users can then add the item to their wishlist.
Other users can then mark the item as purchased.

The application is very raw, lots of feature improvement is possible.
It was developed as examples from L<several of the posts|https://mojolicious.io/blog/tag/wishlist/> during the L<2017 Mojolicious Advent Calendar|https://mojolicious.io/blog/tag/advent/>.
I hope that it will continue to improve, with community collaboration, into a fully fledge competitor to cloud solutions that track and mine your data.

=head1 DEPLOYING

As L<Wishlist> is just a L<Mojolicious> application, all of the L<Mojolicious::Guides::Cookbook/DEPLOYMENT> options are available for deployment.

=head2 APPLICATION HOME

The application home is where L<Wishlist> stores data and looks for configuration.
It can be set by setting C<WISHLIST_HOME> in your environment, otherwise your current working directory is used.

=head2 CONFIGURATION

  {
    site_name => 'Family Wishlist',
    secrets => ['a very secret string'],
    database => '/path/to/database/file.db',
  }

A configuration file is highly recommended.
Its contents should evaluate to a Perl data structure.
The easiest usage is to create a configuration file in the L</"APPLICATION HOME">.
The file should be called C<wishlist.conf> or C<wishlist.$mode.conf> if per-mode configuration is desired.
Alternatively, an absolute path to the configuration file can be given via C<WISHLIST_CONFIG>.

The allowed configuration options are

=over

=item site_name

A string specifying the name of the site.
Used in the link to the application root.
Defaults to C<Mojo Wishlist>.

=item secrets

An array reference of strings used to sign storage cookies.
While this value is optional, it is highly recommended.
Learn about how these work at L<https://mojolicious.io/blog/2017/12/16/day-16-the-secret-life-of-sessions>.

=item database

Path to the file used to store data via L<Mojo::SQLite>.
If not specified the default value will be C<wishlist.db>.
Any relative values will be relative to the L</"APPLICATION HOME">.

=item hypnotoad

Hypnotoad uses the application's configuration for deployment parameters.
If you deploy using it, you probably should read L<Mojolicious::Guides::Cookbook/Hypnotoad>.

=back

=head1 SEE ALSO

=over

=item L<Blog entries tagged 'wishlist'|https://mojolicious.io/blog/tag/wishlist/>

=item L<Mojolicious>

=item L<LinkEmbedder>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Wishlist>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

Nakayama Yasuhiro (yasu47b)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by L</AUTHOR> and L</CONTRIBUTORS>.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
