package Yakuake::Sessions::TraitFor::DBus;

use namespace::autoclean;

use Class::Usul::Constants qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use Class::Usul::Functions qw( throw trim zip );
use Class::Usul::Time      qw( nap );
use Class::Usul::Types     qw( LoadableClass Object );
use English                qw( -no_match_vars );
use Try::Tiny;
use Moo::Role;

requires qw( debug run_cmd );

# Public attribuetes
has 'dbus_class' => is => 'lazy', isa => LoadableClass, default => 'Net::DBus';

has 'service'    => is => 'lazy',
   isa           => sub { $_[ 0 ]->can( 'get_object' )
                             or throw 'Attribute "service" cannot get_object' },
   default       => sub { $_[ 0 ]->dbus->get_service( 'org.kde.yakuake' ) },
   init_arg      => undef;

has 'sessions'   => is => 'lazy', isa => Object,
   default       => sub { $_[ 0 ]->service->get_object( '/yakuake/sessions' ) },
   init_arg      => undef;

has 'tabs'       => is => 'lazy', isa => Object,
   default       => sub { $_[ 0 ]->service->get_object( '/yakuake/tabs' ) },
   init_arg      => undef;

# Private attributes
has '_dbus'      => is => 'lazy',
   isa           => sub { $_[ 0 ]->can( 'get_service' )
                             or throw 'Attribute "dbus" cannot get_service' },
   default       => sub { $_[ 0 ]->dbus_class->session }, reader => 'dbus';

# Public methods
sub apply_sessions {
   my ($self, $session_tabs) = @_; my $active; my $tab_no = 0;

   $self->_close_sessions;

   for my $tab (@{ $session_tabs }) {
      my $sess_id  = $self->_maybe_add_session( $tab_no );
      my $ksess_id = $self->_get_session_map->{ $sess_id };
      my $tty_num  = $self->_get_tty_num( $ksess_id );
      my $title    = $tty_num.SPC.$tab->{title};

      # TODO: Log shows applying the right title even when result wrong
      # Problem must come after this not before. Set tab title is on the
      # tabs object, raise sessions is on the session object
      $self->log->debug( "Applying ${tab_no} ${sess_id} ${ksess_id} ${title}" );

      $self->set_tab_title_for_session( $title, $sess_id );
      $tab->{cwd   } and $self->sessions->runCommand( 'cd '.$tab->{cwd} );
      $tab->{cmd   } and $self->sessions->runCommand(       $tab->{cmd} );
      $tab->{active} and $active = $sess_id;
      $tab_no++;
   }

   defined $active and $self->sessions->raiseSession( $active );
   return;
}

sub get_sessions_from_yakuake {
   my $self        =  shift;
   my $session_map =  $self->_get_session_map;
   my $num_sesses  =  scalar keys %{ $session_map };
   my $active_sess =  $self->_get_active_session_id;
   my $tabs        =  [];

   for my $tab_no (0 .. $num_sesses - 1) {
      my $sess_id  =  $self->_get_session_at_tab( $tab_no );
      my $ksess_id =  $session_map->{ $sess_id }; defined $ksess_id or next;
      my $fgpid    =  $self->_get_session_fg_process_id( $ksess_id );
      my $pid      =  $self->_get_session_process_id( $ksess_id );

      push @{ $tabs }, {
         active    => $sess_id == $active_sess,
         cmd       => $self->_get_executing_command( $pid, $fgpid ),
         cwd       => $self->_get_current_directory( $pid ),
         title     => $self->_get_tab_title( $sess_id ),
      };
   }

   return $tabs;
}

sub set_tab_title_for_session {
   my ($self, $title, $sess_id) = @_; $title or return;

   $sess_id //= $self->_get_active_session_id;

   return $self->tabs->setTabTitle( $sess_id, $title );
}

# Private methods
sub _close_sessions {
   my $self        = shift;
   my $active_sess = $self->_get_active_session_id;
   my $borked      = FALSE;

   for my $sess_id  ($self->_get_session_ids) {
      my $ksess_id = $self->_get_session_map->{ $sess_id };
      my $fgpid    = $self->_get_session_fg_process_id( $ksess_id );
      my $pid      = $self->_get_session_process_id( $ksess_id );

      $pid != $fgpid and kill 'TERM', $fgpid;

      # Konsole removed the close method from the API after 4.4 before 4.8.4
      # Utterly useless bastards
      unless ($borked) {
         try   { $self->_get_session_object( $ksess_id )->close }
         catch { $borked = TRUE };
      }

      if ($borked and $sess_id != $active_sess) {
         $self->sessions->raiseSession( $sess_id );
         $self->sessions->runCommand( 'exit' );
         sleep 1;
      }
   }

   return;
}

sub _get_active_session_id {
   return int $_[ 0 ]->sessions->activeSessionId;
}

sub _get_current_directory {
   my ($self, $pid) = @_; my $cmd = [ 'pwdx', $pid ];

   my $out = $self->run_cmd( $cmd, { debug => $self->debug } )->stdout;

   return trim( (split m{ : }msx, $out)[ 1 ] );
}

sub _get_executing_command {
   my ($self, $pid, $fgpid) = @_; $pid == $fgpid and return NUL;

   my $cmd = [ qw( ps --format command --no-headers --pid ), $fgpid ];

   $cmd = trim $self->run_cmd( $cmd, { debug => $self->debug } )->stdout;

   return $cmd =~ m{ \A perl (.+) $PROGRAM_NAME }msx ? NUL : $cmd;
}

sub _get_ksession_ids {
   return ( sort   { $a <=> $b }
            map    { m{ name = [\"] (\d+) [\"] }mx }
            grep   { m{ <node \s+ name }mx }
            split m{ \n }msx,
            $_[ 0 ]->service->get_object( '/Sessions' )->Introspect );
}

sub _get_session_at_tab {
   return int $_[ 0 ]->tabs->sessionAtTab( $_[ 1 ] );
}

sub _get_session_fg_process_id {
   return $_[ 0 ]->_get_session_object( $_[ 1 ] )->foregroundProcessId;
}

sub _get_session_ids {
   return ( sort   { $a <=> $b }
            map    { int $_ }
            split m{ , }msx, $_[ 0 ]->sessions->sessionIdList );
}

sub _get_session_map {
   return { zip $_[ 0 ]->_get_session_ids, $_[ 0 ]->_get_ksession_ids };
}

sub _get_session_object {
   return $_[ 0 ]->service->get_object( '/Sessions/'.$_[ 1 ] );
}

sub _get_session_process_id {
   return $_[ 0 ]->_get_session_object( $_[ 1 ] )->processId;
}

sub _get_tab_title {
  (my $title = $_[ 0 ]->tabs->tabTitle( $_[ 1 ] ) ) =~ s{ \A \d+ \s+ }{}mx;

   return $title;
}

sub _get_tty_num {
   my ($self, $ksess_id) = @_; defined $ksess_id or return '?';

   my $pid = $self->_get_session_process_id( $ksess_id );
   my $cmd = [ qw( ps --no-headers -o tty -p ), $pid ];

   return (split m{ [/] }mx, $self->run_cmd( $cmd )->out)[ -1 ];
}

sub _maybe_add_session {
   my ($self, $tab_no) = @_; my $sess_id = $self->_get_active_session_id;

   $tab_no > 0 or return $sess_id;

   my $old_id = $sess_id; $self->sessions->addSession;

   while (not length $sess_id or $sess_id <= $old_id) {
      nap $self->config->nap_time; $sess_id = $self->_get_active_session_id;
   }

   return $sess_id;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Yakuake::Sessions::TraitFor::DBus - Interface with DBus

=head1 Synopsis

   use Moo;

   extends 'Yakuake::Sessions::Base';
   with    'Yakuake::Sessions::TraitFor::DBus';

=head1 Description

Abstract away the mechanics of communicating with Yakuake via DBus

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<dbus_class>

A lazy loaded class which defaults to L<Net::DBus>

=item C<service>

A lazy object ref for the C<org.kde.yakuake> DBus service

=item C<sessions>

A lazy object ref for the C</yakuake/sessions> DBus service object

=item C<tabs>

A lazy object ref for the C</yakuake/tabs> DBus service object

=back

=head1 Subroutines/Methods

=head2 apply_sessions

   $self->apply_sessions( $session_tabs );

Apply a profile of sessions

=head2 get_sessions_from_yakuake

   $session_tabs = $self->get_sessions_from_yakuake;

Generate a profile of sessions

=head2 set_tab_title_for_session

   $self->set_tab_title_for_session( $tab_title, $session_id );

Sets the tab title for the session. The tab title is required. The
session id defaults to the currently active session

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Moo::Role>

=item L<Net::DBus>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

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
