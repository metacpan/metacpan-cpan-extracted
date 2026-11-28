package Web::Session::Store::File;

use strict;
use Fcntl qw(O_RDWR O_CREAT O_EXCL);
use Errno qw(EEXIST);
use Apache::Session::Store::File;
our @ISA     = qw(Apache::Session::Store::File);
our $VERSION = '1.0.0';

# The inherited insert() and update() print the serialized session as is, so
# Perl writes Latin-1 bytes when every character fits in a byte and UTF-8
# otherwise. Reading then has to guess which one it was, and the two are
# indistinguishable when the Latin-1 bytes also form a valid UTF-8 sequence
# ("\x{c3}\x{a9}" comes back as "\x{e9}"). The JSON serializer documents its
# output as UTF-8 text, so always write UTF-8 bytes, whatever the internal
# form of the string

sub insert {
    my $self    = shift;
    my $session = shift;

    # Like the parent store, never overwrite an existing session (O_EXCL
    # also closes the race between the existence check and the open)
    $self->_open( $session, 1 );
    $self->_write($session);
}

sub update {
    my $self    = shift;
    my $session = shift;

    $self->_open($session) unless ( $self->{opened} );
    truncate( $self->{fh}, 0 ) || die "Could not truncate file: $!";
    seek( $self->{fh}, 0, 0 );
    $self->_write($session);
}

sub _open {
    my ( $self, $session, $exclusive ) = @_;

    my $directory = $session->{args}->{Directory}
      || $Apache::Session::Store::File::Directory;
    my $file = $directory . '/' . $session->{data}->{_session_id};
    unless (
        sysopen( $self->{fh}, $file,
            O_RDWR | O_CREAT | ( $exclusive ? O_EXCL : 0 ) )
      )
    {
        die "Object already exists in the data store" if ( $! == EEXIST );
        die "Could not open file $file: $!";
    }
    $self->{opened} = 1;
}

sub _write {
    my ( $self, $session ) = @_;

    # Work on a copy: {serialized} is reused by the caller and other stores
    my $data = $session->{serialized};
    utf8::encode($data) if ( utf8::is_utf8($data) );
    print { $self->{fh} } $data;
    $self->{fh}->flush();
}

1;

__END__

=encoding utf8

=head1 NAME

Web::Session::Store::File - Store sessions in files, as UTF-8

=head1 DESCRIPTION

Same as L<Apache::Session::Store::File>, but the serialized session is always
written as UTF-8 bytes. The parent class prints the string as it is, which
stores Latin-1 bytes when every character of the session fits in a byte: a
reader can't tell those bytes from UTF-8 ones, so a session holding
C<"\x{c3}\x{a9}"> comes back as C<"\x{e9}">.

Sessions written by an older version are still read, as long as their bytes
are not valid UTF-8: Latin-1 data already written as UTF-8 can't be told
apart.

=head1 SEE ALSO

L<Apache::Session::Store::File>, L<Web::Session::File>

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2026 by Clément Oudot

=item 2019-2026 by Maxime Besson

=item 2013-2026 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
