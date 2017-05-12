package WWW::MenuGrinder;
BEGIN {
  $WWW::MenuGrinder::VERSION = '0.06';
}

# ABSTRACT: A tool for managing dynamic website menus - base class.

use strict;
use warnings;

use Moose;

use WWW::MenuGrinder::Role::Plugin;
use WWW::MenuGrinder::Visitor;


has 'menu' => (
  is => 'rw',
);


has 'plugins' => (
  is => 'rw',
  isa => 'ArrayRef[WWW::MenuGrinder::Role::Plugin]',
  default => sub { [] },
);

has 'plugin_hash' => (
  is => 'rw',
  default => sub { + {} },
);

has 'loader' => (
  is => 'rw',
);

has 'on_load_plugins' => (
  is => 'rw',
  default => sub { [] },
);

has 'per_request_plugins' => (
  is => 'rw',
  default => sub { [] },
);

has 'outputs' => (
  is => 'rw',
  default => sub { [] },
);

has 'outputs_by_name' => (
  is => 'rw',
  default => sub { + {} },
);

has 'config' => (
  is => 'rw',
  default => sub { + {} },
);


sub rolename {
  my ($name) = @_;

  return __PACKAGE__ . "::Role::$name";
}


sub plugins_with {
  my ($self, $role) = @_;

  if ($role =~ s/^-//) {
    $role = rolename($role);
  }

  return [ grep $_->does($role), @{ $self->plugins } ]
}

sub _register_plugin {
  my ($self, $class, $plugin) = @_;

  push @{ $self->plugins }, $plugin;
  $self->plugin_hash->{$class} = $plugin;
}

sub _ensure_loaded {
  my ($self, $class) = @_;

  my $file = $class . '.pm';
  $file =~ s{::}{/}g;

  return 1 if $INC{$file};

  return eval qq{CORE::require(\$file)};
}


sub load_plugin {
  my ($self, $class) = @_;

  my $shortname;

  if ($class =~ /^\+/) {
    $class =~ s/^\+//;
  } else {
    $shortname = $class;
    $class =~ s/^/WWW::MenuGrinder::Plugin::/;
  }

  return $self->plugin_hash->{$class} if $self->plugin_hash->{$class};

  $self->_ensure_loaded($class) or die $@;

  if ($class->can('plugin_depends')) {
    my @deps = $class->plugin_depends;
    for my $dep (@deps) {
      eval {
        $self->load_plugin($dep);
      };
      if ($@) {
        die "$@ while loading $dep, which was required by $class";
      };
    }
  }

  my %plugin_config;

  if (defined $shortname) {
    my $config = $self->config->{$shortname};
    %plugin_config = %$config if defined $config;
  } else {
    my $config = $self->config->{$class};
    %plugin_config = %$config if defined $config;
  }

  my $plugin = $class->new( %plugin_config, grinder => $self );

  $plugin->verify_plugin;

  $self->_register_plugin($class, $plugin);
  return $plugin;
}


# Load and verify all of the plugins in the config.
sub load_plugins {
  my ($self, @args) = @_;

  my $plugins = $self->config->{plugins};

  my $loader = $plugins->{loader};
  die "config->{plugins}{loader} is mandatory" unless defined $loader;
  my $loaderclass = $self->load_plugin($loader);
  die "Specified plugin $loader is not a Loader" unless $loaderclass->does(rolename('Loader'));
  $self->loader($loaderclass);

  my $on_load = $plugins->{on_load} || [];
  for my $name (@$on_load) {
    my $plugin = $self->load_plugin($name);
    die "On-load plugin $name is not a Mogrifier or ItemMogrifier" 
      unless $plugin->does(rolename('Mogrifier')) or $plugin->does(rolename('ItemMogrifier'));
    push @{ $self->on_load_plugins }, $plugin;
  }

  my $per_request = $plugins->{per_request} || [];
  for my $name (@$per_request) {
    my $plugin = $self->load_plugin($name);
    die "Per-request plugin $name is not a Mogrifier, ItemMogrifier, or BeforeMogrify" 
      unless $plugin->does(rolename('Mogrifier')) or $plugin->does(rolename('ItemMogrifier')) or $plugin->does(rolename('BeforeMogrify'));
    push @{ $self->per_request_plugins }, $plugin;
  }

  my $outputs = $plugins->{outputs};
  $outputs = [ $plugins->{output} ] if !defined $outputs && defined $plugins->{output};
  $outputs = [] if !defined $outputs;

  for my $output (@$outputs) {
    my $plugin = $self->load_plugin($output);
    die "Specified plugin $output is not an Output" unless $plugin->does(rolename('Output'));
    $self->outputs_by_name->{$output} = $plugin;
    push @{ $self->outputs }, $plugin;
  }

}


sub init_menu {
  my ($self) = @_;

  my $menu = $self->loader->load;
  $menu = $self->mogrify( $menu, 'on-load', @{ $self->on_load_plugins } );
  $self->menu($menu);
  $_->on_init($menu) for @{ $self->plugins_with(-OnInit) };
}

sub BUILD {
  my ($self) = @_;

  $self->load_plugins;
  $self->init_menu;
}

# Remove items from the beginning of an array that pass some test and return
# them. Stop as soon as we find an item that fails the test.
sub _remove_initial_subsequence (&\@) {
  my ($criterion, $arr) = @_;
  my @ret;

  while (@$arr && do { local $_ = $arr->[0]; $criterion->() }) {
    push @ret, shift @$arr;
  }

  return @ret;
}


sub mogrify {
  my ($self, $menu, $stage, @plugins) = @_;

#  warn "$stage: ", (join ", ", map ref $_, @plugins), "\n";

  # We've got a list of plugins that are to run at this stage.
  # There are two kinds of p
  while (@plugins) {
    my @im = _remove_initial_subsequence { $_->does(rolename('ItemMogrifier')) } @plugins;
    @im = map +{
      plugin => $_,
      methods => [ $_->item_mogrify_methods ],
    }, @im;

    # Process the first method of every plugin, then the second method of every
    # plugin, then the third etc. until there are no more.
    while (@im) {
      my @actions = map +{
        plugin => $_->{plugin},
        method => shift( @{ $_->{methods} } ),
      }, @im;

      $menu = WWW::MenuGrinder::Visitor->visit_menu($menu, \@actions);

      @im = grep @{ $_->{methods} }, @im;
    }

    last unless @plugins;

    my $mogrifier = shift @plugins;

    if ($mogrifier->does(rolename('Mogrifier'))) {
        $menu = $mogrifier->mogrify($menu);
    }
  }

  return $menu;
}


sub get_menu {
  my ($self, $outputtype) = @_;

  $_->before_mogrify($self->menu) for @{ $self->plugins_with(-BeforeMogrify) };

  my $menu = $self->menu;

  $menu = $self->mogrify( $menu, 'per-request', @{ $self->per_request_plugins } );

  if (!defined $outputtype) {
    if (@{ $self->outputs } == 1) {
      return $self->outputs->[0]->output($menu);
    } else {
      return $menu;
    }
  }

  my $output = $self->outputs_by_name->{$outputtype};
  die "Output plugin $outputtype does not exist" unless defined $output;
  return $output->output($menu);
}

sub cleanup {
  my ($self, $menu) = @_;

  for my $plugin (@{ $self->plugins }) {
    $plugin->cleanup() if $plugin->can('cleanup');
  }
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;



__END__
=pod

=head1 NAME

WWW::MenuGrinder - A tool for managing dynamic website menus - base class.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  my $grinder = My::Subclass::Of::MenuGrinder->new(
    config => {
      plugins => {
        loader => 'XMLLoader',
        per_request => [
          'FileReloader',
          'HotKeys',
        ],
      },
      filename => "/foo/menu.xml"
   },
  );

  # Some time later...
  
  my $menu = $grinder->get_menu

=head1 DESCRIPTION

C<WWW::MenuGrinder> is a framework for integrating menus into web applications.

MenuGrinder provides a framework for any number of plugins (from CPAN or the
"using" application) to work with a tree structure representing a navigational
method. Plugins may perform tasks such as loading a representation of the menu
from disk, rendering the menu as HTML, conditionally displaying menu items based
on user permissions, or determining the menu item corresponding to the "current
page". MenuGrinder plugins on the CPAN may be found in the
C<WWW::MenuGrinder::Plugin::> namespace.

MenuGrinder is intended to work well within web frameworks; currently there are
glue classes for Catalyst on CPAN but it should work well within any system.

MenuGrinder uses Moose to make extending it as pleasant as possible!

=head1 METHODS

=head2 C<< $grinder->menu >>

Accessor. This is where the menu structure sits between "on load" processing and
"per-request" processing.

=head2 C<< $grinder->plugins >>

Accessor. Is an arrayref containing instances of all of the loaded plugins, in
the order they were specified in the config. More likely accessed via 
C<< $grinder->plugins_with($role) >>.

=head2 C<rolename($role)>

Utility function, maps a role name (C<Plugin>) to the corresponding class name
(C<WWW::MenuGrinder::Role::Plugin>).

=head2 C<< $grinder->plugins_with($role) >>

Returns an arrayref listing all of the registered plugin instances that
consume the named role. Accepts the short name of a role.

=head2 C<< $grinder->load_plugin($plugin) >>

Attempts to load the plugin given by C<$plugin>. If C<$plugin> begins with
C<'+'> then it is treated as a literal classname, otherwise it is prefixed with
C<WWW::MenuGrinder::Plugin::>. If the plugin is found:

=over 4

=item *

The plugin is C<require>d.

=item *

Its C<plugin_depends>, if any, are followed recursively.

=item *

The plugin is instantiated, with its config from C<< $grinder->config >> (if
any).

=item *

The plugin is asked to C<verify_plugin> itself (may throw an exception).

=item *

The plugin is added to the grinder's list of registered plugins to be returned
by C<< $grinder->plugins >> and C<< $grinder->plugins_with >>.

=item *

The plugin instance is returned.

=back

=head2 C<< $grinder->load_plugins >>

Called on grinder construction. Reads the list of plugins from the config and
attempts to load them. Throws an exception if anything seems to be amiss.

=head2 C<< $grinder->init_menu >>

Called on grinder construction.

=over 4

=item *

Invokes the C<Loader> plugin to load the menu structure.

=item *

Invokes any "on_load" plugins to make initial modifications to the menu.

=item *

Invokes the C<on_init> method of any plugins consuming the C<OnInit> role.

=back

=head2 C<< $grinder->mogrify($menu, $stage, @plugins) >>

This is the main workhorse of MenuGrinder; given the menu structure and a list
of plugins implementing C<Mogrifier> or C<ItemMogrifier> roles, it allows each
plugin in turn to make modifications to the menu. C<ItemMogrifier> plugins that
fall adjacent to each other in the plugin chain may be run together on a single
pass over the menu tree; to avoid this behavior separate the C<ItemMogrifier>
plugins by a C<Mogrifier> plugin, perhaps the no-op
L<WWW::MenuGrinder::Plugin::NullTransform>.

=head2 C<< $grinder->get_menu( [ $type ] ) >>

Invokes all "per_request" plugins to modify a copy of the menu structure,
possibly filters the menu through an C<Output> plugin, then returns the result.
The heuristic for choosing an output is slightly complex:

=over 4

=item *

If the C<$type> argument is provided then it is taken to be the name of the
output plugin to use. If C<$type> doesn't correspond to the name of a loaded
C<Output> plugin an error occurs.

=item *

If the C<$type> argument is not provided and there is exactly one loaded
C<Output> plugin, that plugin is used.

=item *

Otherwise, the menu is returned unmodified.

=back

=head1 WARNING

Currently this is B<alpha code>. I welcome any opinions, ideas for extensions,
new plugins, etc. However, documentation is incomplete, tests are nonexistent,
and interfaces are subject to change. B<don't use this in production> unless
you want to get yourself in deep.

=head1 SEE ALSO

=over 4

=item *

L<WWW::MenuGrinder::Extending> for the best current documentation of internals.

=item *

C<t/MyApp/> in L<Catalyst::Model::MenuGrinder> for an example of MenuGrinder
in use.

=item *

The documentation for each individual plugin, for an idea of the kinds of
things that are possible.

=item *

L<http://github.com/arodland/www-menugrinder/> for the latest code, and change
history.

=item *

C<hobbs> on C<irc.perl.org>. I can be found in C<#catalyst> but private
messages are okay to avoid off-topicness.

=back

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

