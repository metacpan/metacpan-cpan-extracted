package Vim::Helper::Help;
use strict;
use warnings;
use Vim::Helper::Plugin;

sub args {
    {
        help => {
            handler     => \&arg_help,
            description => "Help with a specific command",
            help        => "Usage: $0 help COMMAND",
        },
    };
}

sub opts {
    {
        help => {
            bool        => 1,
            trigger     => \&opt_help,
            description => "Show usage help"
        },
    };
}

sub opt_help {
    my $helper = shift;
    print _help_output($helper);
    exit(0);
}

sub _help_output {
    my $helper = shift;
    return "Usage: $0 [OPTS] command [ARGS]\n\n" . $helper->cli->usage;
}

sub arg_help {
    my $helper = shift;
    my ( $name, $opts, $command ) = @_;

    return {
        code   => 0,
        stdout => _help_output($helper),
    } unless $command;

    my $plugin;
    for $name ( keys %{$helper->plugins} ) {
        $plugin = $helper->plugins->{$name};
        last if $plugin->args->{$command};
        $plugin = undef;
    }

    return {
        code   => 1,
        stderr => "Command not found\n",
    } unless $plugin;

    return {
        code   => 0,
        stdout => $plugin->args->{$command}->{help} . "\n" || "No help available\n",
    };
}

1;

__END__

=pod

=head1 NAME

Vim::Helper::Help - Provides the help output

=head1 DESCRIPTION

Used to provide the help output. No need to load this, it is loaded
automatically.

=head1 ARGS

=over 4

=item help

Show help output, or get help for a specific arg.

=back

=head1 OPTS

=over 4

=item --help

Show command usage.

=back

=head1 CONFIGURATION OPTIONS

None

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Vim-Helper is free software; Standard perl licence.

Vim-Helper is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut

