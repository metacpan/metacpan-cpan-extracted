package WWW::Plurk::Friend;

use warnings;
use strict;
use Carp;

=head1 NAME

WWW::Plurk::Friend - A plurk friend

=head1 VERSION

This document describes WWW::Plurk::Friend version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::Plurk;
    my $plurk = WWW::Plurk->new( 'username', 'password' );
    my @friends = $plurk->friends;
  
=head1 DESCRIPTION

Represents a user other than the logged in user.

Based on Ryan Lim's unofficial PHP API: L<http://code.google.com/p/rlplurkapi/>

=cut

BEGIN {
    my @INFO = qw(
      display_name
      full_name
      gender
      has_profile_image
      id
      is_channel
      karma
      location
      nick_name
      page_title
      relationship
      star_reward
      uid
      plurk
    );

    for my $info ( @INFO ) {
        no strict 'refs';
        *{$info} = sub { shift->{$info} };
    }
}

=head1 INTERFACE 

=head2 C<< new >>

Called internally.

=cut

sub new {
    my ( $class, $plurk, $uid, $detail ) = @_;
    return bless {
        plurk => $plurk,
        uid   => $uid,
        %$detail,
    }, $class;
}

=head2 C<< friends >>

Get this user's friends. See L<WWW::Plurk#friends> for more details.

=cut

sub friends {
    my $self = shift;
    return $self->plurk->friends_for( $self );
}

=head2 Accessors

The following accessors provide access to the content of this Plurk:

=over

=item * C<< display_name >>

=item * C<< full_name >>

=item * C<< gender >>

=item * C<< has_profile_image >>

=item * C<< id >>

=item * C<< is_channel >>

=item * C<< karma >>

=item * C<< location >>

=item * C<< nick_name >>

=item * C<< page_title >>

=item * C<< relationship >>

=item * C<< star_reward >>

=item * C<< uid >>

=item * C<< plurk >>

=back

=cut

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
WWW::Plurk requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-plurk@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

L<< http://www.plurk.com/user/AndyArmstrong >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
