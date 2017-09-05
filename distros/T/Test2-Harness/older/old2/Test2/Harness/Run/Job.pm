package Test2::Harness::Run::Job;
use strict;
use warnings;

use Carp qw/croak/;
use Test2::Util qw/CAN_REALLY_FORK/;

use Test2::Harness::Run::Job::Result;

use Test2::Harness::HashBase qw/-id -file -config/;

sub start {
    my $self = shift;
    my $config = $self->config;

    

    return $self->_start_simple  if $^O eq 'MSWin32';
    return $self->_start_preload if CAN_REALLY_FORK && $config->preload && !$self->file->no_preload;
    return $self->_start_open3;
}

sub _start_simple {
    my $self = shift;

    my %env = (
        T2_FORMATTER => 'Stream',
        T2_STREAM_SERIALIZER => 'Storable',
        T2_STREAM_FILE => ...,
    );
}

sub _start_preload {
}

sub _start_open3 {
}

1;

__END__

sub via_open3 {
    my $self = shift;
    my ($file, %params) = @_;

    return $self->via_win32(@_)
        if $^O eq 'MSWin32';

    my $env      = $params{env} || {};
    my $libs     = $params{libs};
    my $switches = $params{switches};
    my $header   = $self->header($file);

    my $in  = gensym;
    my $out = gensym;
    my $err = $self->{+MERGE} ? $out : gensym;

    my @switches;
    push @switches => map { ("-I$_") } @$libs if $libs;
    push @switches => map { ("-I$_") } split $Config{path_sep}, ($ENV{PERL5LIB} || "");
    push @switches => @$switches             if $switches;
    push @switches => @{$header->{switches}} if $header->{switches};

    # local $ENV{$_} = $env->{$_} for keys %$env;  does not work...
    my $old = {%ENV};
    $ENV{$_} = $env->{$_} for keys %$env;

    my $pid = open3(
        $in, $out, $err,
        $^X, @switches, $file
    );

    $ENV{$_} = $old->{$_} || '' for keys %$env;

    die "Failed to execute '" . join(' ' => $^X, @switches, $file) . "'" unless $pid;

    my $proc = Test2::Harness::Proc->new(
        file   => $file,
        pid    => $pid,
        in_fh  => $in,
        out_fh => $out,
        err_fh => $self->{+MERGE} ? undef : $err,
    );

    return $proc;
}

sub via_do {
    my $self = shift;
    my ($file, %params) = @_;

    my $env      = $params{env} || {};
    my $libs     = $params{libs};
    my $header   = $self->header($file);

    my ($in_read, $in_write, $out_read, $out_write, $err_read, $err_write);

    pipe($in_read, $in_write) or die "Could not open pipe!";
    pipe($out_read, $out_write) or die "Could not open pipe!";
    if ($self->{+MERGE}) {
        ($err_read, $err_write) = ($out_read, $out_write);
    }
    else {
        pipe($err_read, $err_write) or die "Could not open pipe!";
    }

    # Generate the preload list
    $self->preload_list;

    my $pid = fork;
    die "Could not fork!" unless defined $pid;

    if ($pid) {
        return Test2::Harness::Proc->new(
            file   => $file,
            pid    => $pid,
            in_fh  => $in_write,
            out_fh => $out_read,
            err_fh => $self->{+MERGE} ? undef : $err_read,
        )
    }

    close(STDIN);
    open(STDIN, '<&', $in_read) || die "Could not open new STDIN: $!";

    close(STDOUT);
    open(STDOUT, '>&', $out_write) || die "Could not open new STDOUT: $!";

    close(STDERR);
    open(STDERR, '>&', $err_write) || die "Could not open new STDERR: $!";

    unshift @INC => @$libs if $libs;
    @ARGV = ();

    $SET_ENV = sub { $ENV{$_} = $env->{$_} || '' for keys %$env };

    $DO_FILE = $file;
    $0 = $file;

    $self->reset_DATA($file);

    # Stuff copied shamelessly from forkprove
    ####################
    # if FindBin is preloaded, reset it with the new $0
    FindBin::init() if defined &FindBin::init;

    # restore defaults
    Getopt::Long::ConfigDefaults();

    # reset the state of empty pattern matches, so that they have the same
    # behavior as running in a clean process.
    # see "The empty pattern //" in perlop.
    # note that this has to be dynamically scoped and can't go to other subs
    "" =~ /^/;

    # Test::Builder is loaded? Reset the $Test object to make it unaware
    # that it's a forked off proecess so that subtests won't run
    if ($INC{'Test/Builder.pm'}) {
        if (defined $Test::Builder::Test) {
            $Test::Builder::Test->reset;
        }
        else {
            Test::Builder->new;
        }
    }

    # avoid child processes sharing the same seed value as the parent
    srand();
    ####################
    # End stuff copied from forkprove

    my $ok = eval {
        no warnings 'exiting';
        last T2_DO_FILE;
        1;
    };
    my $err = $@;

    die $err unless $err =~ m/Label not found for "last T2_DO_FILE"/;

    # Test files do not always return a true value, so we cannot use require. We
    # also cannot trust $!
    package main;
    $Test2::Harness::Runner::SET_ENV->();
    $@ = '';
    do $file;
    die $@ if $@;
    exit 0;
}

{
    no warnings 'once';
    *via_win32 = \&via_files;
}
sub via_files {
    my $self = shift;
    my ($file, %params) = @_;

    my $env      = $params{env} || {};
    my $libs     = $params{libs};
    my $switches = $params{switches};
    my $header   = $self->header($file);

    my ($in_write, $in)   = tempfile(CLEANUP => 1) or die "XXX";
    my ($out_write, $out) = tempfile(CLEANUP => 1) or die "XXX";
    my ($err_write, $err) = tempfile(CLEANUP => 1) or die "XXX";
    open(my $in_read,  '<', $in)  or die "$!";
    open(my $out_read, '<', $out) or die "$!";
    open(my $err_read, '<', $err) or die "$!";

    my @switches;
    push @switches => map { ("-I$_") } @$libs if $libs;
    push @switches => map { ("-I$_") } split $Config{path_sep}, ($ENV{PERL5LIB} || "");
    push @switches => @$switches             if $switches;
    push @switches => @{$header->{switches}} if $header->{switches};

    # local $ENV{$_} = $env->{$_} for keys %$env;  does not work...
    my $old = {%ENV};
    $ENV{$_} = $env->{$_} || '' for keys %$env;

    my $pid = open3(
        "<&" . fileno($in_read), ">&" . fileno($out_write), ">&" . fileno($err_write),
        $^X, @switches, $file
    );

    $ENV{$_} = $old->{$_} || '' for keys %$env;

    die "Failed to execute '" . join(' ' => $^X, @switches, $file) . "'" unless $pid;

    my $proc = Test2::Harness::Proc->new(
        file   => $file,
        pid    => $pid,
        in_fh  => $in_write,
        out_fh => $out_read,
        err_fh => $err_read,
    );

    return $proc;
}



    
    if ($config->preload && $file->can_preload) {
        return (
            $self->file->filename,
            sub { $config->set_environment },
        )
    }
}

1;

__END__

sub is_complete {

}

sub step {
    my $self = shift;

    # Find parser unless found
    # Get some facets

    my $work = 1;

    return $work;
}

1;
