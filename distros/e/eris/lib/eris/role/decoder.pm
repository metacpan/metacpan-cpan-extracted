package eris::role::decoder;
# ABSTRACT: Role for implementing decoders

use Moo::Role;
use Types::Standard qw( Str Int );
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


requires 'decode_message';
with qw(
    eris::role::plugin
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::decoder - Role for implementing decoders

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Implement your own decoders, e.g.:

    use Parse::Syslog::Line;
    use Moo;
    with qw( eris::role::decoder );

    sub decode_message {
        my ($self,$msg) = @_;
        return parse_syslog_line($msg);
    }

=head1 INTERFACE

=head2 decode_message

Passed the raw message as received.  Expects a parsed structure in the form of a
C<HashRef> as a return.

=head1 SEE ALSO

L<eris::log::decoders>, L<eris::log::contextualizer>, L<eris::log::decoders::syslog>,
L<eris::log::decoder::json>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
