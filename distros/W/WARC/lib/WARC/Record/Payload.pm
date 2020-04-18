package WARC::Record::Payload;					# -*- CPerl -*-

use strict;
use warnings;

use WARC; *WARC::Record::Payload::VERSION = \$WARC::VERSION;

use Carp;
use Fcntl qw/SEEK_SET SEEK_CUR SEEK_END/;

# This implementation uses an array as the underlying object.

use constant { BASE => 0, HANDLE => 1, PARENT => 2 };
use constant OBJECT_INIT => undef, undef, undef;

sub _dbg_dump {
  my $self = shift;

  my $out = 'record payload @'.(tell $self->[HANDLE]);
  $out .= "\n";

  return $out;
}

sub TIEHANDLE {
  my $class = shift;
  my $parent = shift;
  my $replay = shift;

  # The payload_offset key will be set in $parent iff loading was deferred.
  my $handle; my $base_offset;
  if (defined $parent->{payload_offset}) {
    $handle = $parent->open_continued;
    $base_offset = $parent->{payload_offset};
  } elsif ($replay->can('content_ref')) {
    # The payload was smaller than the deferred loading threshold.
    # This open fails iff perl was built without PerlIO, which is non-default.
    # uncoverable branch true
    open $handle, '<', $replay->content_ref
      or die "failure opening stream on replay object buffer: $!";
    binmode $handle, ':raw';
    $base_offset = 0;
  } else
    { confess 'extracting payload from '.(ref $replay).' not implemented' }

  my $ob = [OBJECT_INIT];
  @$ob[PARENT, HANDLE, BASE] = ($parent, $handle, $base_offset);

  bless $ob, $class;

  $ob->SEEK(0, SEEK_SET);

  return $ob;
}

# TODO: implement payload decoding

sub READLINE { readline $_[0]->[HANDLE] }

# This sub must rely on the aliasing effect of @_.
sub READ { read $_[0]->[HANDLE], $_[1], $_[2], (defined $_[3] ? $_[3] : 0) }

sub GETC { getc $_[0]->[HANDLE] }

sub EOF { eof $_[0]->[HANDLE] }

sub SEEK {
  my $self = shift;
  my $offset = shift;
  my $whence = shift;

  my $adjust = 0;
  $adjust = $self->[BASE] if $whence == SEEK_SET;

  seek $self->[HANDLE], $adjust + $offset, $whence
}

sub TELL { return ((tell $_[0]->[HANDLE]) - $_[0]->[BASE]) }

sub CLOSE { close $_[0]->[HANDLE] }

1;
__END__

=head1 NAME

WARC::Record::Payload - tied filehandle for reading decoded record payload

=head1 SYNOPSIS

  use WARC::Record;

=head1 DESCRIPTION

This is an internal class used to implement the C<open_payload> instance
method on C<WARC::Record> objects.  This class provides tied filehandles
and the methods are documented in L<perltie/"Tying FileHandles"> and
L<perlfunc>.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>
L<perltie/"Tying FileHandles">
L<perlfunc>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
