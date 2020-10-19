package Test::Run::CmdLine::Prove;

use strict;
use warnings;

use Moose;

with 'MooseX::Getopt::Basic';

has 'dry' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(D)],
);

has '_ext_regex' => (accessor => "ext_regex", is => "rw", isa => "RegexpRef");
has '_ext_regex_string' =>
    (accessor => "ext_regex_string", is => "rw", isa => "Str")
    ;
has 'recurse' => (traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(r)],
);
has 'shuffle' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(s)],
);
has 'Verbose' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(v)],
);
has 'Debug' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(d)],
);

has '_Switches' => (accessor => "Switches", is => "rw", isa => "ArrayRef");
has 'Test_Interpreter' => (
    traits => ['Getopt'], is => "rw",
    isa => "Str", cmd_aliases => [qw(perl)],
);
has 'Timer' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool",
    cmd_aliases => [qw(timer)],
);
has 'proto_includes' => (
    traits => ['Getopt'],
    is => "rw", isa => "ArrayRef",
    cmd_aliases => [qw(I)],
    default => sub { return []; },
);
has 'blib' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(b)],
);

has 'lib' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(l)],
);

has 'taint' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(t)],
);

has 'uc_taint' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(T)],
);

has 'help' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(h ?)],
);

has 'man' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(H)],
);

has 'version' => (
    traits => ['Getopt'], is => "rw",
    isa => "Bool", cmd_aliases => [qw(V)],
);

has 'ext' => (
    is => "rw", isa => "ArrayRef",
    default => sub { return []; },
);

use MRO::Compat;

use Test::Run::CmdLine::Iface;
use Getopt::Long;
use Pod::Usage 1.12;
use File::Spec;

use vars qw($VERSION);

$VERSION = '0.0132';


=head1 NAME

Test::Run::CmdLine::Prove - A Module for running tests from the command line

=head1 SYNOPSIS

    use Test::Run::CmdLine::Prove;

    my $tester = Test::Run::CmdLine::Prove->new({'args' => [@ARGV]});

    $tester->run();

=cut

=begin removed_code

around '_parse_argv' => sub {
    my $orig = shift;
    my $self = shift;

    my %params = $self->$orig(@_);
    delete($params{'usage'});
    return %params;
};

=end removed_code

=cut

sub create
{
    my $class = shift;
    my $args = shift;

    my @argv = @{$args->{'args'}};
    my $env_switches = $args->{'env_switches'};

    if (defined($env_switches))
    {
        unshift @argv, split(" ", $env_switches);
    }

    Getopt::Long::Configure( "no_ignore_case" );
    Getopt::Long::Configure( "bundling" );

    my $self;
    {
        # Temporary workaround for MooseX::Getopt;
        local @ARGV = @argv;
        $self = $class->new_with_options(
            argv => \@argv,
            "no_ignore_case" => 1,
            "bundling" => 1,
        );
    }

    $self->_initial_process($args);

    return $self;
}

sub _initial_process
{
    my ($self, $args) = @_;

    $self->maybe::next::method($args);

    my @switches = ();

    if ($self->version())
    {
        $self->_print_version();
        exit(0);
    }

    if ($self->help())
    {
        $self->_usage(1);
    }

    if ($self->man())
    {
        $self->_usage(2);
    }

    if ($self->taint())
    {
        unshift @switches, "-t";
    }

    if ($self->uc_taint())
    {
        unshift @switches, "-T";
    }

    my @includes = @{$self->proto_includes()};

    if ($self->blib())
    {
        unshift @includes, ($self->_blibdirs());
    }

    # Handle the lib include path
    if ($self->lib())
    {
        unshift @includes, "lib";
    }

    $self->proto_includes(\@includes);

    push @switches, (map { $self->_include_map($_) } @includes);

    $self->Switches(\@switches);

    $self->_set_ext([ @{$self->ext()} ]);

    return 0;
}

sub _include_map
{
    my $self = shift;
    my $arg = shift;
    my $ret = "-I$arg";
    if (($arg =~ /\s/) &&
        (! (($arg =~ /^"/) && ($arg =~ /"$/)) )
       )
    {
        return "\"$ret\"";
    }
    else
    {
        return $ret;
    }
}

sub _print_version
{
    my $self = shift;
    printf("runprove v%s, using Test::Run v%s, Test::Run::CmdLine v%s and Perl v%s\n",
        $VERSION,
        $Test::Run::Obj::VERSION,
        $Test::Run::CmdLine::VERSION,
        $^V
    );
}

=head1 Interface Functions

=head2 $prove = Test::Run::CmdLine::Prove->create({'args' => [@ARGV], 'env_switches' => $env_switches});

Initializes a new object. C<'args'> is a keyed parameter that gives the
command line for the prove utility (as an array ref of strings).

C<'env_switches'> is a keyed parameter that gives a string containing more
arguments, or undef if not wanted.

=head2 $prove->run()

Runs the tests.

=cut

sub run
{
    my $self = shift;

    my $tests = $self->_get_test_files();

    if ($self->_should_run_tests($tests))
    {
        return $self->_actual_run_tests($tests);
    }
    else
    {
        return $self->_dont_run_tests($tests);
    }
}

sub _should_run_tests
{
    my ($self, $tests) = @_;

    return scalar(@$tests);
}

sub _actual_run_tests
{
    my ($self, $tests) = @_;

    my $method = $self->dry() ? "_dry_run" : "_wet_run";

    return $self->$method($tests);
}

sub _dont_run_tests
{
    return 0;
}

sub _wet_run
{
    my $self = shift;
    my $tests = shift;

    my $test_run =
        Test::Run::CmdLine::Iface->new(
            {
                'test_files' => [@$tests],
                'backend_params' => $self->_get_backend_params(),
            }
        );

    return $test_run->run();
}

sub _dry_run
{
    my $self = shift;
    my $tests = shift;
    print join("\n", @$tests, "");
    return 0;
}

# Stolen directly from blib.pm
sub _blibdirs {
    my $self = shift;
    my $dir = File::Spec->curdir;
    if ($^O eq 'VMS') {
        ($dir = VMS::Filespec::unixify($dir)) =~ s-/\z--;
    }
    my $archdir = "arch";
    if ( $^O eq "MacOS" ) {
        # Double up the MP::A so that it's not used only once.
        $archdir = $MacPerl::Architecture = $MacPerl::Architecture;
    }

    my $i = 5;
    while ($i--) {
        my $blib      = File::Spec->catdir( $dir, "blib" );
        my $blib_lib  = File::Spec->catdir( $blib, "lib" );
        my $blib_arch = File::Spec->catdir( $blib, $archdir );

        if ( -d $blib && -d $blib_arch && -d $blib_lib ) {
            return ($blib_arch,$blib_lib);
        }
        $dir = File::Spec->catdir($dir, File::Spec->updir);
    }
    warn "Could not find blib dirs";
    return;
}

sub _get_backend_params_keys
{
    return [qw(Verbose Debug Timer Test_Interpreter Switches)];
}

sub _get_backend_params
{
    my $self = shift;
    my $ret = +{};
    foreach my $key (@{$self->_get_backend_params_keys()})
    {
        my $value = $self->$key();
        if (ref($value) eq "ARRAY")
        {
            $ret->{$key} = join(" ", @$value);
        }
        else
        {
            if (defined($value))
            {
                $ret->{$key} = $value;
            }
        }
    }
    return $ret;
}

sub _usage
{
    my $self = shift;
    my $verbosity = shift;

    Pod::Usage::pod2usage(
        {
            '-verbose' => $verbosity,
            '-exitval' => 0,
        }
    );

    return;
}

sub _default_ext
{
    my $self = shift;
    my $ext = shift;
    return (@$ext ? $ext : ["t"]);
}

sub _normalize_extensions
{
    my $self = shift;

    my $ext = shift;
    $ext = [ map { split(/,/, $_) } @$ext ];
    foreach my $e (@$ext)
    {
        $e =~ s{^\.}{};
    }
    return $ext;
}

sub _set_ext
{
    my $self = shift;
    my $ext = $self->_default_ext(shift);

    $self->ext_regex_string('\.(?:' .
        join("|", map { quotemeta($_) }
            @{$self->_normalize_extensions($ext)}
        )
        . ')$'
    );
    $self->_set_ext_re();
}

sub _set_ext_re
{
    my $self = shift;
    my $s = $self->ext_regex_string();
    $self->ext_regex(qr/$s/);
}

sub _post_process_test_files_list
{
    my ($self, $list) = @_;
    if ($self->shuffle())
    {
        return $self->_perform_shuffle($list);
    }
    else
    {
        return $list;
    }
}

sub _perform_shuffle
{
    my ($self, $list) = @_;
    my @ret = @$list;
    my $i = @ret;
    while ($i)
    {
        my $place = int(rand($i--));
        @ret[$i,$place] = @ret[$place, $i];
    }
    return \@ret;
}

sub _get_arguments
{
    my $self = shift;
    my $args = $self->extra_argv();
    if (defined($args) && @$args)
    {
        return $args;
    }
    else
    {
        return [ File::Spec->curdir() ];
    }
}

sub _get_test_files
{
    my $self = shift;
    return
        $self->_post_process_test_files_list(
            [
                map
                { $self->_get_test_files_from_arg($_) }
                @{$self->_get_arguments()}
            ]
        );
}

sub _get_test_files_from_arg
{
    my ($self, $arg) = @_;
    return (map { $self->_get_test_files_from_globbed_entry($_) } glob($arg));
}

sub _get_test_files_from_globbed_entry
{
    my ($self, $entry) = @_;
    if (-d $entry)
    {
        return $self->_get_test_files_from_dir($entry);
    }
    else
    {
        return $self->_get_test_files_from_file($entry);
    }
}

sub _get_test_files_from_file
{
    my ($self, $entry) = @_;
    return ($entry);
}

sub _get_test_files_from_dir
{
    my ($self, $path) = @_;
    if (opendir my $dir, $path)
    {
        my @files = sort readdir($dir);
        closedir($dir);
        return
            (map { $self->_get_test_files_from_dir_entry($path, $_) } @files);
    }
    else
    {
        warn "$path: $!\n";
        return ();
    }
}

sub _should_ignore_dir_entry
{
    my ($self, $dir, $file) = @_;
    return
        (
            ($file eq File::Spec->updir()) ||
            ($file eq File::Spec->curdir()) ||
            ($file eq ".svn") ||
            ($file eq "CVS")
        );
}

sub _get_test_files_from_dir_entry
{
    my ($self, $dir, $file) = @_;
    if ($self->_should_ignore_dir_entry($dir, $file))
    {
        return ();
    }
    my $path = File::Spec->catfile($dir, $file);
    if (-d $path)
    {
        return $self->_get_test_files_from_dir_path($path);
    }
    else
    {
        return $self->_get_test_files_from_file_path($path);
    }
}

sub _get_test_files_from_dir_path
{
    my ($self, $path) = @_;
    if ($self->recurse())
    {
        return $self->_get_test_files_from_dir($path);
    }
    else
    {
        return ();
    }
}

sub _get_test_files_from_file_path
{
    my ($self, $path) = @_;
    if ($path =~ $self->ext_regex())
    {
        return ($path);
    }
    else
    {
        return ();
    }
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

1;
