# Manage dynamic configuration of modules.

package UR::ModuleConfig;

=pod

=head1 NAME

UR::ModuleConfig - manage dynamic configuration of modules.

=head1 SYNOPSIS

  package MyModule;
  use base qw(UR::ModuleConfig);

  MyModule->config(%conf);
  $val = MyModule->config('key');
  %conf = MyModule->config;

=head1 DESCRIPTION

This module manages the configuration for modules.  Configurations can
be read from files or set dynamically.  Modules wishing to use the
configuration methods should inherit from the module.

=cut

# set up package
require 5.006_000;
use warnings;
use strict;
require UR;
our $VERSION = "0.47"; # UR $VERSION;
use base qw(UR::ModuleBase);
use IO::File;

=pod

=head2 METHODS

The methods deal with managing configuration.

=cut

# hash containing all configuration information
our %config;

# create a combined configuration hash from inheritance tree
sub _inherit_config
{
    my $self = shift;
    my $class = ref($self) || $self;

    my %cfg;

    # get all packages inherited from
    my @inheritance = $self->inheritance;

    # reverse loop through inheritance tree and construct config
    foreach my $cls (reverse(@inheritance))
    {
        if (exists($config{$cls}))
        {
            # add hash, overriding previous values
            %cfg = (%cfg, %{$config{$cls}});
        }
    }

    # now add the current class config
    if (exists($config{$class}))
    {
        %cfg = (%cfg, %{$config{$class}});
    }

    # now add the object config
    if (ref($self))
    {
        # add the objects config
        if (exists($config{"$class;$self"}))
        {
            %cfg = (%cfg, %{$config{"$class;$self"}});
        }
    }

    return %cfg;
}

=pod

=over 4

=item config

  MyModule->config(%config);
  $val = MyModule->config('key');
  %conf = MyModule->config;

  my $obj = MyModule->new;
  $obj->config(%config);

This method can be called three ways, as either a class or object
method.  The first method takes a hash as its argument and sets the
configuration parameters given in the hash.  The second method takes a
single argument which should be one of the keys of the hash that set
the config parameters and returns the value of that config hash key.
The final method takes no arguments and returns the entire
configuration hash.

When called as an object method, the config for both the object and
all classes in its inheritance hierarchy are referenced, with the
object config taking precedence over class methods and class methods
closer to the object (first in the @ISA array) taking precedence over
those further away (later in the @ISA array).  When called as a class
method, the same procedure is used, except no object configuration is
referenced.

Do not use configuration keys that begin with an underscore (C<_>).
These are reserved for internal use.

=back

=cut

sub config
{
    my $self = shift;
    my $class = ref($self) || $self;

    # handle both object and class configuration
    my $target;
    if (ref($self))
    {
        # object config
        $target = "$class;$self";
    }
    else
    {
        # class config
        $target = $self;
    }

    # lay claim to the modules configuration
    $config{$target}{_Manager} = __PACKAGE__;

    # see if values are being set
    if (@_ > 1)
    {
        # set values in config hash, overriding any current values
        my (%opts) = @_;
        %{$config{$target}} = (%{$config{$target}}, %opts);
        return 1;
    }
    # else they want one key or the whole hash

    # store config for object and inheritance tree
    my %cfg = $self->_inherit_config;

    # see how we were called
    if (@_ == 1)
    {
        # return value of key
        my ($key) = @_;
        # make sure hash key exists
        my $val;
        if (exists($cfg{$key}))
        {
            $self->debug_message("config key $key exists");
            $val = $cfg{$key};
        }
        else
        {
            $self->error_message("config key $key does not exist");
            return;
        }
        return $val;
    }
    # else return the entire config hash
    return %cfg;
}

=pod

=over 4

=item check_config

  $obj->check_config($key);

This method checks to see if a value is set.  Unlike config, it does
not issue a warning if the key is not set.  If the key is not set,
C<undef> is returned.  If the key has been set, the value of the key
is returned (which may be C<undef>).

=back

=cut

sub check_config
{
    my $self = shift;

    my ($key) = @_;

    # get config for inheritance tree
    my %cfg = $self->_inherit_config;

    if (exists($cfg{$key}))
    {
        $self->debug_message("configuration key $key set: $cfg{$key}");
        return $cfg{$key};
    }
    # else
    $self->debug_message("configuration key $key not set");
    return;
}

=pod

=over 4

=item default_config

  $class->default_config(%defaults);

This method allows the developer to set configuration values, only if
they are not already set.

=back

=cut

sub default_config
{
    my $self = shift;

    my (%opts) = @_;

    # get config for inheritance tree
    my %cfg = $self->_inherit_config;

    # loop through arguments
    while (my ($k, $v) = each(%opts))
    {
        # see is config value is already set
        if (exists($cfg{$k}))
        {
            $self->debug_message("config $k already set");
            next;
        }
        $self->debug_message("setting default for $k");

        # set config key
        $self->config($k => $v);
    }

    return 1;
}

=pod

=over 4

=item config_file

  $rv = $class->config_file(path => $path);
  $rv = $class->config_file(handle => $fh);

This method reads in the given file and expects key-value pairs, one
per line.  The key and value should be separated by an equal sign,
C<=>, with optional surrounding space.  It currently only handles
single value values.

The method returns true upon success, C<undef> on failure.

=back

=cut

sub config_file
{
    my $self = shift;

    my (%opts) = @_;

    my $fh;
    if ($opts{path})
    {
        # make sure file is ok
        if (-f $opts{path})
        {
            $self->debug_message("config file exists: $opts{path}");
        }
        else
        {
            $self->error_message("config file does not exist: $opts{path}");
            return;
        }
        if (-r $opts{path})
        {
            $self->debug_message("config file is readable: $opts{path}");
        }
        else
        {
            $self->error_message("config file is not readable: $opts{path}");
            return;
        }

        # open file
        $fh = IO::File->new("<$opts{path}");
        if (defined($fh))
        {
            $self->debug_message("opened config file for reading: $opts{path}");
        }
        else
        {
            $self->error_message("failed to open config file for reading: "
                                 . $opts{path});
            return;
        }
    }
    elsif ($opts{handle})
    {
        $fh = $opts{handle};
    }
    else
    {
        $self->error_message("no config file input specified");
        return;
    }

    # read through file
    my %fconfig;
    while (defined(my $line = $fh->getline))
    {
        # clean up
        chomp($line);
        $line =~ s/\#.*//;
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;
        next unless $line =~ m/\S/;

        # parse
        my ($k, $v) = split(m/\s*=\s*/, $line, 2);
        $fconfig{$k} = $v;
    }
    $fh->close;

    # update config
    return $self->config(%fconfig);
}

1;

#$Header$
