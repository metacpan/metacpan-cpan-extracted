package UR::Namespace::Command::Sys::ClassBrowser;

# This turns on the perl stuff to insert data in the DB
# namespace so we can get line numbers and stuff about
# loaded modules
BEGIN {
   unless ($^P) {
       no strict 'refs';
       *DB::DB = sub {};
       $^P = 0x31f;
   }
}

use strict;
use warnings;
use UR;
use Data::Dumper;
use File::Spec;
use File::Basename;
use IO::File;
use Template;
use Plack::Request;
use Class::Inspector;

our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has_optional => [
        generate_cache  => { is => 'Boolean', default_value => 0, doc => 'Generate the class cache file' },
        use_cache       => { is => 'Boolean', default_value => 1, doc => 'Use the class cache instead of scanning for modules'},
        port            => { is => 'Integer', default_value => 8080, doc => 'TCP port to listen for connections' },
        timeout         => { is => 'Integer', doc => 'If specified, exit after this many minutes of inactivity' },
        host            => { is => 'String', default_value => 'localhost', doc => 'host to listen on for connections' },
    ],
);

sub is_sub_command_delegator { 0;}

sub help_brief {
    "Start a web server to browse through the class structure.";
}

sub help_synopsis {
  q(# Start the web server
# By default, only connections from localhost are accepted
ur sys class-browser

# Start the server and accept connections from any
# address, not just localhost
ur sys class-browser --host 0

# Create the cache file for the current namespace
ur sys class-browser --generate-cache);
}

sub help_detail {
    q(The class-browser command starts an embedded web server containing an app for
browsing through the class structure.  After starting, it prints a URL on
STDOUT that can be copy-and-pasted into a browser to run the app.);
}

sub _class_info_cache_file_name_for_namespace {
    my($self, $namespace) = @_;
    unless ($INC{$namespace.'.pm'}) {
        eval "use $namespace";
        die $@ if $@;
    }
    my $class_cache_file = sprintf('.%s-class-browser-cache', $namespace);
    return File::Spec->catfile($namespace->get_base_directory_name, $class_cache_file);
}


sub load_class_info_for_namespace {
    my($self, $namespace) = @_;

    my $class_cache_file = $self->_class_info_cache_file_name_for_namespace($namespace);
    if ($self->use_cache and -f $class_cache_file) {
        $self->_load_class_info_from_cache_file($namespace, $class_cache_file);
    } else {
        $self->status_message("Preloading class information for namespace $namespace...");
        $self->_load_class_info_from_modules_on_filesystem($namespace);
    }
}

sub _write_class_info_to_cache_file {
    my $self = shift;

    my $current_namespace = $self->namespace_name;
    return unless ($self->{_cache}->{$current_namespace});

    my $cache_file = $self->_class_info_cache_file_name_for_namespace($current_namespace);
    my $fh = IO::File->new($cache_file, 'w') || die "Can't open $cache_file for writing: $!";

    $fh->print( Data::Dumper->new([$self->{_cache}->{$current_namespace}], ['cache_data'])->Sortkeys(1)->Purity(1)->Dump );
    $fh->close();
    $self->status_message("Saved class info to cache file $cache_file");
}


sub _load_class_info_from_cache_file {
    my($self, $namespace, $class_cache_file) = @_;

    return 1 if ($self->{_cache}->{$namespace});  # Don't load same namespace more than once

    $self->status_message("Loading class info cache file $class_cache_file\n");
    my $fh = IO::File->new($class_cache_file, 'r');
    unless ($fh) {
        $self->error_message("Cannot load class cache file $class_cache_file: $!");
        return;
    }

    my $buf;
    {   local $/;
        $buf = <$fh>;
    }
    my $cache_data;
    eval $buf;
    $self->{_cache}->{$namespace} = $cache_data;
}

sub _load_class_info_from_modules_on_filesystem {
    my $self = shift;
    my $namespace = shift;

    return 1 if ($self->{_cache}->{$namespace});  # Don't load same namespace more than once

    my $by_class_name = $self->{_cache}->{$namespace}->{by_class_name}
                        ||= $self->_generate_class_name_cache($namespace);

    unless ($self->name_tree_cache($namespace)) {
        $self->name_tree_cache( $namespace,
                                UR::Namespace::Command::Sys::ClassBrowser::TreeItem->new(
                                    name => $namespace,
                                    relpath => $namespace.'.pm'));
    }
    unless ($self->inheritance_tree_cache($namespace)) {
        $self->inheritance_tree_cache( $namespace,
                                UR::Namespace::Command::Sys::ClassBrowser::TreeItem->new(
                                    name => 'UR::Object',
                                    relpath => 'UR::Object'));
    }
    unless ($self->directory_tree_cache($namespace)) {
        $self->directory_tree_cache($namespace,
                                UR::Namespace::Command::Sys::ClassBrowser::TreeItem->new(
                                    name => $namespace,
                                    relpath => $namespace.'.pm' ));
    }
    my $inh_inserter = $self->_class_inheritance_cache_inserter($by_class_name, $self->inheritance_tree_cache($namespace));
    foreach my $data ( values %$by_class_name ) {
        $self->_insert_cache_for_class_name_tree($data);
        $self->_insert_cache_for_path($data);
        $inh_inserter->($data->{name});
    }
    1;
}

foreach my $cache ( [ 'by_class_name_tree', 'name_tree_cache'],
                    [ 'by_class_inh_tree',  'inheritance_tree_cache'],
                    [ 'by_directory_tree',  'directory_tree_cache'] ) {
    my $key = $cache->[0];
    my $subname = $cache->[1];
    my $sub = sub {
        my $self = shift;
        my $namespace = shift;
        unless (defined $namespace) {
            Carp::croak "\$namespace is a required argument";
        }
        if (@_) {
            $self->{_cache}->{$namespace}->{$key} = shift;
        }
        return $self->{_cache}->{$namespace}->{$key};
    };
    Sub::Install::install_sub({
        into => __PACKAGE__,
        as => $subname,
        code => $sub,
    });
}


sub _namespace_for_class_name {
    my($self, $class_name) = @_;
    return ($class_name =~ m/^(\w+)(::)?/)[0];
}

sub _cached_data_for_class {
    my($self, $class_name) = @_;

    my $namespace = $self->_namespace_for_class_name($class_name);
    return $self->{_cache}->{$namespace}->{by_class_name}->{$class_name};
}

# 1-level hash.  Maps a class name to a hashref containing simple
# data about that class.  relpath is relative to the namespace's module_path
sub _generate_class_name_cache {
    my($self, $namespace) = @_;

    my $cwd = Cwd::getcwd . '/';
    my $namespace_meta = $namespace->__meta__;
    my $namespace_dir = $namespace_meta->module_directory;
    (my $path = $namespace_meta->module_path) =~ s/^$cwd//;
    my $by_class_name = {  $namespace => {
                                name  => $namespace,
                                is    => $namespace_meta->is,
                                relpath  => $namespace . '.pm',
                                id  => $path,
                                file => File::Basename::basename($path),
                            }
                        };
    foreach my $class_meta ( $namespace->get_material_classes ) {
        my $class_name = $class_meta->class_name;
        $by_class_name->{$class_name} = $self->_class_name_cache_data_for_class_name($class_name);
    }
    return $by_class_name;
}

sub _class_name_cache_data_for_class_name {
    my($self, $class_name) = @_;

    my $class_meta = $class_name->__meta__;
    unless ($class_meta) {
        Carp::carp("Can't get class metadata for $class_name... skipping.");
        return;
    }
    my $namespace_dir = $class_meta->namespace->__meta__->module_directory;
    my $module_path = $class_meta->module_path;
    (my $relpath = $module_path) =~ s/^$namespace_dir//;
    return {
        name    => $class_meta->class_name,
        relpath => $relpath,
        file    => File::Basename::basename($relpath),
        is      => $class_meta->is,
    };
}

# Build the by-class-name tree data
sub _insert_cache_for_class_name_tree {
    my($self, $data) = @_;

    my $namespace = $self->_namespace_for_class_name($data->{name});
    my $tree = $self->name_tree_cache($namespace);
    my @names = split('::', $data->{name});
    my $relpath = shift @names;  # Namespace is first part of the name
    while(my $name = shift @names) {
        $relpath = join('::', $relpath, $name);
        $tree = $tree->get_child($name)
                    || $tree->add_child(
                        name        => $name,
                        relpath     => $relpath);
    }
    $tree->data($data);
    return $tree;
}

# Build the by_directory_tree data
sub _insert_cache_for_path {
    my($self, $data) = @_;

    my $namespace = $self->_namespace_for_class_name($data->{name});
    my $tree = $self->directory_tree_cache($namespace);

    # split up the path to the module relative to the namespace directory
    my @path_parts = File::Spec->splitdir($data->{relpath});
    shift @path_parts if $path_parts[0] eq '.';  # remove . at the start of the path

    my $partial_path = shift @path_parts;
    while (my $subdir = shift @path_parts) {
        $partial_path = join('/', $partial_path, $subdir);
        $tree = $tree->get_child($subdir)
                    || $tree->add_child(
                            name    => $subdir,
                            relpath => $partial_path);
    }
    $tree->data($data);
    return $tree;
}

sub _cache_has_data_for {
    my($self, $namespace) = @_;
    return exists($self->{_cache}->{$namespace});
}


# build the by_class_inh_tree data
sub _class_inheritance_cache_inserter {
    my($self, $by_class_name, $tree) = @_;

    my $cache = $tree ? { $tree->name => $tree } : {};

    my $do_insert;
    $do_insert = sub {
        my $class_name = shift;

        $by_class_name->{$class_name} ||= $self->_class_name_cache_data_for_class_name($class_name);
        my $data = $by_class_name->{$class_name};

        if ($cache->{$class_name}) {
            return $cache->{$class_name};
        }
        my $node = UR::Namespace::Command::Sys::ClassBrowser::TreeItem->new(
                    name => $class_name, data => $data
                );
        $cache->{$class_name} = $node;

        if ((! $data->{is}) || (! @{ $data->{is}} )) {
            # no parents?!  This _is_ the root!
            return $tree = $node;
        }
        foreach my $parent_class ( @{ $data->{is}} ) {
            my $parent_class_tree = $do_insert->($parent_class);
            unless ($parent_class_tree->has_child($class_name)) {
                $parent_class_tree->add_child( $node );
            }
        }
        return $node;
    };

    return $do_insert;
}


sub execute {
    my $self = shift;

    if ($self->generate_cache) {
        $self->_load_class_info_from_modules_on_filesystem($self->namespace_name);
        $self->_write_class_info_to_cache_file();
        return 1;
    }

    $self->load_class_info_for_namespace($self->namespace_name);

    my $tt = $self->{_tt} ||= Template->new({ INCLUDE_PATH => $self->_template_dir, RECURSION => 1 });

    my $server = UR::Service::WebServer->create(timeout => $self->timeout,
                                                host => $self->host,
                                                port => $self->port);

    my $router = UR::Service::UrlRouter->create( verbose => $self->verbose);
    my $assets_dir = $self->__meta__->module_data_subdirectory.'/assets/';
    $router->GET(qr(/assets/(.*)), $server->file_handler_for_directory( $assets_dir));
    $router->GET('/', sub { $self->index(@_) });
    $router->GET(qr(/detail-for-class/(.*)), sub { $self->detail_for_class(@_) });
    $router->GET(qr(/search-for-class/(.*)), sub { $self->search_for_class(@_) });
    $router->GET(qr(/render-perl-module/(.*)), sub { $self->render_perl_module(@_) });
    $router->GET(qr(/property-metadata-list/(.*)/(\w+)), sub { $self->property_metadata_list(@_) });

    $server->cb($router);
    $server->run();

    return 1;
}

sub _template_dir {
    my $self = shift;
    return $self->__meta__->module_data_subdirectory();
}

sub index {
    my $self = shift;
    my $env = shift;

    my $req = Plack::Request->new($env);
    my $namespace = $req->param('namespace') || $self->namespace_name;

    unless ($self->_cache_has_data_for($namespace)) {
        $self->load_class_info_for_namespace($namespace);
    }
    my $data = {
        current_namespace => $namespace,
        namespaces  => [ map { $_->id } UR::Namespace->is_loaded() ],
        classnames  => $self->name_tree_cache($namespace),
        inheritance => $self->inheritance_tree_cache($namespace),
        paths       => $self->directory_tree_cache($namespace),
    };

    return $self->_process_template('class-browser.html', $data);
}

sub _process_template {
    my($self, $template_name, $template_data) = @_;

    my $out = '';
    my $tmpl = $self->{_tt};
    $tmpl->process($template_name, $template_data, \$out)
        and return [ 200, [ 'Content-Type' => 'text/html' ], [ $out ]];

    # Template error :(
    $self->error_message("Template failed: ".$tmpl->error);
    return [ 500, [ 'Content-Type' => 'text/plain' ], [ 'Template failed', $tmpl->error ]];
}

sub _fourohfour {
    return [ 404, [ 'Content-Type' => 'text/plain' ], ['Not Found']];
}

sub _line_for_function {
    my($self, $name) = @_;
    my $info = $DB::sub{$name};

    return () unless $info;
    my ($file,$start);
    if ($info =~ m/\[(.*?):(\d+)\]/) {  # This should match eval's and __ANON__s
        ($file,$start) = ($1,$2);

    } elsif ($info =~ m/(.*?):(\d+)-(\d+)$/) {
        ($file,$start) = ($1,$2);

    }

    if ($start) {
        # Convert $file into a package name
        foreach my $inc ( keys %INC ) {
            if ($INC{$inc} eq $file) {
                (my $pkg = $inc) =~ s/\//::/g;
                $pkg =~ s/\.pm$//;
                return (package => $pkg, line => $start);
            }
        }
    }
    return;
}

# Return a list of package names where $method is defined
sub _overrides_for_method {
    my($self, $class, $method) = @_;

    my %seen;
    my @results;
    my @isa = ($class);
    while (my $target_class = shift @isa) {
        next if $seen{$target_class}++;
        if (Class::Inspector->function_exists($target_class, $method)) {
            push @results, $target_class;
        }
        {   no strict 'vars';
            push @isa, eval '@' . $target_class . '::ISA';
        }
    }
    return \@results;
}

sub detail_for_class {
    my $self = shift;
    my $env = shift;
    my $class = shift;

    my $class_meta = eval { $class->__meta__};

    my $tree = UR::Namespace::Command::Sys::ClassBrowser::TreeItem->new(
                                name => 'UR::Object',
                                relpath => 'UR::Object');

    my $namespace = $class_meta->namespace;
    my $treebuilder = $self->_class_inheritance_cache_inserter(
                            $self->{_cache}->{$namespace}->{by_class_name},
                            $tree,
                    );
    $treebuilder->($class);

    unless ($class_meta) {
        return $self->_fourohfour;
    }

    my @public_methods = sort { $a->[2] cmp $b->[2] }  # sort by function name
                        @{ Class::Inspector->methods($class, 'public', 'expanded') };
    my @private_methods = sort { $a->[2] cmp $b->[2] }  # sort by function name
                        @{ Class::Inspector->methods($class, 'private', 'expanded') };

    # Convert each of them to a hashref for easier access
    foreach ( @public_methods, @private_methods ) {
        my $class = $_->[1];
        my $method = $_->[2];
        my $function = $_->[0];
        my $cache = $self->_cached_data_for_class($class);
        $_ = {
            class       => $class,
            method      => $method,
            file        => $cache->{relpath},
            overrides   => $self->_overrides_for_method($class, $method),
            $self->_line_for_function($function),
        };
    }

    my @sorted_properties = sort { $a->property_name cmp $b->property_name }
                            $class_meta->properties;

    my $tmpl_data = {
        meta                    => $class_meta,
        property_metas          => \@sorted_properties,
        class_inheritance_tree  => $tree,
        public_methods          => \@public_methods,
        private_methods         => \@private_methods,
    };
    return $self->_process_template('class-detail.html', $tmpl_data);
}

sub search_for_class {
    my $self = shift;
    my $env = shift;
    my $search = shift;

    my $req = Plack::Request->new($env);
    my $namespace = $req->param('namespace') || $self->namespace_name;

    my $class_cache = $self->{_cache}->{$namespace}->{by_class_name};
    my @results = sort
                  grep { m/$search/i } keys %$class_cache;

    if (@results == 1) {
        return $self->detail_for_class($env, $results[0]);
    } else {
        return $self->_process_template('search_results.html',
                                        { search => $search, classes => \@results });
    }
}

sub render_perl_module {
    my($self, $env, $module_name) = @_;

    my $module_path;
    if (my $class_meta = eval { $module_name->__meta__ }) {
        $module_path = $class_meta->module_path;

    } else {
        ($module_path = $module_name) =~ s/::/\//g;
        $module_path = $INC{$module_path.'.pm'};
    }
    unless ($module_path and -f $module_path) {
        return $self->_fourohfour;
    }

    my $fh = IO::File->new($module_path, 'r');
    my @lines = <$fh>;
    chomp(@lines);
    return $self->_process_template('render-perl-module.html', { module_name => $module_name, lines => \@lines });
}

# Render the popover content when hovering over a row in the
# class property table
sub property_metadata_list {
    my($self, $env, $class_name, $property_name) = @_;

    my $class_meta = $class_name->__meta__;
    unless ($class_meta) {
        return $self->_fourohfour;
    }
    my $prop_meta = $class_meta->property_meta_for_name($property_name);
    unless ($prop_meta) {
        return $self->_fourohfour;
    }

    return $self->_process_template('partials/property_metadata_list.html',
                    { meta => $prop_meta,
                      show => [qw(  doc class_name column_name data_type data_length is_id
                                    via to where reverse_as id_by
                                    valid_values example_values  is_optional is_transient is_constant
                                    is_mutable is_delegated is_abstract is_many is_deprecated
                                    is_calculated calculate_perl calculate_sql
                                )],
                    });
}


package UR::Namespace::Command::Sys::ClassBrowser::TreeItem;

sub new {
    my $class = shift;
    my %node = @_;
    die "new() requires a 'name' parameter" unless (exists $node{name});

    $node{children} = {};
    unless (defined $node{id}) {
        ($node{id} = $node{name}) =~ s/::/__/g;
    }
    my $self = bless \%node, __PACKAGE__;
    return $self;
}

sub id {
    return shift->{id};
}

sub name {
    return shift->{name};
}

sub relpath {
    return shift->{relpath};
}

sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = shift;
    }
    return $self->{data};
}

sub has_children {
    my $self = shift;
    return %{$self->{children}};
}

sub children {
    my $self = shift;
    return [ values(%{$self->{children}}) ];
}

sub has_child {
    my $self = shift;
    my $child_name = shift;
    return exists($self->{children}->{$child_name});
}

sub get_child {
    my $self = shift;
    my $child_name = shift;
    return $self->{children}->{$child_name};
}

sub add_child {
    my $self = shift;
    my $child = ref($_[0]) ? shift(@_) : $self->new(@_);
    $self->{children}->{ $child->name } = $child;
}


1;

=pod

=head1 NAME

UR::Namespace::Command::Sys::ClassBrowser - WebApp for browsing the class structure

=head1 SYNOPSIS

  # Start the web server
  ur sys class-browser

  # Create the cache file for the current namespace
  ur sys class-browser --generate-cache

=head1 DESCRIPTION

The class-browser command starts an embedded web server containing an app for
browsing through the class structure.  After starting, it prints a URL on
STDOUT that can be copy-and-pasted into a browser to run the app.

=head1 COMMAND-LINE OPTIONS

With no options, the command expects to be run within a Namespace directory.
It will auto-discover all the classes in the Namespace, either from a
previously created cache file, or by scanning all the perl modules within the
Namespace's subdirectory.

=over 4

=item --generate-cache

Instead of starting a web server, the command will scan for all perl modules
within the Namespace's subdirectory and create a file called
.<namespace>-class-browser-cache, then exit.  This file will contain
information about all the classes it found, which will improve the start-up
time the next time the command is run.

=item --port <port>

Change the TCP port the web server listens on.  The default is 8080.

=item --nouse-cache

The command will use the cache file generated by the --generate-cache option
if it finds one.  When --nouse-cache is used, it will always scan for perl
modules, and will ignore any cache that may be present.

=item --verbose

Causes the command to print the STDOUT the URLs loaded while it is running.

=back

=head1 SEE ALSO

L<UR>, L<UR::Object::Type>, L<UR::Service::WebServer>

=cut
