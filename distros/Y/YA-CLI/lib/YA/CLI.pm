package YA::CLI;
our $VERSION = '0.001';
use Moo;

# ABSTRACT: Do CLI things

use Carp qw(croak);
use Getopt::Long;
use List::Util qw(first);
use Module::Pluggable::Object;


sub BUILD_ARGS {
    croak "Please use run()";
}

sub default_handler {
    return 'main';
}

sub default_search_path {
    return shift;
}

sub cli_options {
    return;
}

sub _init {
    my ($class, $args) = @_;

    $args //= \@ARGV;

    my %cli_args = $class->_get_opts($args);

    my $action;
    if (@$args && $args->[0] !~ /^--/) {
        $action = shift @$args;
    }
    $action //= $class->default_handler;

    my $handler = $class->_get_action_handler($action);

    if (!$handler) {
        require YA::CLI::ErrorHandler;
        $handler = 'YA::CLI::ErrorHandler';
        return $handler->as_help(1, "$action command does not exist!");
    }

    return $handler->as_manpage()  if $cli_args{man};
    return $handler->as_help()     if $cli_args{help};

    return $handler->new_from_args($args);
}

sub run {
    my ($class, $args) = @_;
    my $handler = $class->_init($args);
    return $handler->run();
}

sub _get_opts {
    my ($class, $args) = @_;

    my @cli_options = qw(
        help|h
        man|m
    );

    push(@cli_options, $class->cli_options);

    my $p = Getopt::Long::Parser->new(
        config => [
            qw(
                pass_through
                no_auto_abbrev
            )
        ]
    );

    my %cli_args;
    $p->getoptionsfromarray($args, \%cli_args, @cli_options);
    return %cli_args;
}

my @PLUGINS;

sub _get_action_handler {
    my ($class, $action) = @_;

    my $finder = Module::Pluggable::Object->new(
        search_path => $class->default_search_path,
        require     => 1,
    );

    @PLUGINS = $finder->plugins if !@PLUGINS;
    return first { $_->has_action($action) } @PLUGINS;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

YA::CLI - Do CLI things

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package main;
    require Your::App;
    Your::App->run();


    package Your::App;
    use Moo;
    extends 'YA::CLI';

    __PACKAGE__->meta->make_immutable;


    package Your::App::SubCommand;
    use Moo;
    use namespace::autoclean;
    with 'YA::CLI::ActionRole';

    # This is the action your sub command is selected on
    sub action { 'main' } # can also be an array in case you want aliases

    sub run {
        # Logic here
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

A CLI framework for CLI applications that use subcommands

=for Pod::Coverage BUILD_ARGS

=head1 METHODS

=head2 run

Runs the application

=head2 default_search_path

Override the default search path, defaults to your Your::App namespace.

=head2 default_handler

Defaults to C<main> for your default handler. If this handler cannot be found
ultimatly falls back to L<YA::CLI::MainHandler> which deals with just C<--help>
and C<--man> commands.

=head2 cli_options

Define L<Getopt::Long> options in your module that are used on top of the
default help and man.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
