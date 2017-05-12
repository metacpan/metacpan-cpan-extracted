package App::Metabase::Relayd::Plugin;
$App::Metabase::Relayd::Plugin::VERSION = '0.40';
#ABSTRACT: metabase-relayd plugins

use strict;
use warnings;

qq[Smokin' plugins];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Metabase::Relayd::Plugin - metabase-relayd plugins

=head1 VERSION

version 0.40

=head1 DESCRIPTION

This document describes the App::Metabase::Relayd::Plugin system for
L<App::Metabase::Relayd> and L<metabase-relayd>.

Plugins are a mechanism for providing additional functionality to
L<App::Metabase::Relayd> and L<metabase-relayd>.

It is assumed that plugins will be L<POE> based and consist of at least one
L<POE::Session>.

=head1 INITIALISATION

The plugin constructor is C<init>. L<App::Metabase::Relayd> uses
L<Module::Pluggable> to find plugins beneath the App::Metabase::Relayd::Plugin
namespace and will attempt to call C<init> on each plugin class that it finds.

C<init> will be called with one parameter, a hashref that contains keys for each
section of the L<metabase-relayd> configuration file, (which utilises L<Config::Tiny>).

The role of the plugin is to determine if an appropriate section exists for its
own configuration.

If no appropriate configuration exists, then C<init> must return C<undef>.

If appropriate configuration does exist, then the plugin may start a L<POE::Session>.

L<App::Metabase::Relayd> will watch for a C<_child> event indicating that it has gained
a plugin child session. It will detach this child after making a note of the child's
session ID which it will use to send the following events.

=head1 EVENTS

=over

=item C<mbrd_received>

C<ARG0> will be a C<HASHREF> with the following keys:

 archname
 distfile
 grade
 osname
 osversion
 perl_version
 textreport

C<ARG1> will be the IP address of the client that sent the report.

=back

=head1 SEE ALSO

L<App::Metabase::Relayd>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
