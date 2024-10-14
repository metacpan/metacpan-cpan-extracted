package Tiny::Prof;

=head1 LOGO

  _____ _               ____             __
 |_   _(_)_ __  _   _  |  _ \ _ __ ___  / _|
   | | | | '_ \| | | | | |_) | '__/ _ \| |_
   | | | | | | | |_| | |  __/| | | (_) |  _|
   |_| |_|_| |_|\__, | |_|   |_|  \___/|_|
                |___/

=cut

use 5.006;
use strict;
use warnings;
use File::Path      qw( make_path );
use Term::ANSIColor qw( colored );
use File::Basename  qw( basename );
use Cwd             qw( realpath );
use Time::Piece;

our $VERSION = '0.04';

=head1 NAME

Tiny::Prof - Perl profiling made simple to use.

=cut

=head1 SYNOPSIS

    use Tiny::Prof;
    my $profiler = Tiny::Prof->run;

    ...

    # $profiler goes out of scope and
    # then builds the results page.

=cut

=head1 DESCRIPTION

This module is a tool that is designed to make
profiling perl code as easy as can be.

=head2 Run Stages

 When profiling, keep in mind:
 - The stages described below.
 - the scope of what should be captured/recorded.

 Flow of Code Execution:

 |==          <-- Stage 1: Setup environment.
 |
 |====        <-- Stage 2: Beginning of code.
 |
 |========    <-- Stage 3: Start profiling.
 |
 |                (Data is collected/recorded ONLY here!)
 |
 |========    <-- Stage 4: Stop profiling.
 |
 |====        <-- Stage 5: End of code.
 |
 |==          <-- Stage 6: Restore environment
 |
 v

=head3 Stage 1: Setup Environment

These environmental variables should be setup.
Failure to do so may result in missing links
and/or data in the results!

    export PERL5OPT=-d:NYTProf
    export NYTPROF='trace=0:start=no:slowops=0:addpid=1'

    # Trace   - Set to a higher value like '1' for more details.
    # Start   - Put profiler into "standby" mode
    #           (ready, but not running).
    # AddPid  - Important when there are multiple processes.
    # SlowOps - Disabled to avoid profiling say
    #           sleep or print.

If running as a service, the environmental variables
should be stored in the service file instead.

On a Debian-based machine/box that may mean:

    systemctl status MY_SERVICE
    sudo vi /etc/systemdsystem/MY_SERVICE.service

Add this line:

    Environment="PERL5OPT=-d:NYTProf" "NYTPROF='trace=0:start=no:slowops=0:addpid=1'"

Then restsrt the service:

    systemctl restart MY_SERVICE

=head3 Stage 2: Beginning of Code

 The C<profiler> at this point is in "standby" mode:
 - Aware of source files (important for later).
 - Not actually recording anything yet.

=head3 Stage 3: Start Profiling

To start profiling is like pressing a global record
button. Anything after starting to profile will be
stored in a file in a data format
(which is mostly in machine-readable format).

=head3 Stage 4: Stop Profiling

Similary, to stop profiling is to press the global
stop button.

NOTE: It is important to stop the profile correctly
since the results would otherwise be useless.
As stated in L<Devel::NYTProf>:

 "NYTProf writes some important data to the data file
 when finishing profiling."

=head3 Stage 5: End of Code

 The C<profiler> at this point returns again to "standby" mode:
 - Aware of source files (maybe important for later).
 - Not actually recording anything anymore.

=head3 Stage 6: Restore Environment

Once profiling is done, the environment should be
restored by using:

    unset PERL5OPT
    unset NYTPROF

=cut

=head1 METHODS
    
=head2 run

Run the C<profiler> and return a special object.

    my $profiler = Tiny::Prof->run( %Options );

Will automatically close the recording data file when the object
goes out of scope (by default).

=head3 Options

    name            => "my",             # Name/title of the results.
    use_flame_graph => 0,                # Generate the flame graph (very slow).
    root_dir        => "mytprof",        # Folder with results and work data
    work_dir        => "$root_dir/work", # Folder for active work..
    log             => "$work_dir/log",  # Proflier log.

=cut

# API.
sub run {
    my ( $class, %params ) = @_;
    my $self = bless \%params, $class;

    $self->_init;
    $self->_check_env;
    $self->_clean_work_dir;
    $self->_start_profiling;

    $self;
}

sub DESTROY {
    my ( $self ) = @_;

    $self->_stop_profiling if $self->{env_ok};

    close $self->{log_fh};
}

# Setup.
sub _init {
    my ( $self ) = @_;

    $self->{name}            //= 'my';
    $self->{use_flame_graph} //= 0;
    $self->{root_dir}        //= 'nytprof';
    $self->{work_dir}        //= "$self->{root_dir}/work";
    $self->{log}             //= "$self->{work_dir}/log";

    make_path( $self->{work_dir} );
    open $self->{log_fh}, ">>", $self->{log};

    $self->{log_fh}->autoflush( 1 );
    STDOUT->autoflush( 1 );
}

sub _check_env {
    my ( $self ) = @_;

    my @needed = qw(
      PERL5OPT
      NYTPROF
    );

    for my $need ( @needed ) {
        if ( not $ENV{$need} ) {
            $self->_print( "ERROR not set: \$ENV{$need}", "RED" );
            die "Aborting!\n";
        }
    }

    $self->{env_ok} = 1;
}

sub _clean_work_dir {
    my ( $self ) = @_;

    my @files = sort glob qq(
        "$self->{work_dir}/*.out"
        "$self->{work_dir}/*.out.*"
    );

    for my $file ( @files ) {
        return if !$self->_remove_file( $file );
    }
}

sub _remove_file {
    my ( $self, $file ) = @_;

    return 1 if !-e $file;

    if ( unlink $file ) {
        $self->_print( "Removed: $file" );
    }
    else {
        $self->_print( "ERROR: Could not remove $file", "RED" );
        return;
    }

    return 1;
}

# DB.
sub _start_profiling {
    my ( $self ) = @_;

    $self->_print( "_start_profiling" );

    my $raw_file = sprintf( "$self->{work_dir}/$self->{name}_%s.out",
        $self->_get_timestamp, );
    $self->{raw_file} = $raw_file;

    $self->_print( "==> Profiling Started (writing to '$raw_file.*')",
        "YELLOW" );

    DB::enable_profile( $raw_file );
}

sub _stop_profiling {
    my ( $self ) = @_;

    DB::finish_profile();

    $self->_print( "_stop_profiling()" );

    # Rename the output file to easily indentify that its finished.
    my $Old = glob "$self->{raw_file}*";
    my $New = "$Old.finished";

    # Make sure the output file actually exists.
    if ( !-e $Old ) {
        $self->_print(
"ERROR: output file '$Old' was not created! (Perhaps someone removed it during profiling?)",
            "RED"
        );
        return;
    }

    # Make it much easier to identify when finished profiling.
    if ( !rename $Old => $New ) {
        $self->_print( "ERROR: Cannot rename '$Old' to '$New': $!", "RED" );
        return;
    }

    $self->_print( "==> Profiling Finished", "YELLOW" );

    $self->_build_html( $New );
}

# Output.
sub _print {
    my ( $self, $msg, $color ) = @_;

    $msg = colored( $msg, $color ) if $color;

    # Enrich message.
    my $TimeStamp = $self->_get_timestamp;
    $msg = "$TimeStamp [$$] $msg\n";

    # Write to STDOUT and a log.
    print $msg;
    print { $self->{log_fh} } $msg;

    return;
}

sub _get_timestamp {
    my ( $self ) = @_;

    return localtime->strftime( '%Y-%m-%d_%H-%M-%S' );
}

# NYTProf.
sub _build_html {
    my ( $self, $finished_file ) = @_;

    $self->_print( "_build_html($finished_file)" );

    my $html_dir = sprintf( "$self->{root_dir}/%s",
        basename( $finished_file ) =~ s/ \. out \. .+ //rx, );

    # Run nytprofhtml.
    my $ok = $self->_system(
        sprintf(
            "nytprofhtml --file '$finished_file' --out '$html_dir' --delete %s",
            $self->{use_flame_graph} ? '' : '--no-flame', )
    );

    # Still maybe ok if the index.html file can be found.
    if ( !$ok && -e "$html_dir/index.html" ) {
        $self->_print( "WARNING running nytprofhtml, but index.html was made\n",
            "YELLOW", );
        $ok = 1;
    }
    return if !$ok;

    $self->_show_html_link( $html_dir );
}

sub _system {
    my ( $self, $command ) = @_;

    $self->_print( colored( "==> Running: ", "YELLOW" )
          . colored( "$command", "ON_BRIGHT_BLACK" ) );

    my $output = qx($command 2>&1) // "";

    if ( $? ) {
        $command =~ / ^ (\S+) /x;    # Shorter for display.
        $self->_print( "ERROR running '$command': $?", "RED" );
        $self->_print( $output );
        return;
    }

    return 1;
}

sub _show_html_link {
    my ( $self, $html_dir ) = @_;
    my $index_path = realpath( "$html_dir/index.html" );

    if ( !-e $index_path ) {
        $self->_print( "ERROR: Could not create $index_path\n", "RED" );
        return;
    }

    $self->_print( "Created: file://$index_path", "GREEN" );
}

# Pod.

=head1 BUGS

None

... and then came along Ron :)

=cut

=head1 SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc Tiny::Prof

You can also look for information at:

L<https://metacpan.org/pod/Tiny::Prof>

L<https://github.com/poti1/tiny-prof>

=cut

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >> E<0x1f42a>E<0x1f977>

=cut

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

"\x{1f42a}\x{1f977}"
