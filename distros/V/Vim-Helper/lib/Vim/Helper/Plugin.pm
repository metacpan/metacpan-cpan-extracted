package Vim::Helper::Plugin;
use strict;
use warnings;
use Carp qw/croak/;
our @CARP_NOT = ('Vim::Helper');

sub import {
    my $class       = shift;
    my $caller      = caller;
    my %config_keys = @_;

    {
        no strict 'refs';
        no warnings 'once';
        push @{"$caller\::ISA"} => $class;
        *{"$caller\::config_keys"} = sub { \%config_keys };
    }

    _gen_accessor( $caller, $_ ) for keys %config_keys;
}

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub args  { {} }
sub opts  { {} }
sub vimrc { "" }

sub config {
    my $self = shift;
    my ($config) = @_;

    for my $key ( keys %{$self->config_keys} ) {
        my $val  = delete $config->{$key};
        my $spec = $self->config_keys->{$key};

        croak "config key '$key' is required."
            if $spec->{required} && !defined $val;

        $self->$key($val) if defined $val;
    }

    return unless keys %$config;

    croak "The following keys are not valid: " . join ", " => keys %$config;
}

sub _gen_accessor {
    my ( $class, $name ) = @_;

    my $default = $class->config_keys->{$name}->{default};

    my $meth = sub {
        my $self = shift;
        ( $self->{$name} ) = @_ if @_;

        if ( defined($default) && !exists $self->{$name} ) {
            $self->{$name} = ref $default ? $self->$default : $default;
        }

        return $self->{$name};
    };

    no strict 'refs';
    *{$class . '::' . $name} = $meth;
}

1;

__END__

=pod

=head1 NAME

Vim::Helper::Plugin - Base class and API for writing new plugins

=head1 DESCRIPTION

This package acts as a base class for all plugins. It also provides an API for
writing new plugins quickly and efficiently. When you C<use
Vim::Helper::Plugin> it automatically sets itself as a base class on your
class.

=head1 SYNOPSIS

    package Vim::Helper::MyPlugin;
    use strict;
    use warnings;
    
    # Load the plugin base class, and specify our configuration options.
    # A read/write accessor will be generated for every config option added.
    # If a default is specified it will be used when no option is provided.
    # Defaults can be wrapped in a sub if they need ot be generated per
    # instance.
    # If required is specified, the program will crash if the config does not
    # specify the option.
    use Vim::Helper::Plugin(
        config_option_foo => { default => 'foo'           },
        config_option_bar => { default => sub {[ 'bar' ]} },
        config_option_baz => { required => 1              },
    );

    #########################
    # Override some methods:
    
    # args and opts, each key must be a valid key for the type in Declare::CLI.
    # An additional key of 'help' is accepted for use in the 'help' command.
    # Both of these are optional, no need to override them
    sub args {{ key => %CONFIG }}
    sub opts {{ key => %CONFIG }}

    # VIMRC content (if we have any, otherwise do not override)
    sub vimrc {
        my $self = shift;
        my ( $helper, $opts ) = @_;
        my $cmd = $helper->command( $opts );

        ...

        return $VIMRC_CONTENT;
    }

    #########################
    # Add our own methods:
    sub do_something {
        my $self = shift;
        ...
    }
    
    1;

=head1 METHODS

=over 4

=item $args = $CLASS->args()

Get the hashref of args provided by this plugin.

=item $opts = $CLASS->opts()

Get the hashref of opts provided by this plugin.

=item $obj = $CLASS->new()

Create a new instance.

=item $vimrc = $obj->vimrc( $helper, $opts )

Generate the vimrc content for this plugin.

=item $obj->config( { key => 'value', ... } )

You probably should not override this unless you REALLY want to change how your
classes configuration function behaves.

For each key it will set the proper accessor. If a required key is omitted an
error is thrown. If a key is invalid an error will be thrown.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Vim-Helper is free software; Standard perl licence.

Vim-Helper is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut

