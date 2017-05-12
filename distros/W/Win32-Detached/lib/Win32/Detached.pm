use strict;
use warnings;

package Win32::Detached;
BEGIN {
  $Win32::Detached::VERSION = '1.103080';
}

# ABSTRACT: daemonize perl scripts under windows, without a console window


use Win32;
use Win32::Process;
use Cwd;
use English;

check_args();


sub skip_flag { '--no_detach' }


sub check_args {

    if ( grep { $_ eq skip_flag() } @ARGV ) {
        @ARGV = grep { $_ ne skip_flag() } @ARGV;
        return;
    }

    return if $COMPILING;
    return if $PROGRAM_NAME =~ m/release-pod-coverage/;

    return detach();
}


sub detach {

    my @cmd_parts = ( $EXECUTABLE_NAME, $PROGRAM_NAME, @ARGV, skip_flag() );
    @cmd_parts = map { tr/ // ? qq["$_"] : $_ } @cmd_parts; # check all components for spaces and wrap if necessary

    # build command string
    my $command = join " ", @cmd_parts;

    my $process;
    my @proc_params = (
        \$process,
        $EXECUTABLE_NAME,
        $command,
        0,
        DETACHED_PROCESS,
        cwd
    );

    Win32::Process::Create( @proc_params ) or die Win32::FormatMessage(Win32::GetLastError());

    exit;
}

1;

__END__
=pod

=head1 NAME

Win32::Detached - daemonize perl scripts under windows, without a console window

=head1 VERSION

version 1.103080

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Win32::Detached; # at this point the script will background itself
                         # if started via Win->Run or double-clicking,
                         # the console window will close

    sleep 10; # so you can see the process in the task manager

    print "moo"; # this will not show up anywhere

On the command line:

    # to daemonize:
    script.pl

    # to run normally
    script.pl --no_detach

=head1 DESCRIPTION

First off, I am not the one who originally wrote this. I found it years ago on Perlmonks, only remembered it now and
figuring it was time to get it out.

This module allows you to daemonize any perl script under windows. This may be useful to have a service/daemon in the
background, or when running a desktop application and being annoyed by the console window.

When the module is loaded it inspects @ARGV for presence of "--no_detach" If it finds it, it removes it from @ARGV and
then returns, doing nothing else.

If that flag is not present however it relaunches the script that loaded it with the same arguments (plus --no_detach),
in the same working directory. Then it exits the current script. You can think of it as cloning itself and then
comitting suicide.

Take note: You will want to use this module before any other module that actually executes code.

If you don't like the name of the skip flag, you can override the sub Win32::Detached::_skip_flag however you like.
Easiest is probably Sub::Exporter and its "into" facility.

=head1 SUBROUTINES

=head2 skip_flag

Returns the default command line argument string which signals that the script should run normally and not detach.

=head2 check_args

Checks the command line and certain system variables to see whether we want to detach or not. Cleans ARGV and returns
if not.

=head2 detach

Builds the command line for the detached clone, executes it to start the clone and then exits itself.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

