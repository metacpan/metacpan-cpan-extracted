# LOGO

     _____ _               ____             __
    |_   _(_)_ __  _   _  |  _ \ _ __ ___  / _|
      | | | | '_ \| | | | | |_) | '__/ _ \| |_
      | | | | | | | |_| | |  __/| | | (_) |  _|
      |_| |_|_| |_|\__, | |_|   |_|  \___/|_|
                   |___/

# NAME

Tiny::Prof - Perl profiling made simple to use.

# SYNOPSIS

    use Tiny::Prof;
    my $profiler = Tiny::Prof->run;

    ...

    # $profiler goes out of scope and
    # then builds the results page.

# DESCRIPTION

This module is a tool that is designed to make
profiling perl code as easy as can be.

## Run Stages

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

### Stage 1: Setup Environment

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

### Stage 2: Beginning of Code

    The C<profiler> at this point is in "standby" mode:
    - Aware of source files (important for later).
    - Not actually recording anything yet.

### Stage 3: Start Profiling

To start profiling is like pressing a global record
button. Anything after starting to profile will be
stored in a file in a data format
(which is mostly in machine-readable format).

### Stage 4: Stop Profiling

Similary, to stop profiling is to press the global
stop button.

NOTE: It is important to stop the profile correctly
since the results would otherwise be useless.
As stated in [Devel::NYTProf](https://metacpan.org/pod/Devel%3A%3ANYTProf):

    "NYTProf writes some important data to the data file
    when finishing profiling."

### Stage 5: End of Code

    The C<profiler> at this point returns again to "standby" mode:
    - Aware of source files (maybe important for later).
    - Not actually recording anything anymore.

### Stage 6: Restore Environment

Once profiling is done, the environment should be
restored by using:

    unset PERL5OPT
    unset NYTPROF

# METHODS

## run

Run the `profiler` and return a special object.

    my $profiler = Tiny::Prof->run( %Options );

Will automatically close the recording data file when the object
goes out of scope (by default).

### Options

    name            => "my",             # Name/title of the results.
    use_flame_graph => 0,                # Generate the flame graph (very slow).
    root_dir        => "mytprof",        # Folder with results and work data
    work_dir        => "$root_dir/work", # Folder for active work..
    log             => "$work_dir/log",  # Proflier log.

# BUGS

None

... and then came along Ron :)

# SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc Tiny::Prof

You can also look for information at:

[https://metacpan.org/pod/Tiny::Prof](https://metacpan.org/pod/Tiny::Prof)

[https://github.com/poti1/tiny-prof](https://github.com/poti1/tiny-prof)

# AUTHOR

Tim Potapov, `<tim.potapov[AT]gmail.com>` 🐪🥷

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
