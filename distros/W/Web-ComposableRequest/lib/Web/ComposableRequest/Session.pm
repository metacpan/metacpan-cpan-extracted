package Web::ComposableRequest::Session;

use namespace::autoclean;

use Web::ComposableRequest::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Web::ComposableRequest::Util      qw( bson64id is_arrayref throw );
use Unexpected::Types                 qw( ArrayRef Bool HashRef
                                          NonEmptySimpleStr NonZeroPositiveInt
                                          Object SimpleStr Undef );
use Moo;

# Public attributes
has 'authenticated' => is => 'rw',  isa => Bool, default => FALSE;

has 'messages'      => is => 'ro',  isa => HashRef[ArrayRef],
   builder          => sub { {} };

has 'updated'       => is => 'ro',  isa => NonZeroPositiveInt, required => TRUE;

has 'username'      => is => 'rw',  isa => SimpleStr, default => NUL;

# Private attributes
has '_config'       => is => 'ro',  isa => Object, init_arg => 'config',
   required         => TRUE;

has '_mid'          => is => 'rwp', isa => NonEmptySimpleStr | Undef;

has '_request'      => is => 'ro',  isa => Object, init_arg => 'request',
   required         => TRUE, weak_ref => TRUE;

has '_session'      => is => 'ro',  isa => HashRef, init_arg => 'session',
   required         => TRUE;

# Private functions
my $_session_attr = sub {
   my $conf = shift; my @public = qw( authenticated messages updated username );

   return keys %{ $conf->session_attr }, @public;
};

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   for my $k ($_session_attr->( $attr->{config} )) {
       my $v = $attr->{session}->{ $k }; defined $v and $attr->{ $k } = $v;
   }

   $attr->{updated} //= time;

   return $attr;
};

sub BUILD {
   my $self = shift; my $conf = $self->_config;

   my $max_time = $conf->max_sess_time;

   if ($self->authenticated and $max_time
       and time > $self->updated + $max_time) {
      my $req = $self->_request;
      my $msg = $conf->expire_session->( $self, $req );

      $self->authenticated( FALSE );
      $self->_set__mid( $self->add_status_message( $msg ) );
      $req->_log->( { level => 'debug',
                      message => $req->loc_default( @{ $msg } ) } );
   }

   return;
}

# Public methods
sub add_status_message {
   my ($self, $msg) = @_;

   is_arrayref $msg or throw 'Parameter [_1] not an array reference', [ $msg ];

   $self->messages->{ my $mid = bson64id } = $msg;

   return $mid;
}

sub collect_message_id {
   my ($self, $req) = @_;

   return $self->_mid && exists $self->messages->{ $self->_mid }
        ? $self->_mid : $req->query_params->( 'mid', { optional => TRUE } );
}

sub collect_status_message {
   my ($self, $req) = @_; my ($mid, $msg);

   $mid = $self->_mid
      and $msg = delete $self->messages->{ $mid }
      and return $req->loc( @{ $msg } );

   $mid = $req->query_params->( 'mid', { optional => TRUE } )
      and $msg = delete $self->messages->{ $mid }
      and return $req->loc( @{ $msg } );

   return;
}

sub collect_status_messages {
   my ($self, $req) = @_; my @messages = ();

   my $mid = $req->query_params->( 'mid', { optional => TRUE } )
      or return \@messages;

   my @keys = reverse sort keys %{ $self->messages };

   while (my $key = shift @keys) {
      $key gt $mid and next; my $msg = delete $self->messages->{ $key };

      push @messages, $req->loc( @{ $msg } );
   }

   return \@messages;
}

sub trim_message_queue {
   my $self = shift; my @queue = sort keys %{ $self->messages };

   while (@queue > $self->_config->max_messages) {
      my $mid = shift @queue; delete $self->messages->{ $mid };
   }

   return;
}

sub update {
   my $self = shift;

   for my $k ($_session_attr->( $self->_config )) {
      $self->_session->{ $k } = $self->$k();
   }

   $self->_session->{updated} = time;
   return;
}

before 'update' => sub {
   my $self = shift; $self->trim_message_queue; return;
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Session - Session object base class

=head1 Synopsis

   my $class_stash = {};

   my $_build_session_class = sub {
      my $self         = shift;
      my $base         = $self->_config->session_class;
      my $session_attr = $self->_config->session_attr;
      my @session_attr = keys %{ $session_attr };

      @session_attr > 0 or return $base;

      my $class = "${base}::".(substr md5_hex( join q(), @session_attr ), 0, 8);

      exists $class_stash->{ $class } and return $class_stash->{ $class };

      my @attrs;

      for my $name (@session_attr) {
         my ($type, $default) = @{ $session_attr->{ $name } };
         my $props            = [ is => 'rw', isa => $type ];

         defined $default and push @{ $props }, 'default', $default;
         push @attrs, $name, $props;
      }

      return $class_stash->{ $class } = subclass_of
         ( $base, -package => $class, -has => [ @attrs ] );
   };

   has 'session'   => is => 'lazy', isa => Object, builder => sub {
      return $_[ 0 ]->session_class->new
         ( config  => $_[ 0 ]->_config,
           log     => $_[ 0 ]->_log,
           session => $_[ 0 ]->_env->{ 'psgix.session' }, ) },
      handles      => [ 'authenticated', 'username' ];

=head1 Description

Session object base class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<authenticated>

A boolean which defaults to false.

=item C<messages>

A hash reference of messages keyed by message id

=item C<updated>

The unix time this session was last updated

=item C<username>

The name of the authenticated user. Defaults to C<NUL> if the user
is anonymous

=back

=head1 Subroutines/Methods

=head2 C<BUILD>

Tests to see if the session has expired and if so sets the L</authenticated>
boolean to false

=head2 C<BUILDARGS>

Copies the session values into the hash reference used to instantiate the
object from the Plack environment

=head2 C<add_status_message>

   $message_id = $session->add_status_message( $message );

Appends the message to the message queue for this session. The C<$message>
argument is an array reference, first the message then the positional
parameters

=head2 C<collect_message_id>

   $mid = $session->collect_message_id( $req );

Return any pending message id

=head2 C<collect_status_message>

   $localised_message = $session->collect_status_message( $req );

Returns the next message in the queue (if there is one) for the given request

=head2 C<collect_status_messages>

   \@localised_messages = $session->collect_status_messages( $req );

Returns previous messages in the queue (if there are any) for the given request
or any previous requests

=head2 C<trim_message_queue>

   $session->trim_message_queue;

Reduce the size of the message queue the maximum allowed by the configuration

=head2 C<update>

   $session->update;

Copy the attribute values back to the Plack environment

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-ComposableRequest.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
# vim: expandtab shiftwidth=3:
