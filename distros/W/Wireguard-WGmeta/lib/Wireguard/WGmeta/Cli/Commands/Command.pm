=head1 NAME

Cli::Command - Base class for commands

=head1 DESCRIPTION

Base class for the individual CLI commands. A command takes care of (possible) input arguments and performs actions accordingly.

=head1 SYNOPSIS

A command must implement at least

    package Wireguard::WGmeta::Cli::Commands::YourCommand;

    use experimental 'signatures';
    use parent 'Wireguard::WGmeta::Cli::Commands::Command';

    # is called from the router
    sub entry_point($self) {
        ...
    }

    # show cmd specific help
    sub cmd_help($self) {
        ...
    }

=head1 METHODS

=cut


package Wireguard::WGmeta::Cli::Commands::Command;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use Wireguard::WGmeta::Utils;
use constant WIREGUARD_HOME => '/etc/wireguard/';

=head2 new(@input_arguments)

Creates a new Command instance. The following data is accessible through C<$self> after calling:

    my $commandline_args = $self->{input_args};     # reference to array of input arguments
    my $wireguard_home = $self->{wireguard_home};   # Path to wireguard home dir

Please also take note of the effect of environment vars: L<Wireguard::WGmeta::Index/ENVIRONMENT VARIABLES>

B<Parameters>

=over 1

=item

C<@input_arguments> List of input args (except C<cmd>)

=back

B<Returns>

An instance of a Command

=cut

sub new($class, @input_arguments) {
    my $self = {
        'input_args' => \@input_arguments
    };
    # check if env var is available
    if (defined($ENV{'WIREGUARD_HOME'})) {
        $self->{wireguard_home} = $ENV{'WIREGUARD_HOME'};
    }
    else {
        $self->{wireguard_home} = WIREGUARD_HOME;
    }
    bless $self, $class;
    return $self;
}

=head2 entry_point()

Method called from L<Wireguard::WGmeta::Cli::Router/route_command($ref_list_input_args)>

=cut
sub entry_point($self) {
    die 'Please instantiate the actual implementation';
}

=head2 cmd_help()

Stub for specific cmd help. Is expected to terminate the command by calling C<exit()>
and print the help content directly to I<std_out>.

=cut
sub cmd_help($self) {
    die 'Please instantiate the actual implementation';
}

=head2 check_privileges()

Check if the user has r/w access to C<wireguard_home>.

B<Raises>

Exception if the user has insufficient privileges .

=cut
sub check_privileges($self) {
    if (not -w $self->{wireguard_home}) {
        my $username = getpwuid($<);
        die "Insufficient privileges - `$username` has rw no permissions to `$self->{wireguard_home}`. You probably forgot `sudo`";
    }
}

sub _retrieve_or_die($self, $ref_array, $idx) {
    my @arr = @{$ref_array};
    eval {return $arr[$idx]} or $self->cmd_help();
}

1;