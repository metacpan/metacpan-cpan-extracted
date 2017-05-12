# $Id: Config.pm 2274 2011-01-19 20:22:07Z guillomovitch $
package Youri::Config;

=head1 NAME

Youri::Config - Youri configuration handler

=head1 SYNOPSIS

    use Youri::Config;

    my $app = Youri::Config->new(
        options => {
            help => '|h!'
        },
        directories => [ '/etc/youri', "$ENV{HOME}/.youri" ],
        file        => 'app.conf',
    );

    # get command line argument
    my $foo = $app->get_arg('foo');

    # get configuration file parameter
    my $bar = $app->get_param('bar');

=head1 DESCRIPTION

This class handle configuration for all YOURI applications.

The command line specification is used to manage arguments through
Getopt::Long. Unless  B<--config> argument is given, the list of directories is
then scanned for a file with given name, and halt as soon as it find one. If no
readable file is found, an exception is thrown. The file is then processed
through YAML::AppConfig. If parsing fails, an exception is thrown.

=head1 CONFIGURATION FILE FORMAT

=head2 SHARED KEYS

In addition to the application-specific optional or mandatory parameters, all
YOURI applications support the following optional top-level parameters:

=over

=item B<includes>

A list of additional configuration files.

=item B<foo>

An arbitrary variable, usable everywhere else in the file.

=back

=head2 PLUGIN DEFINITION

All YOURI application heavily rely on plugins defined in their configuration
files. A plugin definition is composed from the following parameters:

=over

=item B<class>

The class of this plugin.

=item B<options>

The options of this plugin.

=back

=head1 SEE ALSO

YAML::AppConfig, Getopt::Long

=cut

use strict;
use warnings;
use YAML::AppConfig;
use Getopt::Long;
use File::Spec;
use Pod::Usage;
use Carp;
use version; our $VERSION = qv('0.2.1');

=head2 new(%args)

Creates and returns a new Youri::Config object.

=cut

sub new {
    my ($class, %options) = @_;

    # command line arguments
    my $args = {
        verbose => 0
    };
    my @args;
    if ($options{args}) {
        while (my ($arg, $spec) = each %{$options{args}}) {
            push(@args, ($arg . $spec) => \$args->{$arg});
        }
    }
    push(@args,
        'config=s'   => \$args->{config},
        'h|help'     => \$args->{help},
        'v|verbose+' => \$args->{verbose}
    );
    GetOptions(@args);

    if ($args->{help}) {
        if (!@ARGV) {
            # standard help, available immediatly
            my $filename = (caller)[1];
            pod2usage(
                -input   => $filename,
                -verbose => 0
            );
        }
    }

    # config files parameters
    
    # find configuration file to use
    my $main_file;
    if ($args->{config}) {
        if (! -f $args->{config}) {
            croak "Non-existing file $args->{config}";
        } elsif (! -r $args->{config}) {
            croak "Non-readable file $args->{config}";
        } else {
            $main_file = $args->{config};
        }
    } else {
        foreach my $directory (@{$options{directories}}) {
            my $file = "$directory/$options{file}";
            next unless -f $file && -r $file;
            $main_file = $file;
            last;
        }
    }

    my $params;
    if ($main_file) {
        eval {
            $params = YAML::AppConfig->new(file => $main_file);
        };
        if ($@) {
            croak
                "Invalid configuration file $main_file, aborting. " .
                "The parser error was:\n" . $@;
        }

        # process inclusions
        my $includes = $params->get('includes');
        if ($includes) {
            foreach my $include_file (@{$includes}) {
                # convert relative path to absolute ones
                $include_file = File::Spec->rel2abs(
                    $include_file, (File::Spec->splitpath($main_file))[1]
                );

                if (! -f $include_file) {
                    warn "Non-existing file $include_file, skipping";
                } elsif (! -r $include_file) {
                    warn "Non-readable file $include_file, skipping";
                } else {
                    eval {
                        $params->merge(file => $include_file);
                    };
                    if ($@) {
                        carp "Invalid included configuration file $include_file, skipping";
                    }
                }
            }
        }
    } else {
        croak 'No config file found, aborting' if $options{mandatory};
    }

    my $self = bless {
        _args   => $args,
        _params => $params
    }, $class;

    return $self;
}

=head1 INSTANCE METHODS

=head2 get_arg($arg)

Returns the command-line argument $arg.

=cut

sub get_arg {
    my ($self, $arg) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_args}->{$arg};
}

=head2 get_param($param)

Returns the configuration file parameter $param.

=cut


sub get_param {
    my ($self, $param) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_params} ?
        $self->{_params}->get($param) : 
        undef;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
