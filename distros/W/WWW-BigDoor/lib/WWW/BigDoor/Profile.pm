package WWW::BigDoor::Profile;

use strict;
use warnings;

use Data::Dumper;
use Carp;
#use Smart::Comments -ENV;

use WWW::BigDoor::EndUser;
use base qw(WWW::BigDoor::Resource Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
    qw(id provider email first_name last_name display_name profile_photo end_user_obj is_saved ) );

sub new {
    my ( $class, $end_user_obj, $args ) = @_;

    my $self = $class->SUPER::new( $args );

    $self->set_is_saved( 0 );
    $self->set_end_user_obj( $end_user_obj );
    return $self;
}

sub get_id {
    my ( $self ) = @_;

    return $self->get_provider() if $self->get_is_saved;

    return;
}

sub end_point {
    my ( $self, $end_user_obj ) = @_;
    my $ep = $self->_end_point;

    unless ( defined $end_user_obj ) {
        croak "Need EndUser object as parameter" unless ref $self;
        $end_user_obj = $self->get_end_user_obj;
    }
    ### end_user_obj: Dumper($end_user_obj)

    my $end_user_login = $end_user_obj->get_end_user_login();
    ### end_user_login: $end_user_login
    ### _end_point: $self->_end_point()
    ### _parent_end_point: $self->_parent_end_point()

    $ep = sprintf '%s/%s/%s', $self->_parent_end_point(), $end_user_login, $self->_end_point();
    ###  ep with parent: $ep
    return $ep;
}

sub save {
    my ( $self, @args ) = @_;
    $self->SUPER::save( @args );
    $self->set_is_saved( 1 );
    return $self;
}

sub load {
    my ( $self, @args ) = @_;
    $self->SUPER::load( @args );
    $self->set_is_saved( 1 );
    return $self;
}

sub remove {
    my $self = shift;
    $self->SUPER::remove( @_ );
    $self->set_is_saved( 0 );
    return $self;
}

sub _parent_end_point { ## no critic (ProhibitUnusedPrivateSubroutines)
    return 'end_user';
}

sub _parent_id_attr { ## no critic (ProhibitUnusedPrivateSubroutines)
    return 'end_user_login';
}

1;
__END__

=head1 NAME

WWW::BigDoor::Profile - Profile Resource Object for BigDoor API

=head1 VERSION

This document describes BigDoor version 0.1.1

=head1 SYNOPSIS

    use WWW::BigDoor;
    use WWW::BigDoor::EndUser;
    use WWW::BigDoor::Profile;

    my $client = new WWW::BigDoor( $APP_SECRET, $APP_KEY );

    my $end_user_obj = new WWW::BigDoor::EndUser({
            end_user_login => 'username', 
        });

    $end_user_obj->save( $client );

    my $profile_payload = {
        provider      => 'publisher',
        email         => 'end_user@example.com',
        first_name    => 'John',
        last_name     => 'Doe',
        display_name  => 'John Doe',
        profile_photo => 'http://example.com/image.jpg',
        example_key   => 'Example Value',
    };

    my $profile_obj = new WWW::BigDoor::Profile( $end_user_obj, $profile_payload );

    $profile_obj->save( $client );

    $profile_obj->remove( $client );
    $end_user_obj->remove( $client );
  
=head1 DESCRIPTION

This module provides object corresponding to BigDoor API /end_user/{id}/profile end point.
For description see online documentation L<http://publisher.bigdoor.com/docs/>

=head1 INTERFACE 

All methods except accessor/mutators are provided by base
WWW::BigDoor::Resource object
  
=head3 new( $end_user_obj, $payload )

Constructs a new WWW::BigDoor::Profile object

=head3 load( $client, [$id] )

Loads single WWW::BigDoor::Profile object identified by id or reloads existing
object if id omitted.

=over 4

=item client

WWW::BigDoor client object

=item id

BigDoor Resource object ID. If calling object has id attribute defined, $id
parameter is optional

=back

=head3 save( $client )

Saves Resource object. If object was saved before than PUT method is used,
otherwise POST is used.

=over 4

=item client

WWW::BigDoor client object

=back

=head3 remove( $client )

=over 4

=item client

WWW::BigDoor client object

=back

=head3 end_point( $end_user_obj )

Returns corresponding end_point URL for this particular object.

=head3 get_id()

Returns provider attribute if object was saved before or undef otherwise.

=head1 DIAGNOSTICS

No error messages produced by module itself.

=head1 CONFIGURATION AND ENVIRONMENT

WWW:BigDoor::Profile requires no configuration files or environment variables.

=head1 DEPENDENCIES

WWW::BigDoor::Resource, WWW::BigDoor

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bigdoor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

WWW::BigDoor::Resource for base class description, WWW::BigDoor for procedural
interface for BigDoor REST API

=head1 AUTHOR

Alex L. Demidov  C<< <alexeydemidov@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

BigDoor Open License
Copyright (c) 2010 BigDoor Media, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions:

- This copyright notice and all listed conditions and disclaimers shall
be included in all copies and portions of the Software including any
redistributions in binary form.

- The Software connects with the BigDoor API (api.bigdoor.com) and
all uses, copies, modifications, derivative works, mergers, publications,
distributions, sublicenses and sales shall also connect to the BigDoor API and
shall not be used to connect with any API, software or service that competes
with BigDoor's API, software and services.

- Except as contained in this notice, this license does not grant you rights to
use BigDoor Media, Inc. or any contributors' name, logo, or trademarks.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
