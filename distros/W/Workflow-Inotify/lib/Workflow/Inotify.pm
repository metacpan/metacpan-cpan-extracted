package Workflow::Inotify;

# this package just provides pod

use strict;
use warnings;

our $VERSION = '1.0.5'; ## no critic (RequireInterpolation)

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

inotify.pl - script to daemonize a C<Linux::Inotify2> handler

=head1 SYNOPSIS

 inotify.pl --config=inotify.cfg

=head1 DESCRIPTION

Script harness for C<Workflow::Inotify::Handler> classes.  This is
typically launched as a daemon by the F<inotifyd> script or using a
C<systemctl> service description.

See L<Workflow::Inotify::Handler>

=head1 HOW IT WORKS

The C<inotify.pl> script reads a C<.ini> style configuration file and
installs handlers implemented by Perl classes to process kernel events
generated from file or directory changes. Using L<Linux::Inotify2>,
the script creates instantiates one or more handlers which process
directory events and then daemonizes this script.

=head2 The Configuration File

The configuration file is a C<.ini> style configuration file
consisting of a C<[global]> section and one or more sections named
using the convention: C<[watch_{name}]>.

Boolean values can be set as '0', '1', 'true', 'false', 'on', 'off',
'yes', or 'no'. Take your pick.

Example:

 [global]
 daemonize = yes
 logfile = /var/log/inotify.log
 block = yes
 perl5lib = $HOME/lib/perl5
 
 [watch_tmp]
 dir = /tmp
 mask = IN_MOVE_TO | IN_CLOSE_WRITE
 handler = Workflow::Inotify::Handler

Sections are described below.

=over

=item C<[global]>

The C<global> section contains configuration values used throughout
the script. All of the values in the C<global> section are optional.

=over

=item * sleep

Amount of time in seconds to sleep after polling for a watch event.

=item * block

Boolean that indicates if the watcher should block waiting for an
event. If you set C<block> to a false value, you should also consider
a sleep value.

default: true

=item * logfile

Name of a file that will receive all STDERR and STDOUT messages.

=item * perl5lib

One or more paths to add to C<@INC>. Paths should be ':' separated.

Example:

 perl5lib = $HOME/lib/perl5:/usr/local/lib/perl5

Words that begin with '$' are interpretted to be environment variables
(for this variable only).

=item * verbose

Output messages at beginning of script.

default: true

=item * daemonize

Boolean that indicates whether the script should be daemonize using L<Proc::Daemon>.

default: false

=back

=item C<[watch_{name}]>

The C<watch> section contains settings for the directories to watch.

=over

=item * dir

Directory to watch.

Example:

 [watch_example]

 dir =  I</var/spool/junk>.

=item * mask

One or more C<inotify> event names as described in I<man 7
inotify>. These events should be pipe delimited (as in "oring" them
together).

Example:

 mask = IN_MOVED_FROM | IN_MOVED_TO

These are also described in L<Workflow::Inotify::Handler>.

=item * handler

The name of a Perl class that has at least a C<handler()> method. This
handler will be called with a L<Linux::Inotify::Event> object.

Example:

 handler = Workflow::Inotify::Handler

=back

=back

=head2 Application Configuration

You can create a section in the configuration file that is named for
the handler class. For example, if your handler class is
C<Worflow::S3::Uploader>, then create a section in the configuration
file named C<workflow_s3_uploader>. Place any values you wish in that
section. The configuration object is passed to your handler's C<new()>
method so you can access the values as needed. The configuration
object is an instance of L<Config::IniFiles>.

If you use the parent class L<Workflow::Inotify::Handler>, its
C<new()> method will automatically create setters and getters for these
values.

See L<Workflow::Inotify::Handler> for more details.

=head1 VERSION

This documentation refers to version 1.0.5

=head1 REPOSITORY

L<https://github.com/rlauer6/perl-Workflow-Inotify.git>

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 SEE ALSO 

L<Linux::Inotify2>, L<Config::IniFiles>

=cut
