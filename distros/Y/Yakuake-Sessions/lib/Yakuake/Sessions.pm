package Yakuake::Sessions;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.15.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Moo;
use Class::Usul::Constants  qw( TRUE );

extends q(Yakuake::Sessions::Base);
with    q(Yakuake::Sessions::TraitFor::DBus);
with    q(Yakuake::Sessions::TraitFor::TabTitles);
with    q(Yakuake::Sessions::TraitFor::FileData);
with    q(Yakuake::Sessions::TraitFor::Management);

# Construction
before 'run' => sub {
   $_[ 0 ]->quiet( TRUE ); return;
};

1;

__END__

=pod

=encoding utf8

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Yakuake-Sessions.svg)](http://badge.fury.io/pl/Yakuake-Sessions)

=end markdown

=head1 WARNING

Backwardly incompatible changes to the Konsole API between 4.4 and
4.8.4 broke this application (https://bugs.kde.org/show_bug.cgi?id=338914).
A patch has been applied but it's gross

=head1 Name

Yakuake::Sessions - Session Manager for the Yakuake Terminal Emulator

=head1 Version

This documents version v0.15.$Rev: 1 $ of L<Yakuake::Sessions>

=head1 Synopsis

   # To reduce typing define some shell aliases
   alias ys='yakuake_session'

   # Create some Yakuake sessions. Set each session to a different directory.
   # Run some commands in some of the sessions like an HTTP web development
   # server or tail -f on a log file. Set the tab titles for each session.
   # Now create a profile called dev
   ys create dev

   # Subsequently reload the dev profile
   ys load dev

   # Show the contents of the dev profile
   ys show dev

   # Edit the contents of the dev profile
   ys edit dev

   # Delete the dev profile
   ys delete dev

   # Command line help
   ys -? | -H | -h [sub-command] | list_methods | dump_self

=head1 Description

Create, edit, load session profiles for the Yakuake Terminal Emulator. Sets
and manages the tab title text

=head1 Configuration and Environment

Reads configuration from F<~/.yakuakue_sessions/yakuake_session.json> which
might look like;

   {
      "doc_title": "Perl",
      "tab_title": "Oo.!.oO"
   }

See the L<config class|Yakuake::Sessions::Config> for the full list of
configuration attributes

Defines the following list of attributes which can be set from the command
line;

=over 3

=item C<config_dir>

Directory containing the configuration files. Defaults to
F<~/.yakuake_sessions>

=item C<editor>

The editor used to edit profiles. Can be set from the configuration
file. Defaults to the environment variable C<EDITOR> or if unset
C<emacs>

=item C<force>

Overwrite the output file if it already exists

=item C<profile_dir>

Directory to store the session profiles in

=item C<storage_class>

File format used to store session data. Defaults to the config class
value; C<JSON>

=back

Modifies these methods in the base class

=over 3

=item C<run>

=back

=head1 Subroutines/Methods

=head2 create

   yakuake_session create <profile_name>

Creates a new session profile in the F<profile_dir>. Calls L</dump>

=head2 delete

   yakuake_session delete <profile_name>

Deletes the specified session profile

=head2 dump

   yakuake_session dump <path>

Dumps the current sessions to file. For each tab it captures the
current working directory, the command being executed, the tab title text,
and which tab is currently active

=head2 edit

   yakuake_session edit <profile_name>

Edit a session profile

=head2 list

   yakuake_session list

List the session profiles stored in the F<profile_dir>

=head2 load

   yakuake_session load <profile_name>

Load the specified profile, recreating the tabs with their title text,
current working directories and executing commands

=head2 select

   yakuakge_session select

Select the profile to load from the displayed list

=head2 set_tab_title

   yakuake_session set_tab_title <title_text>

Sets the current tabs title text to the specified value. Defaults to the
vale supplied in the configuration

=head2 set_tab_title_for_project

   yakuake_session set_tab_title_for_project <title_text>

Set the current tabs title text to the specified value. Must supply a
title text. Will save the project name for use by
C<yakuake_session_tt_cd>

=head2 show

   yakuake_session show <profile_name>

Display the contents of the specified session profile

=head1 Diagnostics

Turning on debug, add C<-D> to the command line, causes the session dump
and load subroutines to display the session tabs data

The C<list_methods> command lists all of the callable the methods and
their abstracts

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<Net::DBus>

=back

=head1 Incompatibilities

None

=head1 Bugs and Limitations

It is necessary to edit new session profiles and manually escape the shell
meta characters embeded in the executing commands

There are no known bugs in this module.Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Yakuake-Sessions. Source code
is on Github git://github.com/pjfl/Yakuake-Sessions.git. Patches and
pull requests are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2014 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

