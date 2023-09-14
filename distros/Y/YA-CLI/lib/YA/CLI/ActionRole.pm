package YA::CLI::ActionRole;
our $VERSION = '0.004';
use Moo::Role;
use namespace::autoclean;

# ABSTRACT: Action handler role

use YA::CLI::Usage;
use Getopt::Long;
use List::Util qw(none any);

requires qw(
    action
    run
);

has _cli_args => (
  is        => 'ro',
  predicate => '_has_cli_args',
  writer    => '_set_cli_args',
  init_args => undef,
  default   => sub { {} },
);

sub cli_options {
    return;
}

sub usage_pod {
    return;
}

sub BUILD {
    my ($self, $args) = @_;

    foreach (keys %$args) {
        delete $args->{$_} if $self->can($_);
    }
    $self->_set_cli_args($args) if %$args;
}

sub new_from_args {
    my ($class, $args) = @_;
    return $class->new($class->get_opts($args));
}

sub get_opts {
    my ($class, $args) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [qw(no_auto_abbrev) ]
    );

    my %cli_args;
    $p->getoptionsfromarray($args, \%cli_args, $class->cli_options);
    return %cli_args;
}

sub has_action {
    my $self = shift;
    my $action  = shift;
    my $subaction = shift;

    return if none { $action eq $_ } $self->action;

    if ($self->can('subaction')) {
        return 0 unless defined $subaction;
        return any { $subaction eq $_ } $self->subaction;
    }
    return defined $subaction ? 0 : 1;
}

sub as_help {
    my ($self, $rc, $message) = @_;

    return YA::CLI::Usage->new(
        rc => ($rc // 0),
        $message ? (message  => $message) : (),
        $self->_get_podfile_for_usage,
    );
}

sub as_manpage {
    my ($self) = @_;

    return YA::CLI::Usage->new(
        rc      => 0,
        verbose => 2,
        $self->_get_podfile_for_usage,
    );
}


sub _get_podfile_for_usage {
    my $self = shift;
    my $podfile;
    if (my $pod = $self->usage_pod) {
        $podfile = $pod == 1? $self : $pod;
    }
    return $podfile ? ( pod_file => $podfile ) : ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

YA::CLI::ActionRole - Action handler role

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package Foo;
    use Moo;
    with qw(YA::CLI::ActionRole);

    sub usage_pod { 1 } # 1 Usage is provided by this module's POD
    sub cli_options { return qw(foo=s) }

    sub action { "action" }
    sub subaction { "subaction" }
    sub run { ...; }

=head1 DESCRIPTION

This role should be implemented by an action handler. The action handler should
implement the following methods:

=over

=item action

The action it handles, eg. C<provider>

=item run

How the action should be run

=back

The following method doesn't need to be implemented if an action doesn't have a
subcommand

=over

=item subaction

The sub action it handles, eg. C<create>

=back

=head1 METHODS

=head2 usage_pod

If the handler provides its own usage POD. If this is 0/undef, the POD of the
script it used. If this function returns 1, it it taken from the file itself.
Otherwise it is assumed the return value is the path to the POD itself.

=head2 cli_options

Add additional CLI options for the sub command. This will be parsed by
L<Getopt::Long>.

=head2 get_opts

Parse the options and returns a hash with the parsed options.

=head2 as_help

Returns an L<YA::CLI::Usage> object which runs as a help

=head2 as_manpage

Returns an L<YA::CLI::Usage> object which runs as a manpage

=head2 has_action

Checks if the supplied action is supported by the action handler

=head2 new_from_args

Instantiates the class with the CLI args that were given to them

=head2 _cli_args

For all cli options which do not have attributes in the module, you can access them via

    $self->_cli_args->{'your-name-here'}

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
