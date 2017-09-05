package Test2::Harness;
use strict;
use warnings;

our $VERSION = '0.000014';

use File::Find();
use File::Spec();

use Carp qw/croak/;
use Test2::Util qw/pkg_to_file/;
use Scalar::Util qw/blessed/;

use Test2::Harness::TestFile;

use Test2::Harness::JSON qw/encode_json decode_json/;
use Test2::Harness::Util qw/read_file write_file/;

use Test2::Harness::HashBase qw{
    -workdir
    -rootdir
    -jobs
    -libs -lib -blib
    -preload -switches
    -merge -verbose

    -output_events
    -output_muxing

    -search
    -unsafe_inc

    -worker
    -parser
    -pipeline
    -renderer
};

sub init {
    my $self = shift;

    require Test2::Plugin::OpenFixPerlIO
        if $self->{+OUTPUT_EVENTS} || $self->{+OUTPUT_MUXING};

    croak "The 'workdir' attribute is required"
        unless $self->{+WORKDIR};

    $self->{+JOBS}    ||= 1;
    $self->{+ROOTDIR} ||= File::Spec->curdir;

    $self->{+LIBS}   ||= [];
    $self->{+SEARCH} ||= ['t'];

    unless (defined $self->{+UNSAFE_INC}) {
        if (defined $ENV{PERL_USE_UNSAFE_INC}) {
            $self->{+UNSAFE_INC} = $ENV{PERL_USE_UNSAFE_INC};
        }
        else {
            $self->{+UNSAFE_INC} = 1;
        }
    }

    $self->{+WORKER}   ||= 'Test2::Harness::Worker';
    $self->{+PARSER}   ||= 'Test2::Harness::Parser';
    $self->{+RENDERER} ||= 'Test2::Harness::Renderer';

    $self->{+PIPELINE} ||= [
        'Test2::Harness::Pipeline::Assembler',
        'Test2::Harness::Pipeline::Validator'
    ];

    unshift @{$self->{+PIPELINE}} => 'Test2::Harness::Pipeline::Muxer'
        if $self->{+OUTPUT_MUXING};

    for my $pkg (@{$self}{WORKER(), PARSER(), RENDERER()}, @{$self->{+PIPELINE}}) {
        my $file = pkg_to_file($pkg);
        require $file;
    }
}

sub load_preloads {
    my $self = shift;
    my $load = $self->{+PRELOAD} or return 0;

    if ($self->{+OUTPUT_EVENTS} && $self->{+OUTPUT_MUXING}) {
        require Test2::Plugin::IOSync;
    }
    elsif ($self->{+OUTPUT_EVENTS}) {
        require Test2::Plugin::IOEvents;
    }
    elsif ($self->{+OUTPUT_MUXING}) {
        require Test2::Plugin::IOMuxer;
    }

    unshift @INC => $self->all_libs;
    for my $mod (@$load) {
        my $file = pkg_to_file($mod);
        require $file;
    }

    return 1;
}

sub load {
    my $class = shift;
    my ($file) = @_;

    my $json = read_file($file);
    my $data = decode_json($json);

    return $class->new(%$data);
}

sub save {
    my $self = shift;
    my ($file) = @_;

    my $json = encode_json({%$self});
    write_file($file, $json);

    return $json;
}

sub find_tests {
    my $self  = shift;
    my $tests = $self->{+SEARCH};

    my (@files, @dirs);

    for my $item (@$tests) {
        push @files => Test2::Harness::TestFile->new(filename => $item) and next if -f $item;
        push @dirs  => $item and next if -d $item;
        die "'$item' does not appear to be either a file or a directory.\n";
    }

    my $curdir = File::Spec->curdir();
    chdir($self->{+ROOTDIR}) if $self->{+ROOTDIR};

    my $ok = eval {
        File::Find::find(
            sub {
                no warnings 'once';
                return unless -f $_ && m/\.t2?$/;
                push @files => Test2::Harness::TestFile->new(filename => $File::Find::name);
            },
            @dirs
        );
        1;
    };
    my $error = $@;

    chdir($curdir);

    die $error unless $ok;

    return sort { $a->filename cmp $b->filename } @files;
}

sub make_run {
    my $self = shift;

    my $run_id = join '-' => ($$, time);
    my $run_dir = File::Spec->rel2abs(File::Spec->catdir($self->{+WORKDIR}, $run_id));

    mkdir($run_dir) or die "Could not make run dir '$run_dir': $!";

    $self->save(File::Spec->catfile($run_dir, 'config'));

    return ($run_id, $run_dir);
}

sub all_libs {
    my $self = shift;

    my @libs;

    push @libs => 'lib' if $self->{+LIB};
    push @libs => 'blib/lib', 'blib/arch' if $self->{+BLIB};
    push @libs => @{$self->{+LIBS}} if $self->{+LIBS};

    return @libs;
}

sub perl_command {
    my $self   = shift;
    my %params = @_;

    my @cmd = ($^X);

    my @libs;
    if ($params{include_harness_lib} || $self->{+OUTPUT_MUXING} || $self->{+OUTPUT_EVENTS}) {
        my $path = $INC{"Test2/Harness.pm"};
        $path =~ s{Test2/Harness\.pm$}{};
        $path = File::Spec->rel2abs($path);
        push @libs => $path;
    }

    push @libs => $self->all_libs;
    push @libs => @{$params{libs}}  if $params{libs};

    push @cmd => map { "-I$_" } @libs;

    my @switch_list;
    push @switch_list => $self->{+SWITCHES}   if $self->{+SWITCHES};
    push @switch_list => @{$params{switches}} if $params{switches};

    for my $switches (@switch_list) {
        for (my $i = 0; $i < @$switches; $i++) {
            my $switch = $switches->[$i];
            my $next   = $switches->[$i + 1];

            if ($next && substr($next, 0, 1) ne '-') {
                push @cmd => ($switch, $next);
                $i++;
                next;
            }

            push @cmd => $switch;
        }
    }

    my $add_env = $params{env};
    return sub {
        my $code = shift;
        local $ENV{PERL_USE_UNSAFE_INC} = $self->{+UNSAFE_INC};

        local $ENV{HARNESS_CLASS}      = blessed($self);
        local $ENV{HARNESS_ACTIVE}     = 1;
        local $ENV{HARNESS_VERSION}    = $VERSION;
        local $ENV{HARNESS_IS_VERBOSE} = $self->{+VERBOSE} || 0;
        local $ENV{HARNESS_JOBS}       = $self->{+JOBS};

        local $ENV{T2_HARNESS_CLASS}      = blessed($self);
        local $ENV{T2_HARNESS_ACTIVE}     = 1;
        local $ENV{T2_HARNESS_VERSION}    = $VERSION;
        local $ENV{T2_HARNESS_IS_VERBOSE} = $self->{+VERBOSE} || 0;
        local $ENV{T2_HARNESS_JOBS}       = $self->{+JOBS};

        return $code->(@cmd) unless $add_env;

        local $ENV{$_} = $add_env->{$_} for keys %$add_env;
        return $code->(@cmd);
    };
}

1;
