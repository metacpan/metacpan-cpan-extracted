package Test::Run::CmdLine;

use warnings;
use strict;

use 5.008;

use Carp;
use UNIVERSAL::require;
use YAML::XS ();

use Test::Run::Base;

use Test::Run::Iface;
use Test::Run::Obj;

=head1 NAME

Test::Run::CmdLine - Analyze tests from the command line using Test::Run

=cut

use vars (qw($VERSION));

$VERSION = '0.0131';

use Moose;

extends ('Test::Run::Base');

=head1 SYNOPSIS

    use Test::Run::CmdLine;

    my $tester = Test::Run::CmdLine->new(
        {
            'test_files' => ["t/one.t", "t/two.t"],
        },
    );

    $tester->run();

=cut

has 'backend_class' => (is => "rw", isa => "Str",
    default => "Test::Run::Iface"
);
has 'backend_params' => (is => "rw", isa => "HashRef");
has 'backend_plugins' => (is => "rw", isa => "ArrayRef",
    default => sub { [] },
);
has 'backend_env_args' => (is => "rw", isa => "ArrayRef",
    default => sub { [] },
);
has 'test_files' => (is => "rw", isa => "ArrayRef");

sub BUILD
{
    my $self = shift;

    $self->_collect_backend_plugins();

    return;
}

sub _process_args
{
    my ($self, $args) = @_;
    if (exists($args->{backend_params}))
    {
        $self->backend_params($args->{backend_params});
    }

    return 0;
}

=head1 Interface Functions

=head2 $tester = Test::Run::CmdLine->new({'test_files' => \@test_files, ....});

Initializes a new testing front end. C<test_files> is a named argument that
contains the files to test.

Other named arguments are:

=over 4

=item backend_params

This is a hash of named parameters to be passed to the backend class (derived
from L<Test::Run::Obj>.)

=item driver_class

This is the backend class that will be instantiated and used to perform
the processing. Defaults to L<Test::Run::Obj>.

=back

=head2 $tester->run()

Actually runs the tests on the command line.

TODO : Write more.

=head2 BUILD

For Moose.

=cut

sub run
{
    my $self = shift;
    my $backend_class = $self->backend_class();
    $backend_class->require();
    if ($@)
    {
        die $@;
    }
    foreach my $plugin (@{$self->_calc_plugins_for_ISA()})
    {
        $plugin->require();
        if ($@)
        {
            die $@;
        }
        {
            no strict 'refs';
            push @{"${backend_class}::ISA"}, $plugin;
        }
    }

    # Finally - put Test::Run::Obj there.
    {
        no strict 'refs';
        push @{"${backend_class}::ISA"}, "Test::Run::Obj";
    }

    my $backend = $backend_class->new(
        {
            'test_files' => $self->test_files(),
            @{$self->get_backend_args()},
        },
    );

    return $backend->runtests();
}

=head1 Environment Variables

The following environment variables (C<%ENV>) affect the behaviour of
Test::Run::CmdLine:

=over 4

=item HARNESS_COLUMNS

This determines the width of the terminal (sets C<'Columns'>) in
L<Test::Run::Obj>). If not specified, it will be determined according
to the C<COLUMNS> environment variable, that is normally specified by
the terminal.

=item HARNESS_DEBUG

Triggers the C<'Debug'> option in Test::Run::Obj. Meaning, it will print
debugging information about itself as it runs the tests.

=item HARNESS_FILELEAK_IN_DIR

This variable points to a directory that will be monitored. After each
test file, the module will check if new files appeared in the direcotry
and report them.

It is advisable to give an absolute path here. If it is relative, it would
be relative to the current working directory when C<$tester-E<gt>run()> was
called.

=item HARNESS_NOTTY

Triggers the C<'NoTty'> option in Test::Run::Obj. Meaning, it causes
Test::Run::CmdLine not to treat STDOUT as if it were a console. In this
case, it will not emit more frequent progress reports using carriage
returns (C<"\r">s).

=item HARNESS_PERL

Specifies the C<'Test_Interpreter'> variable of L<Test::Run::Obj>. This allows
specifying a different Perl interprter to use besides C<$^X>.

=item HARNESS_PERL_SWITCHES

Specifies the C<'Switches'> variable of L<Test::Run::Obj>. This allows
specifying more switches to the Perl interpreter.

=item HARNESS_TIMER

This variable triggers the C<'Timer'> option in Test::Run::Obj. What it
does is causes the time that took for tests to run to be displayed.

=item HARNESS_VERBOSE

Triggers the C<'Verbose'> option in Test::Run::Obj. Meaning, it emits
the standard output of the test files while they are processed.

=back

=head1 Internal Functions

=head2 my $args_array_ref = $tester->get_backend_args()

Calculate and retrieve the arguments for the backend class (that inherits
from L<Test::Run::Obj>) as a single array reference. Currently it appends
the arguments of get_backend_env_args() to that of get_backend_init_args().

=cut

sub get_backend_args
{
    my $self = shift;

    return $self->accum_array(
        {
            method => "private_backend_args",
        }
    );
}

=head2 $self->private_backend_args()

Calculates the get_backend_args()-specific arguments for this class.

=cut

sub private_backend_args
{
    my $self = shift;

    $self->get_backend_env_args();

    my $init_args = $self->get_backend_init_args();

    return [@{$self->backend_env_args()}, @$init_args];
}

=head2 $tester->get_backend_env_args()

Calculate the arguments for the backend class, that originated
from the environment (%ENV), and puts them in C<$tester->backend_env_args()>

=cut

sub _get_direct_backend_env_mapping
{
    my $self = shift;

    return $self->accum_array(
        {
            method => "private_direct_backend_env_mapping",
        }
    );
}

=head2 $self->private_direct_backend_env_mapping()

The return value of this method is collected from every class, and adapted
to the direct backend environment mapping.

=cut

sub private_direct_backend_env_mapping
{
    my $self = shift;
    return [
        { 'env' => "HARNESS_FILELEAK_IN_DIR", 'arg' => "Leaked_Dir", },
        { 'env' => "HARNESS_VERBOSE", 'arg' => "Verbose", },
        { 'env' => "HARNESS_DEBUG", 'arg' => "Debug", },
        { 'env' => "COLUMNS", 'arg' => "Columns", },
        { 'env' => "HARNESS_COLUMNS", 'arg' => "Columns", },
        { 'env' => "HARNESS_TIMER", 'arg' => "Timer", },
        { 'env' => "HARNESS_NOTTY", 'arg' => "NoTty", },
        { 'env' => "HARNESS_PERL", 'arg' => "Test_Interpreter", },
        { 'env' => "HARNESS_PERL_SWITCHES", 'arg' => "Switches_Env", },
        ];
}

sub _get_non_direct_backend_env_mapping
{
    my $self = shift;

    return $self->accum_array(
        {
            method => "private_non_direct_backend_env_mapping",
        }
    );
}

sub _get_backend_env_mapping
{
    my $self = shift;

    return
    [
        (map { +{ type => "direct", %$_ } } @{$self->_get_direct_backend_env_mapping()}),
        @{$self->_get_non_direct_backend_env_mapping()},
    ];
}

sub _handle_backend_env_spec
{
    my ($self, $spec) = @_;

    my $type = $spec->{type};
    my $env = $spec->{env};

    if (exists($ENV{$env}))
    {
        my $sub = $self->can("_backend_spec_handler_for_$type");

        if (! $sub)
        {
            confess "Cannot find type handler for $type!";
        }

        $sub->(
            $self,
            $spec,
        );
    }
}

sub _backend_spec_handler_for_direct
{
    my ($self, $spec) = @_;

    my $arg = $spec->{arg};
    my $env = $spec->{env};

    push @{$self->backend_env_args()},
         ($arg => $ENV{$env});
}

sub _backend_spec_handler_for_yamldata
{
    my ($self, $spec) = @_;

    my $arg = $spec->{arg};
    my $env = $spec->{env};

    push @{$self->backend_env_args()},
         ($arg => YAML::XS::LoadFile($ENV{$env}));
}

sub _calc_backend_env_var_map
{
    my ($self, $mapping_string) = @_;

    my @assignments = split(/\s*;\s*/, $mapping_string);
    return
    +{
        map { /\A([^=]*)=(.*)\z/ms ? ($1 => $2) : () }
            @assignments
    };
}

sub _backend_spec_handler_for_varmap
{
    my ($self, $spec) = @_;

    my $arg = $spec->{arg};
    my $env = $spec->{env};

    push @{$self->backend_env_args()},
         ($arg => $self->_calc_backend_env_var_map($ENV{$env}));
}

sub get_backend_env_args
{
    my $self = shift;
    foreach my $spec (@{$self->_get_backend_env_mapping()})
    {
        $self->_handle_backend_env_spec($spec);
    }

    return 0;
}

=head2 my $args_array_ref = $tester->get_backend_init_args()

Calculate and return the arguments for the backend class, that originated
from the arguments passed to the (front-end) object from its constructor.

=cut

sub get_backend_init_args
{
    my $self = shift;
    my @args;
    if (defined($self->backend_params()))
    {
        push @args, (%{$self->backend_params()});
    }
    return \@args;
}

sub _calc_plugins_for_ISA
{
    my $self = shift;
    return
        [
            map { $self->_calc_single_plugin_for_ISA($_) }
            @{$self->backend_plugins()}
        ];
}

sub _calc_single_plugin_for_ISA
{
    my $self = shift;
    my $p = shift;
    return "Test::Run::Plugin::$p";
}

=head2 $self->private_backend_plugins()

Calculates the backend plugins specific for this class. They will be collected
to formulate a list of plugins that will be C<add_to_backend_plugins()>'ed.

=cut

sub _get_backend_plugins_accumulation
{
    my $self = shift;

    return [reverse(@{$self->accum_array(
        {
            method => "private_backend_plugins",
        }
    )})];
}

sub _collect_backend_plugins
{
    my $self = shift;

    foreach my $plug (@{$self->_get_backend_plugins_accumulation()})
    {
        $self->add_to_backend_plugins($plug);
    }

    return;
}

=head2 $self->add_to_backend_plugins($plugin)

Appends a plugin to the plugins list. Useful in front-end plug-ins.

=cut

sub add_to_backend_plugins
{
    my $self = shift;
    my $plugin = shift;
    unshift @{$self->backend_plugins()}, $plugin;
}

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::CmdLine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::CmdLine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::CmdLine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::CmdLine>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Run::CmdLine/>

=back

=head1 SOURCE AVAILABILITY

The latest source of Test::Run::CmdLine is available from the Test::Run
BerliOS Subversion repository:

L<https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

1; # End of Test::Run::CmdLine
