package Test::Health::Email;

use warnings;
use strict;
use Moo 2.000002;
use namespace::clean 0.26;
use Email::Sender::Transport::SMTP 1.300021;
use Types::Standard 1.000005 qw(Str);
use Email::Stuffer 0.012;

our $VERSION = '0.004'; # VERSION

=head1 NAME

Test::Health::Email - Moo class to send an e-mail with an attachment through SMTP

=head1 SYNOPSIS

See health_check.pl script.

=head1 DESCRIPTION

This class is a wrapper for L<Email::Stuffer> and L<Email::Sender::Transport::SMTP>.

=head1 ATTRIBUTES

=head2 host

A string describing the full qualified name of the SMTP server to be used.

It is optional and defaults to "localhost".

=cut

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    reader   => 'get_host',
    default  => 'localhost'
);

=head2 to

A string representing the adressee of the e-mail.

This is a required attribute during object creation.

=cut

has to => ( is => 'ro', isa => Str, required => 1, reader => 'get_to' );

=head2 from

A string representing the sender to the e-mail.

This is a required attribute during object creation.

=cut

has from => ( is => 'ro', isa => Str, required => 1, reader => 'get_from' );

=head1 METHODS

=head2 get_to

Getter for C<to> attribute.

=head2 get_from

Getter for C<from> attribute.

=head2 get_host

Getter for C<host> attribute.

=head2 send_email

Sends the e-mail through SMTP.

Expects the following positional parameters:

=over

=item 1.

A string representing the test name.

=item 2.

The full pathname to the report attachment.

=item 3.

A string representing the application (name) that is being tested.

=back

By default, it will try to remove the attachment after the e-mail was send, unless
an exception occurs. It will print an error message to STDERR in case of failure to remove
the file.

=cut

sub send_email {

    my ( $self, $test_name, $attachment, $app_name ) = @_;
    my $body = <<BLOCK;

    Greetings,

    Sadly a test ($test_name) runned against $app_name failed.
    Please check the attachment for details.

BLOCK

    my $transport = $self->_create_transport();

    Email::Stuffer->from( $self->get_from )->to( $self->get_to )
      ->text_body($body)->transport($transport)->subject(" $test_name failed")
      ->attach_file($attachment)->send;

    unlink $attachment
      or warn "could not remove $attachment after sent by e-mail: $!";

}

=head2 _create_transport

"Hidden" method. Creates an instance of L<Email::Sender::Transport::SMTP>.

=cut

sub _create_transport {
    my $self = shift;
    return Email::Sender::Transport::SMTP->new( { host => $self->get_host } );
}

=head1 SEE ALSO

=over

=item *

L<Email::Sender::Transport::STMP>

=item *

L<Email::Stuffer>

=item *

L<Moo>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Test-Health distribution.

Test-Health is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Test-Health is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Test-Health. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
