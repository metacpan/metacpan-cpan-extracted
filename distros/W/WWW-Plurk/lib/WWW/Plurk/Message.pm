package WWW::Plurk::Message;

use warnings;
use strict;
use Carp;
use Math::Base36 qw( encode_base36 );

=head1 NAME

WWW::Plurk::Message - A plurk message

=head1 VERSION

This document describes WWW::Plurk::Message version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::Plurk;
    my $plurk = WWW::Plurk->new( 'username', 'password' );
    my @plurks = $plurk->plurks;
  
=head1 DESCRIPTION

Represents an individual Plurk or response.

Based on Ryan Lim's unofficial PHP API: L<http://code.google.com/p/rlplurkapi/>

=cut

BEGIN {
    my @INFO = qw(
      author
      content
      content_raw
      id
      is_mute
      is_unread
      lang
      limited_to
      no_comments
      owner_id
      plurk_id
      posted
      qualifier
      response_count
      responses_seen
      source
      user_id
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
    my ( $class, $plurk, $detail, $author ) = @_;
    return bless {
        plurk  => $plurk,
        author => $author,
        %$detail,
    }, $class;
}

=head2 C<< responses >>

Get the responses for this Plurk. If called on an object that already
represents a response gets the peers of that response (i.e. the other
responses to the same Plurk).

=cut

sub responses {
    my $self = shift;
    return $self->plurk->responses_for( $self->plurk_id, @_ );
}

=head2 C<< respond >>

Respond to a Plurk. See L<WWW::Plurk#respond_to_plurk> for details of
arguments.

    $msg->respond( content => "I'm free!" );

Returns the newly created response.

=cut

sub respond {
    my $self = shift;
    return $self->plurk->respond_to_plurk( $self->plurk_id, @_ );
}

=head2 C<< permalink >>

Get a URI that is a permanent link to this Plurk. If called on a
response gets a permalink to the parent Plurk.

=cut

sub permalink {
    my $self = shift;
    return $self->plurk->_base_uri . '/p/'
      . encode_base36( $self->plurk_id );
}

=head2 Accessors

The following accessors provide access to the content of this Plurk:

=over

=item * C<< author >>

=item * C<< content >>

=item * C<< content_raw >>

=item * C<< id >>

=item * C<< is_mute >>

=item * C<< is_unread >>

=item * C<< lang >>

=item * C<< limited_to >>

=item * C<< no_comments >>

=item * C<< owner_id >>

=item * C<< plurk_id >>

=item * C<< posted >>

=item * C<< qualifier >>

=item * C<< response_count >>

=item * C<< responses_seen >>

=item * C<< source >>

=item * C<< user_id >>

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
