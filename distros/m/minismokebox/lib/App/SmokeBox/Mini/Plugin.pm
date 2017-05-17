package App::SmokeBox::Mini::Plugin;
$App::SmokeBox::Mini::Plugin::VERSION = '0.68';
#ABSTRACT: minismokebox plugins

use strict;
use warnings;

qq[Smokin' plugins];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBox::Mini::Plugin - minismokebox plugins

=head1 VERSION

version 0.68

=head1 DESCRIPTION

This document describes the App::SmokeBox::Mini::Plugin system for
L<App::SmokeBox::Mini> and L<minismokebox>.

Plugins are a mechanism for providing additional functionality to
L<App::SmokeBox::Mini> and L<minismokebox>.

It is assumed that plugins will be L<POE> based and consist of at least one
L<POE::Session>.

=head1 INITIALISATION

The plugin constructor is C<init>. L<App::SmokeBox::Mini> uses
L<Module::Pluggable> to find plugins beneath the App::SmokeBox::Mini::Plugin
namespace and will attempt to call C<init> on each plugin class that it finds.

C<init> will be called with one parameter, a hashref that contains keys for each
section of the L<minismokebox> configuration file, (which utilises L<Config::Tiny>).

The role of the plugin is to determine if an appropriate section exists for its
own configuration.

If no appropriate configuration exists, then C<init> must return C<undef>.

If appropriate configuration does exist, then the plugin may start a L<POE::Session>.

L<App::SmokeBox::Mini> will watch for a C<_child> event indicating that it has gained
a plugin child session. It will detach this child after making a note of the child's
session ID which it will use to send the following events.

=head1 EVENTS

=over

=item C<sbox_perl_info>

Sent when C<App::SmokeBox::Mini> has determined the C<perl> version, archname and OS version
of the given C<perl> executable.

  ARG0, will be the perl version
  ARG1, will be the archname
  ARG2, will be the OS version

=item C<sbox_smoke>

Sent on process completion with a hashref as C<ARG0>:

  'job', the POE::Component::SmokeBox::Job object of the job;
  'result', a POE::Component::SmokeBox::Result object containing the results;
  'submitted', the epoch time in seconds when the job was submitted;

The results will be same as returned by L<POE::Component::SmokeBox::Backend>. They may be obtained by querying the
L<POE::Component::SmokeBox::Result> object:

  $_[ARG0]->{result}->results() # produces a list

Each result is a hashref:

  'log', an arrayref of STDOUT and STDERR produced by the job;
  'PID', the process ID of the POE::Wheel::Run;
  'status', the $? of the process;
  'start_time', the time in epoch seconds when the job started running;
  'end_time', the time in epoch seconds when the job finished;
  'idle_kill', only present if the job was killed because of excessive idle;
  'excess_kill', only present if the job was killed due to excessive runtime;
  'term_kill', only present if the job was killed due to a poco shutdown event;

=item C<sbox_stop>

Sent when the smokebox is terminating. Your plugin session should terminate after receiving this
event. The following data will be passed:

  ARG0, the start time of the smoke process in epoch time;
  ARG1, the finish time of the smoke process in epoch time;
  ARG2, the total number of jobs processed;
  ARG3, the number of jobs killed for being idle;
  ARG4, the number of jobs killed for running over the excess time;
  ARG5, the average job runtime in seconds;
  ARG6, the minimum job runtime in seconds;
  ARG7, the maximum job runtime in seconds;

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
