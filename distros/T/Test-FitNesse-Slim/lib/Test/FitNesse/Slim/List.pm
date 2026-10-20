package Test::FitNesse::Slim::List;

use strict;
use warnings;

use Encode qw/ is_utf8 encode decode FB_CROAK /;

our %DEFAULT_LIMITS = (
  nesting     => 128,
  elements    => 1_000_000,
  item_units  => 16_777_216,
  frame_bytes => 67_108_864,
);

sub _utf16_code_units_length {
  my($s) = @_;
  my $utf16be = encode("UTF-16BE", $s);
  use bytes;
  return length($utf16be) / 2;
}

sub _take_utf16_units {
  my ($s, $position, $units) = @_;
  my $start = $$position;
  my $count = 0;

  while ($count < $units && $$position < length $s) {
    my $ch = substr($s, $$position, 1);
    my $codepoint = ord($ch);
    my $units_in_char = $codepoint > 0xFFFF ? 2 : 1;
    last if $count + $units_in_char > $units;
    $count += $units_in_char;
    ++$$position;
  }

  die "syntax error: item length exceeds available UTF-16 code units"
    unless $count == $units;
  return substr($s, $start, $$position - $start);
}

sub new {
  my($this,$l,@options) = @_;
  my $class = ref($this) || $this;
  my %options = @options;
  my $limits = { %DEFAULT_LIMITS, %{ $options{limits} || {} } };
  if (ref($l) eq "ARRAY") {
    return bless { LIST => [ @$l ], LIMITS => $limits } => $class;
  }
  return bless { RAW => $l, LIMITS => $limits } => $class;
}

sub _decimal {
  my($s,$position,$maximum,$kind) = @_;
  pos($s) = $$position;
  die "syntax error: missing $kind" unless $s =~ /\G([0-9]{6,}):/gc;
  my $digits = $1;
  $$position = pos($s);
  (my $significant = $digits) =~ s/^0+//;
  $significant = '0' unless length $significant;
  my $limit = "$maximum";
  die "resource limit: $kind exceeds configured maximum"
    if length($significant) > length($limit)
      || length($significant) == length($limit) && $significant gt $limit;
  return 0 + $significant;
}

sub _parse {
  my($s,$limits,$state,$depth) = @_;
  die "resource limit: nested-list depth exceeds configured maximum"
    if $depth > $limits->{nesting};
  die "syntax error: missing open bracket" unless substr($s,0,1) eq '[';
  my $position = 1;
  my $count = _decimal($s,\$position,$limits->{elements},'list-length');
  $state->{elements} += $count;
  die "resource limit: total list elements exceed configured maximum"
    if $state->{elements} > $limits->{elements};

  my @items;
  for (1 .. $count) {
    my $units = _decimal($s,\$position,$limits->{item_units},'item-length');
    my $item = _take_utf16_units($s,\$position,$units);
    die "syntax error: item is not terminated by a colon"
      unless substr($s,$position++,1) eq ':';

    my $nested;
    if ($item =~ /\A\[/ && $item !~ /\A\[\s*\z/) {
      my $previous_elements = $state->{elements};
      my $ok = eval { $nested = _parse($item,$limits,$state,$depth + 1); 1 };
      die $@ if !$ok && $@ =~ /\Aresource limit:/;
      $state->{elements} = $previous_elements unless $ok;
    }
    push @items, defined($nested) ? $nested : $item;
  }

  die "syntax error: missing close bracket" unless substr($s,$position++,1) eq ']';
  die "syntax error: trailing serialized data" unless $position == length($s);
  return \@items;
}

sub list {
  my($self) = @_;
  return @{ $self->{LIST} } if $self->{LIST};
  my $raw = $self->{RAW};
  die "cannot deserialize undefined value" unless defined $raw;
  die "cannot deserialize empty string" unless length $raw;
  my $limits = $self->{LIMITS} || \%DEFAULT_LIMITS;
  my $measure = $raw;
  my $frame_bytes = is_utf8($measure)
    ? length(encode("UTF-8",$measure,FB_CROAK)) : length($measure);
  die "resource limit: frame exceeds configured maximum"
    if $frame_bytes > $limits->{frame_bytes};
  my $decoded = is_utf8($raw) ? $raw : eval { decode("UTF-8",$raw,FB_CROAK) };
  die "cannot deserialize non-UTF-8 encoding" unless defined $decoded;
  my $parsed = _parse($decoded,$limits,{elements => 0},1);
  @{ $self->{LIST} = $parsed };
}

sub length_string {
  my($self,$length) = @_;
  sprintf "%06d:", $length;
}

sub serialize {
  my($self) = @_;
  return $self->{RAW} if $self->{RAW};
  my @l = $self->list;

  my $result = "[" . $self->length_string(scalar @l);
  for (@l) {
    my $item;
    my $length;
    if (defined $_) {
      if (ref $_) {
        $item = $self->new($_)->serialize;
        $length = _utf16_code_units_length $item;
      }
      elsif (is_utf8($_) || defined eval { $_ = decode("utf8", $_, 1) }) {
        $item = $_;
        $length = _utf16_code_units_length $item;
      }
      else {
        $item = $_;
        $length = _utf16_code_units_length $item;
      }
    }
    else {
      $item = "null";
      $length = length $item;
    }

    $result .= $self->length_string($length) . $item . ":";
  }
  $result .= "]";

  $self->{RAW} = $result;
}

1;

=head1 NAME

Test::FitNesse::Slim::List - Parse and serialize SLiM list values

=head1 DESCRIPTION

This module handles the nested list representation used inside SLiM
messages. Serialized string lengths count UTF-16 code units; the server is
responsible for outer UTF-8 byte framing. Parsing validates the complete
input, including nesting and configurable resource limits, and dies with a
descriptive error for malformed data.

=head1 METHODS

=head2 new

    my $list = Test::FitNesse::Slim::List->new($serialized, limits => \%limits);
    my $list = Test::FitNesse::Slim::List->new(\@values);

Construct a parser from serialized text or a serializer from an array
reference. Optional limits override C<%DEFAULT_LIMITS>. The object is lazy:
serialized input is parsed when C<list> is requested.

=head2 list

Return the list's values. Nested lists are array references and protocol
nulls are represented by C<undef>. Malformed input throws an exception.

=head2 serialize

Return the serialized SLiM list string. Unicode length fields use UTF-16
code units. References are recursively serialized as nested lists.

=head2 length_string

Format a six-digit-minimum decimal length prefix for an inner list item.
Expanded lengths are permitted.

=head1 LIMITS

C<%DEFAULT_LIMITS> defines maximum nesting (128), decoded elements
(1,000,000), item length (16,777,216 UTF-16 units), and frame bytes
(67,108,864). These are server defensive defaults, not protocol limits.

=cut
