package Text::ZPL::Stream;
$Text::ZPL::Stream::VERSION = '0.003001';
use strict; use warnings FATAL => 'all';
use Carp;

use Text::ZPL ();


sub BUF_MAX         () { 0 }
sub BUF             () { 1 }
sub MAYBE_EXTRA_EOL () { 2 }
sub ROOT            () { 3 }
sub CURRENT         () { 4 }
sub LEVEL           () { 5 }
sub TREE            () { 6 }


sub new {
  #  max_buffer_size =>
  #  string =>
  my ($class, %param) = @_;
  my $root = +{};
  bless [
    ($param{max_buffer_size} || 0),  # BUF_MAX
    '',                              # BUF
    0,                               # MAYBE_EXTRA_EOL
    $root,                           # ROOT
    $root,                           # CURRENT
    0,                               # LEVEL
    [],                              # TREE
  ], $class
}

sub max_buffer_size {
  defined $_[0]->[BUF_MAX] ?
    $_[0]->[BUF_MAX] : ( $_[0]->[BUF_MAX] = 0 )
}


sub _maybe_extra_eol {
  $_[0]->[MAYBE_EXTRA_EOL]
}

sub _maybe_extra_eol_off {
  $_[0]->[MAYBE_EXTRA_EOL] = 0
}

sub _maybe_extra_eol_on {
  $_[0]->[MAYBE_EXTRA_EOL] = 1
}


sub _parse_current_buffer {
  my ($self) = @_;
  my $line = $self->[BUF];

  unless ( Text::ZPL::_decode_prepare_line($line) ) {
    # skippable:
    $self->[BUF] = '';
    return
  }

  Text::ZPL::_decode_handle_level(
    0, 
    $line, 
    $self->[ROOT],
    $self->[CURRENT],
    $self->[LEVEL],
    $self->[TREE],
  );
  
  if ( (my $sep_pos = index($line, '=')) > 0 ) {
    my ($k, $v) = Text::ZPL::_decode_parse_kv(
      0, $line, $self->[LEVEL], $sep_pos
    );
    Text::ZPL::_decode_add_kv(
      0, $self->[CURRENT], $k, $v
    );

    $self->[BUF] = '';
    return
  }

  my $re = $Text::ZPL::ValidName;
  if (my ($subsect) = $line =~ /^(?:\s+)?($re)(?:\s+?#.*)?$/) {
    Text::ZPL::_decode_add_subsection(
      0, $self->[CURRENT], $subsect, $self->[TREE]
    );

    $self->[BUF] = '';
    return
  }

  confess "Parse failed in ZPL stream; bad input '$line'"
}


sub get { shift->[ROOT] }

sub get_buffer { shift->[BUF] }


sub push {
  my $self = shift;
  my @chrs = split '', join '', @_;

  my $handled = 0;

  CHAR: for my $chr (@chrs) {
    if ($chr eq "\015") {
      # got \r, maybe an unneeded \n coming up, _maybe_extra_eol_on
      $self->_maybe_extra_eol_on;
      $self->_parse_current_buffer;
      ++$handled;
      next CHAR
    }
    if ($chr eq "\012") {
      if ($self->_maybe_extra_eol) {
        $self->_maybe_extra_eol_off;
      } else {
        $self->_parse_current_buffer;
        ++$handled;
      }
      next CHAR
    }

    $self->_maybe_extra_eol_off if $self->_maybe_extra_eol;

    confess "Exceeded maximum buffer size for ZPL stream"
      if  $self->max_buffer_size
      and length($self->[BUF]) >= $self->max_buffer_size;

    $self->[BUF] .= $chr
  }

  $handled
}


1;

=pod

=for Pod::Coverage BUF(_MAX)? MAYBE_EXTRA_EOL ROOT CURRENT LEVEL TREE

=head1 NAME

Text::ZPL::Stream - Streaming ZPL decoder

=head1 SYNOPSIS

  use Text::ZPL::Stream;

  my $stream = Text::ZPL::Stream->new;

  if ( $stream->push($zpl_chrs) ) {
    # Parsed at least one complete line:
    my $ref = $stream->get;
    # ...
  }

  # Or in a loop:
  while ( defined(my $zpl_chrs = magically_get_some_zpl) ) {
    $stream->push($zpl_chrs);
  }
  my $ref = $stream->get;
  # ...

=head1 DESCRIPTION

A streaming decoder for C<ZeroMQ Property Language> files using L<Text::ZPL>. 

See the L<Text::ZPL> documentation for more on C<ZPL> and parsing-related
details.

=head2 new

  my $stream = Text::ZPL::Stream->new(
    # Optional:
    max_buffer_size => 512,
  );

Constructs an object representing a new C<ZPL> stream.

Accepts the following options:

=over

=item max_buffer_size

The maximum line length allowed in buffers before an exception is thrown.

Defaults to 0 (unlimited).

=back

=head2 push

  $stream->push(@chars);
  $stream->push($string);

Takes characters (individually or as strings) and collects until an
end-of-line marker (C<\r>, C<\n>, or C<\r\n>) is encountered, at which point a
parse is called and the reference returned by L</get> is altered
appropriately.

An exception is thrown if parsing fails, or if L</max_buffer_size> is reached
-- if you're unsure of your incoming data, you may want to wrap C<push> calls
with L<Try::Tiny> or similar.

Returns the number of complete lines parsed, which can be useful as an
indicator that L</get> ought be called:

  if ( $stream->push($zpl) ) {
    # Parsed at least one complete line:
    my $ref = $stream->get;
    ...
  }

=head2 get

  my $ref = $stream->get;

Returns the C<HASH> reference to the decoded structure.

B<< This is the actual reference in use by the decoder, not a copy! >>
Altering the structure of the C<HASH> may have unintended consequences, in
which case you may want to make use of L<Storable/dclone> to create a safe
copy.

=head2 get_buffer

Returns a string containing the current character buffer (that is, any
incomplete line).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
