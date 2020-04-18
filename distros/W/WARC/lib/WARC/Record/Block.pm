package WARC::Record::Block;					# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

use WARC; *WARC::Record::Block::VERSION = \$WARC::VERSION;

use Carp;
use Fcntl qw/SEEK_SET SEEK_CUR SEEK_END/;

# This implementation uses an array as the underlying object.

use constant { BASE => 0, LENGTH => 1, HANDLE => 2, PARENT => 3, AT_EOF => 4 };
use constant OBJECT_INIT => undef, undef, undef, undef, 0;

sub _dbg_dump {
  my $self = shift;

  my $out = 'record block '.$self->[BASE].' +> '.$self->[LENGTH];
  $out .= ' @'.((tell $self->[HANDLE]) - $self->[BASE]);
  $out .= ' [EOF]' if $self->[AT_EOF];
  $out .= "\n";

  return $out;
}

sub TIEHANDLE {
  my $class = shift;
  my $parent = shift;

  my $handle = $parent->volume->open;

  if (defined $parent->{compression}) {
    seek $handle, $parent->offset, SEEK_SET or die "seek: $!";

    my $z_reader = $parent->{compression};
    my $zhandle = new $z_reader ($handle, MultiStream => 0, Transparent => 0,
				 AutoClose => 1)
      or die "$z_reader: ".$parent->_get_compression_error;

    $handle = $zhandle;
  }

  my $ob = [OBJECT_INIT];
  @$ob[PARENT, HANDLE] = ($parent, $handle);
  @$ob[BASE, LENGTH] =
    ($parent->{data_offset}, $parent->field('Content-Length'));

  bless $ob, $class;

  $ob->SEEK(0, SEEK_SET);

  return $ob;
}

sub READLINE {
  my $self = shift;

  if (wantarray) {
    my @data = ();
    while (defined(my $line = $self->READLINE())) { push @data, $line }
    return @data
  }

  return undef if $self->[AT_EOF];

  my $line = readline $self->[HANDLE];
  unless (defined $line) { $self->[AT_EOF] = 1; return undef }

  my $excess = (tell $self->[HANDLE]) - $self->[BASE] - $self->[LENGTH];
  $self->[AT_EOF] = 1 unless $excess < 0;
  $line = substr $line, 0, -$excess if $excess > 0;

  return $line;
}

# This sub must rely on the aliasing effect of @_.
sub READ {
  my $self = shift;
  # args now:  0: buffer  1: length  2: offset into buffer or undef
  my $length = $_[1];
  my $offset = $_[2] || 0;

  return 0 if $self->[AT_EOF];

  my $excess = (($length + tell $self->[HANDLE])
		- $self->[BASE] - $self->[LENGTH]);
  $self->[AT_EOF] = 1 unless $excess < 0;
  $length -= $excess if $excess > 0;

  my $buf; my $count = read $self->[HANDLE], $buf, $length;
  return undef unless defined $count;

  $_[0] = '' unless defined $_[0];
  $_[0] .= "\0" x ($offset - length($_[0])) if $offset > length $_[0];
  substr $_[0], $offset, (length($_[0]) - $offset), $buf;
  return $count;
}

sub GETC {
  my $self = shift;

  my $ch;
  return undef unless $self->READ($ch, 1);
  return $ch;
}

sub EOF { (shift)->[AT_EOF] }

sub SEEK {
  my $self = shift;
  my $offset = shift;
  my $whence = shift;

  my $npos;
  $self->[AT_EOF] = 0;

  if	($whence == SEEK_SET)	{ $npos = $offset }
  elsif ($whence == SEEK_CUR)	{ $npos = $offset + $self->TELL }
  elsif ($whence == SEEK_END)	{ $npos = $self->[LENGTH] + $offset }
  else { croak "unknown WHENCE $whence in call to seek" }

  return 0 if $npos < 0;
  if ($npos >= $self->[LENGTH]) { $self->[AT_EOF] = 1; $npos = $self->[LENGTH] }

  seek $self->[HANDLE], $self->[BASE] + $npos, SEEK_SET;
}

sub TELL {
  my $self = shift;

  return $self->[LENGTH] if $self->[AT_EOF];

  return ((tell $self->[HANDLE]) - $self->[BASE]);
}

sub CLOSE {
  my $self = shift;
  @$self[BASE, LENGTH, AT_EOF] = (0, 0, 1);
  close $self->[HANDLE];
}

1;
__END__

=head1 NAME

WARC::Record::Block - data block from a WARC file

=head1 SYNOPSIS

  use WARC::Record;

=head1 DESCRIPTION

This is an internal class used to implement the C<open_block> instance
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

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
