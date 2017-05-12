# $Id: Builder.pm 2297 2011-01-22 12:07:52Z guillomovitch $

package Youri::Package::RPM::Builder;

=head1 NAME

Youri::Package::RPM::Builder - Build RPM packages

=head1 SYNOPSIS

    my $builder = Youri::Package::RPM::Builder->new();
    $builder->build('foo');

=head1 DESCRIPTION

This module builds rpm packages.

=cut

use strict;
use warnings;

use Carp;
use POSIX qw(setlocale LC_ALL);
use String::ShellQuote;
use Youri::Package::RPM 0.002;
use version; our $VERSION = qv('0.3.0');

# we rely on parsing rpm errors strings, so we have to ensure locale neutrality
setlocale( LC_ALL, "C" );

my $wrapper_class = Youri::Package::RPM->get_wrapper_class();

=head1 CLASS METHODS

=head2 new(%options)

Creates and returns a new Youri::Package::RPM::Builder object.

Available options:

=over

=item verbose $level

verbosity level (default: 0).

=item topdir $topdir

rpm top-level directory (default: rpm %_topdir macro).

=item sourcedir $sourcedir

rpm source directory (default: rpm %_sourcedir macro).

=item build_requires_callback $callback

callback to execute before build, with build dependencies as argument (default:
none).

=item build_requires_command $command

external command (or list of commands) to execute before build, with build
dependencies as argument (default: none). Takes precedence over previous option.

=item build_results_callback $callback

callback to execute after build, with build packages as argument (default:
none).

=item build_results_command $command

external command (or list of commands) to execute after build, with build packages as argument (default: none). Takes precedence over previous option.

=back

=cut

sub new {
    my ($class, %options) = @_;

    if ($options{build_requires_command}) {
        $options{build_requires_callback} = sub {
            foreach my $command (
                ref $options{build_requires_command} eq 'ARRAY' ?
                    @{$options{build_requires_command}} :
                    $options{build_requires_command}
            ) {
                # we can't use multiple args version of system here, as we
                # can't assume given command is just a program name,
                # as in 'sudo rurpmi' case
                my $result = system($command . ' ' . shell_quote(@_));
                croak("Error while executing build requires command: $?\n")
                    if $result != 0;
            }
        }
    }

    if ($options{build_results_command}) {
        $options{build_results_callback} = sub {
            foreach my $command (
                ref $options{build_results_command} eq 'ARRAY' ?
                    @{$options{build_results_command}} :
                    $options{build_results_command}
            ) {
                # same issue here
                my $result = system($command . ' ' . shell_quote(@_));
                croak("Error while executing build results command: $?\n")
                    if $result != 0;
            }
        }
    }

    # force internal rpmlib configuration
    my ($topdir, $sourcedir);
    if ($options{topdir}) {
        $topdir = File::Spec->rel2abs($options{topdir});
        $wrapper_class->add_macro("_topdir $topdir");
    } else {
        $topdir = $wrapper_class->expand_macro('%_topdir');
    }
    if ($options{sourcedir}) {
        $sourcedir = File::Spec->rel2abs($options{sourcedir});
        $wrapper_class->add_macro("_sourcedir $sourcedir");
    } else {
        $sourcedir = $wrapper_class->expand_macro('%_sourcedir');
    }

    my $self = bless {
        _topdir                  => $topdir,
        _sourcedir               => $sourcedir,
        _verbose                 => defined $options{verbose}                 ?
            $options{verbose}                 : 0,
        _build_requires_callback => defined $options{build_requires_callback} ?
            $options{build_requires_callback} : undef,
        _build_results_callback  => defined $options{build_results_callback}  ?
            $options{build_results_callback}  : undef,
    }, $class;

    return $self;
}

=head1 INSTANCE METHODS

=head2 build($spec_file, %options)

Available options:

=over

=item options $options

rpm build options.

=item stage $stage

rpm build stage, among the following values: a, b, p, c, i, l or s (default: a).

=back

=cut

sub build {
    my ($self, $spec_file, %options) = @_;
    croak "Not a class method" unless ref $self;

    if (defined $options{stage}) {
        croak "invalid stage value $options{stage}"
            unless $options{stage} =~ /^[abpcils]$/;
    } else {
        $options{stage} = 'a';
    }
    if (defined $options{rpm_options}) {
        carp "deprecated rpm_options used";
    }

    my $spec;
    
    if (
        $self->{_build_requires_callback} or
        $self->{_build_results_callback}
    ) {
        $spec = $wrapper_class->new_spec($spec_file, force => 1)
            or croak "Unable to parse spec $spec_file\n";
    }

    if ($self->{_build_requires_callback}) {
        print "managing build dependencies\n"
            if $self->{_verbose};

        my $header = $spec->srcheader();
        my $db = $wrapper_class->new_transaction();
        my $pbs;
        if ($wrapper_class eq 'Youri::Package::RPM::RPM4') {
            $db->transadd($header, "", 0);
            $db->transcheck();
            $pbs = $db->transpbs();
        } else {
            $db->add_install($header, "", 0);
            $db->check();
            $pbs = $db->problems();
        }
 
        if ($pbs) {
            my @requires;
            my $pattern = qr/^
                (\S+) \s              # dependency
                (?:\S+ \s \S+ \s)?    # version
                is \s needed \s by \s # problem
                \S+                   # source package
                $/x;
            if ($wrapper_class eq 'Youri::Package::RPM::RPM4') {
                $pbs->init();
                while($pbs->hasnext()) {
                    my ($require) = $pbs->problem() =~ $pattern;
                    next unless $require;
                    push(@requires, $require);
                }
            } else {
                for (my $i=0; $i < $pbs->count; $i++) {
                    my %info = $pbs->pb_info($i);
                    my ($require) = $info{string} =~ $pattern;
                    next unless $require;
                    push(@requires, $require);
                }
            }
            $self->{_build_requires_callback}->(@requires);
        }
    }

    my $command = 
        "rpmbuild -b$options{stage}" .
        " --define '_topdir $self->{_topdir}'" .
        " --define '_sourcedir $self->{_sourcedir}'" .
        ($options{options}     ? " $options{options}"     : '') .
        ($options{rpm_options} ? " $options{rpm_options}" : '') .
        " $spec_file";
    $command .= " >/dev/null 2>&1" unless $self->{_verbose} > 1;

    my @dirs = (
        'builddir',
        ($options{stage} eq 'b' ? () : 'srcrpmdir'),
        ($options{stage} eq 's' ? () : 'rpmdir')
    );

    # check needed directories exist
    foreach my $dir (map { $wrapper_class->expand_macro("\%_$_") } @dirs) {
        next if -d $dir;
        mkdir $dir or croak "Can't create directory $dir: $!\n";
    }

    my $result = system($command) ? 1 : 0;
    croak("Build error\n")
        unless $result == 0;

    if ($self->{_build_results_callback}) {
        my @results =
            grep { -f $_ }
            $spec->srcrpm(),
            $spec->binrpm();
        print "managing build results : @results\n"
            if $self->{_verbose};
        $self->{_build_results_callback}->(@results)
    }
}

1;
