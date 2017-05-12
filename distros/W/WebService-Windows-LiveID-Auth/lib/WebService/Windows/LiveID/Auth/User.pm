package WebService::Windows::LiveID::Auth::User;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use DateTime;

__PACKAGE__->mk_accessors(qw/
  appid
  uid
  ts
  sig
/);

=head1 NAME

WebService::Windows::LiveID::Auth::User - The data class of authenticated user.

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 new($args)

=cut

sub new {
    my ($class, $args) = @_;
    $args->{ts} = DateTime->from_epoch(epoch => $args->{ts});
    return $class->SUPER::new($args);
}

=head1 SYNOPSIS

=head1 METHODS

=head2 appid

Application ID

=head2 uid

Unique ID.

=head2 ts

Authenticated datetime. See L<DateTime>.

=head2 sig

Signature

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-windows-liveid-auth-user@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Windows::LiveID::Auth::User
