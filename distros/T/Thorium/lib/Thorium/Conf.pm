package Thorium::Conf;
{
  $Thorium::Conf::VERSION = '0.510';
}
BEGIN {
  $Thorium::Conf::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Configuration class

use Thorium::Protection;

use Moose;

# Roles
with qw(Thorium::Roles::Logging);

# core
use File::Spec;

# CPAN
use Hash::Merge::Simple qw();
use YAML::XS qw();

# Attributes
has '_conf_data' => (
    'is'            => 'rw',
    'isa'           => 'HashRef',
    'lazy'          => 1,
    'builder'       => '_build_conf_data',
    'documentation' => 'Configuration data.'
);

has '_load_order' => (
    'is'            => 'ro',
    'isa'           => 'ArrayRef',
    'default'       => sub { [qw(global system component env_var from)] },
    'documentation' => 'Order files are loaded in. Right item overrides its leftmost item.'
);

has '_system_directory_root' => (
    'is'            => 'ro',
    'isa'           => 'Str',
    'default'       => '/etc/thorium/conf',
    'documentation' => 'Directory root where global files are located. Changing this is not recommended.'
);

has '_local_file_name' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'default' => 'local.yaml'
);

has 'component_name' => (
    'is'  => 'ro',
    'isa' => 'Maybe[Str]',
    'documentation' =>
      'File name base that might be stored in the _system_directory_root. When extending please provide this.'
);

has 'global' => (
    'is'            => 'ro',
    'isa'           => 'Maybe[Str]',
    'lazy'          => 1,
    'builder'       => '_build_global',
    'documentation' => 'Global configuration file read by all configuration objects.'
);

has 'system' => (
    'is'            => 'ro',
    'isa'           => 'Maybe[Str]',
    'lazy'          => 1,
    'builder'       => '_build_system',
    'documentation' => 'Full path to the components system wide file.'
);

has 'component_root' => (
    'is'            => 'rw',
    'isa'           => 'Str',
    'documentation' => 'Component specific root directory to read from.'
);

has 'component' => (
    'is'            => 'ro',
    'isa'           => 'Maybe[Str|ArrayRef]',
    'lazy'          => 1,
    'builder'       => '_build_component',
    'documentation' => 'Component specific file(s) to read from. Extended classes should set this.'
);

has 'env_var' => (
    'is'            => 'ro',
    'isa'           => 'Maybe[Str]',
    'lazy'          => 1,
    'builder'       => '_build_env_var',
    'documentation' => 'Full path to the environmental set file.'
);

has 'env_var_name' => (
    'is'            => 'ro',
    'isa'           => 'Maybe[Str]',
    'default'       => 'THORIUM_CONF_FILE',
    'documentation' => 'Name of the environment variable.'
);

has 'from' => (
    'is'            => 'rw',
    'isa'           => 'Maybe[Str|ArrayRef]',
    'documentation' => 'A string or list containing the full path of files to read from.'
);

# Builders: subclass modifiable defaults - these aren't called if a value is provided
sub _build_conf_data {
    my ($self) = @_;

    my $data = {};

    # we read configuration information in a set order
    foreach my $attrib (@{$self->_load_order}) {

        my $path = $self->$attrib;

        next unless ($path);

        $self->log->debug('Reading files from ', (ref($path) eq 'ARRAY') ? join(', ', @{$path}) : $path,
            " for $attrib");

        my @files = ();

        # if path is an arrayref, it better contain a list of files
        if (ref($path) eq 'ARRAY') {
            @files = @{$path};
        }
        elsif (-d -r $path) {
            $self->log->warn("$path is a directory, please specify files");
            next;
        }
        elsif ($path =~ /\.yaml$/ && -r $path) {
            push(@files, $path);
        }

        next unless (@files);

        # now that we have a list of (hopefully) yaml files, lets read them in
        foreach my $file (@files) {

            $self->log->trace("Loading conf from $file");

            $data = Hash::Merge::Simple::merge($data, YAML::XS::LoadFile($file));

            unless (ref($data) eq 'HASH') {
                $self->log->error("Failed to load $file because... $_");
                die "Failed to load $file because... $_";
            }
        }
    }

    return $data;
}

sub _build_global {
    my ($self) = @_;

    my $filepath = File::Spec->catfile($self->_system_directory_root, 'thorium.yaml');

    if (-e -r -s $filepath) {
        return $filepath;
    }

    return;
}

sub _build_system {
    my ($self) = @_;

    return unless ($self->component_name);

    my $filepath = File::Spec->catfile($self->_system_directory_root, $self->component_name . '.yaml');

    if (-e -r -s $filepath) {
        return $filepath;
    }

    return;
}

sub _build_component {
    my ($self) = @_;

    my @files;

    my $defaults_config = File::Spec->catfile($self->component_root, 'conf', 'presets', 'defaults.yaml');

    if (-e -r -s $defaults_config) {
        push(@files, $defaults_config);
    }

    my $preset_config = File::Spec->catfile($self->component_root, 'conf', $self->_local_file_name);

    if (-e -r -s $preset_config) {
        push(@files, $preset_config);
    }

    return \@files;
}

sub _build_env_var {
    my ($self) = @_;

    if (exists($ENV{$self->env_var_name})) {
        my $filepath = File::Spec->catfile($ENV{$self->env_var_name});

        if (-e -r -s $filepath) {
            return $filepath;
        }
    }

    return;
}

# Methods
sub data {
    my ($self, $key) = @_;

    my $retdata;

    if (defined $key && $key =~ /\.\./) {
        $self->log->error("Keys are '.' separated. Key supplied contains a null member (..)");
        die "Keys are '.' separated. Key supplied ($key) contains a null member (..)";
    }

    # Start with the top level
    my $data = $self->_conf_data();

    # if no key was supplied, the user wants everything
    return $data
      unless (defined($key));

    $retdata = $data;

    # Descend into the data structure and return whatever we find
    # NOTE: We only support lookups down the tree for hashes, until we discover
    # a use case for something more complex
    foreach my $key_section (split('\.', $key)) {
        if (ref($retdata) ne 'HASH') {
            $self->log->error("Can not look up key '$key_section' in non-hashref data '$retdata'");
            die "Can not look up key '$key_section' in non-hashref data '$data'";
        }

        unless (exists($retdata->{$key_section})) {
            $self->log->error("Nonexistent config value. Died on '$key_section' in '$key'");
            die "Nonexistent config value. Died on '$key_section' in '$key'";
        }

        $retdata = $retdata->{$key_section};
    }

    # The deepest value the key dictated
    return $retdata;
}

# The first request for data will do this, but maybe we want to have it happen
# at a certain point before then (testing for example)
sub load_conf {
    my ($self) = @_;

    $self->_conf_data();

    return 1;
}

sub set {
    my ($self, $key, $value) = @_;

    my $data = $self->data;

    my @nodes = ($key);

    if ($key =~ /\./) {
        @nodes = split(qr(\.), $key);
    }

    my $current_node = $data;

    my $ret = 0;

    foreach my $node (@nodes) {
        if (exists($current_node->{$node})) {
            unless (ref($current_node->{$node})) {
                $current_node->{$node} = $value;
                $self->log->trace("Setting $node to $value");
                $ret = 1;
                last;
            }
        }
        $current_node = $current_node->{$node};
    }

    return $ret;
}

sub save {
    my ($self, $filename) = @_;

    my $data = $self->data;

    my $files_wrote = 0;

    if (YAML::XS::DumpFile($filename, $data)) {
        $files_wrote++;
        $self->log->debug("Saved $filename");
    }
    else {
        my $msg = "Failed to save $filename";
        $self->log->error($msg);
        die("$msg\n");
    }

    return $files_wrote;
}

sub reload {
    my ($self) = @_;

    my @files = map {
        if ($self->$_) {
            (ref($self->$_) eq 'ARRAY') ? @{$self->$_} : $self->$_;
        }
    } (@{$self->_load_order});

    @files = grep { defined($_) && -e -r -s $_ } @files;

    $self->log->debug('Reloading configuration from ', join(', ', @files));

    my $data = $self->_conf_data;

    $data = undef;

    $self->_conf_data({});

    return $self->_conf_data($self->_build_conf_data());
}

sub _delete_local {
    my ($self) = @_;

    my $local_data = File::Spec->catfile($self->component_root, 'conf', $self->_local_file_name);

    if (-e -r -f $local_data) {
        unlink($local_data);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Thorium::Conf - Configuration class

=head1 VERSION

version 0.510

=head1 SYNOPSIS

Extending:

    package Some::App::Conf;

    use Moose;

    extends 'Thorium::Conf';

    has '+component_name' => ('default' => 'someapp');
    has '+component' => ('default' => [ '/file1.yaml', '/file2.yaml' ]);

    1;

But you may also use it directly:

    use Thorium::Conf;

    my $conf = Thorium::Conf->new('from' => '/that/app.yaml');

    print $conf->data('some.key');

    ...

=head1 DESCRIPTION

Thorium::Conf is an extendable class for handling configuration data in YAML
L<http://yaml.org> format through L<YAML::XS>.

Data is accessed through a string interface that maps directly to the key names
of a hash. Data is loaded in the order of (first to last): global, system,
component, env_var, from. With each overriding data from the previous,
e.g. component's a key would override systems's a key. All data is marked
read-only to prevent accidental modification, but there is an interface to
control this.

In nearly all cases you should sub-class and override the C<component_name> and
C<component> attributes. See the L<"SYNOPSIS"> for an example. C<component> maps
to the base file name that will be found in the C<system> location (as set by
C<_system_directory_root>). Therefore, if your component name is C<someapp>,
then you'd expect the system wide file to reside in
F</etc/thorium/conf/someapp.yaml>.

F</etc/thorium/conf/thorium.yaml> is the universally global file all
L<Thorium::Conf> and sub-classed objects read (when it exists).

=head1 ROLES

L<Thorium::Roles::Logging>

=head1 ATTRIBUTES

=head2 Optional Attributes

=over

=item * B<_system_directory_root> (ro, Str) - Directory root where global files
are located. Changing this is not recommended. Defaults to '/etc/thorium/conf'.

=item * B<component> (ro, Maybe[ArrayRef|Str]) - Component specific file(s) to
read from. Extended classes should set this.

=item * B<component_name> (ro, Str) - File name base that might be stored in the
_system_directory_root. When extending please provide this.

=item * B<env_var> (ro, Maybe[Str]) - Full path to the environmental set file.

=item * B<env_var_name> (ro, Maybe[Str]) - Name of the environment
variable. Defaults to 'THORIUM_CONF_FILE'.

=item * B<from> (ro, Maybe[ArrayRef|Str]) - A string or list containing the full
path of files to read from.

=item * B<global> (ro, Maybe[Str]) - Global configuration file read by all
configuration objects. Defaults to '/etc/thorium/conf/thorium.yaml'.

=item * B<system> (ro, Maybe[Str]) - Full path to the components system wide file.

=back

=head1 PUBLIC API METHODS

=over

=item * B<data([ $key ])>

If C<$key> is specified, return that specific data, otherwise return all data.

Note: by default all configuration data is marked read only and can not be
changed.

=item * B<reload()>

Re-reads all data from files.

=item * B<save($filename)>

Writes the data to the full file path from $filename.

=item * B<set($key, $value)>

Change $key to $value. $key is the same format as C<data()>.

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

