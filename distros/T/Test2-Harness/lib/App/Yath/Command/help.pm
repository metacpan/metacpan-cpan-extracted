package App::Yath::Command::help;
use strict;
use warnings;

use Term::Table();

our $VERSION = '2.000005';

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase qw/<_command_info_hash/;

use Test2::Harness::Util qw/find_libraries mod2file/;
use App::Yath::Util qw/paged_print/;
use List::Util();
use File::Spec();

sub group { ' main' }
sub summary { 'Show the list of commands' }

sub description {
    return <<"    EOT"
This command provides a list of commands when called with no arguments.
When given a command name as an argument it will print the help for that
command.
    EOT
}

use Getopt::Yath;
option_group {group => 'help', category => "Help Options"} => sub {
    option verbose => (
        type => 'Count',
        short => 'v',
        description => "Show commands that would normally be omitted such as internal and deprecated",
        initialize => 0,
    );
};

sub command_info_hash {
    my $self = shift;

    return $self->{+_COMMAND_INFO_HASH} if $self->{+_COMMAND_INFO_HASH};

    my $settings = $self->{+SETTINGS};
    my $hs = $settings->help;

    my %commands;
    my $command_libs = { %{find_libraries('App::Yath::Command::*')}, %{find_libraries('App::Yath::Command::*::*')}};
    for my $lib (sort keys %$command_libs) {
        my $ok = eval {
            local $SIG{__WARN__} = sub { 1 };
            require $command_libs->{$lib};
            1
        };
        unless ($ok) {
            my ($err) = split /\n/, $@;
            my $short = $lib;
            $short =~ s/^App::Yath::Command:://;

            if ($err =~ m/Module '\Q$lib\E' has been deprecated/) {
                push @{$commands{'z  deprecated'}} => [$short, "This command is deprecated"] if $hs->verbose;
                next;
            }

            push @{$commands{'z  failed to load'}} => [$short, $err];
            next;
        }

        next unless $lib->isa('App::Yath::Command');
        my $internal = $lib->internal_only;
        next if $internal && !$hs->verbose;
        my $name = $lib->name;
        my $group = $internal ? 'z  internal only' : $lib->group;
        $group = [$group] unless ref $group;
        for my $g (@$group) {
            next if $g =~ m/deprecated/ && !$hs->verbose;
            push @{$commands{$g}} => [$name, $hs->verbose ? ($lib) : (), $lib->summary];
        }
    }

    return $self->{+_COMMAND_INFO_HASH} = \%commands;
}

sub run {
    my $self = shift;
    my $args = $self->{+ARGS};

    return $self->command_help($args->[0]) if @$args;

    my $script = File::Spec->abs2rel($self->settings->yath->script // $0);

    paged_print(
        "\nUsage: $script help [-v] [COMMAND]\n",
        $self->command_table,
    );

    return 0;
}

sub command_table {
    my $self = shift;

    my $command_info_hash = $self->command_info_hash;

    my $out = "";

    for my $group (reverse sort keys %$command_info_hash) {
        my $set = $command_info_hash->{$group};

        my $printable = $group;
        $printable =~ s/^\s+//g;
        $printable =~ s/\s+$//g;
        $printable =~ s/^z\s+//ig;
        $printable =~ s/^z-//ig;
        $out .= "\n" . uc($printable) . " COMMANDS:\n";

        my $rows = [ sort { $a->[0] cmp $b->[0] } @$set ];
        my $table = Term::Table->new(rows => $rows);
        $out .= join '' =>  map { "$_\n" } $table->render;
    }

    return $out;
}

sub command_help {
    my $self = shift;
    my ($command) = @_;

    require App::Yath;
    my $cmd_class = "App::Yath::Command::$command";
    require(mod2file($cmd_class));

    my $app = App::Yath->new(command => $cmd_class, settings => $self->settings);
    $app->options->include($cmd_class->options);
    paged_print($app->cli_help());

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::help - Show the list of commands

=head1 DESCRIPTION

This command provides a list of commands when called with no arguments.
When given a command name as an argument it will print the help for that
command.


=head1 USAGE

    $ yath [YATH OPTIONS] help [COMMAND OPTIONS]

=head2 OPTIONS

=head3 Help Options

=over 4

=item -v

=item -vv

=item -vvv..

=item -v=COUNT

=item --verbose

=item --verbose=COUNT

=item --no-verbose

Show commands that would normally be omitted such as internal and deprecated

Note: Can be specified multiple times, counter bumps each time it is used.


=back


=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

