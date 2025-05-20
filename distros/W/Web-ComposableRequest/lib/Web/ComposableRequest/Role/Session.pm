package Web::ComposableRequest::Role::Session;

use namespace::autoclean;

use Web::ComposableRequest::Constants qw( TRUE );
use Web::ComposableRequest::Util      qw( add_config_role compose_class );
use Unexpected::Types                 qw( LoadableClass Object );
use Moo::Role;

requires qw( loc loc_default query_params _config _env _log );

add_config_role __PACKAGE__.'::Config';

has 'session' =>
   is      => 'lazy',
   isa     => Object,
   builder => sub {
      my $self = shift;

      return $self->session_class->new(
         config  => $self->_config,
         request => $self,
         session => $self->_env->{'psgix.session'},
      );
   },
   clearer => TRUE,
   handles => [ 'authenticated', 'username' ];

has 'session_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   builder => sub {
      my $self = shift;
      my $conf = $self->_config;

      return compose_class(
         $conf->session_class, $conf->session_attr, is => 'rw'
      );
   };

sub reset_session {
   my $self       = shift;
   my $psgix_sess = $self->_env->{ 'psgix.session' };

   delete $psgix_sess->{ $_ } for (keys %{ $psgix_sess });

   $self->clear_session;
   return;
}

package Web::ComposableRequest::Role::Session::Config;

use namespace::autoclean;

use Web::ComposableRequest::Constants qw( FALSE TRUE );
use Unexpected::Types qw( ArrayRef Bool CodeRef HashRef NonEmptySimpleStr
                          NonZeroPositiveInt PositiveInt );
use Moo::Role;

has 'delete_on_collect' => is => 'ro', isa => Bool, default => TRUE;

has 'expire_session' => is => 'lazy', isa => CodeRef,
   default => sub { sub { [ 'User [_1] session expired', $_[ 0 ]->username ] }};

has 'max_messages' => is => 'ro', isa => NonZeroPositiveInt,
   default => 3;

has 'max_sess_time' => is => 'ro', isa => PositiveInt,
   default => 3_600;

has 'serialise_session_attr' => is => 'ro', isa => ArrayRef[NonEmptySimpleStr],
   default => sub { [] };

has 'session_attr' => is => 'ro', isa => HashRef[ArrayRef],
   default => sub { {} };

has 'session_class' => is => 'ro', isa => NonEmptySimpleStr,
   default => 'Web::ComposableRequest::Session';

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::Session - Adds a session object to the request

=head1 Synopsis

   package Your::Request::Class;

   use Moo;

   extends 'Web::ComposableRequest::Base';
   with    'Web::ComposableRequest::Role::Session';

=head1 Description

Adds a session object to the request. The L</session_attr> list defines
attributes (name, type, and default) which are dynamically added to the
session class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<session>

Stores the user preferences. An instance of L</session_class>

=item C<session_class>

Defaults to L<Web::ComposableRequest::Session>

=back

Defines the following configuration attributes

=over 3

=item C<expire_session>

A code reference which will be called passing in the session object reference
when the session has expired. By default it sets the C<authenticated> boolean
to false and returns the message displayed by the application

=item C<max_messages>

A non zero positive integer which defaults to 3. The maximum number of messages
to keep in the queue

=item C<max_sess_time>

A positive integer that defaults to 3600 seconds (one hour). The maximum amount
of time a session can be idle before re-authentication is required. Setting
this to zero disables the feature

=item C<session_attr>

A hash reference of array references. Defaults to an empty hash. The keys
are the session attribute names, the arrays are tuples containing a type
and a default value

=item C<session_class>

A non empty simple string which defaults to L<Web::ComposableRequest::Session>.
The name of the session base class

=back

=head1 Subroutines/Methods

=head2 C<reset_session>

Resets the session object so that next time it is referenced a new one is
minted

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Digest::MD5>

=item L<Subclass::Of>

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
