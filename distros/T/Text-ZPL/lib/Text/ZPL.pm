package Text::ZPL;
$Text::ZPL::VERSION = '0.003001';
use strict; use warnings FATAL => 'all';
no warnings 'void';

use Carp;
use Scalar::Util 'blessed', 'reftype';

use parent 'Exporter::Tiny';
our @EXPORT = our @EXPORT_OK = qw/
  encode_zpl
  decode_zpl
/;


# note: not anchored as-is:
our $ValidName = qr/[A-Za-z0-9\$\-_\@.&+\/]+/;


sub decode_zpl {
  confess "Expected a ZPL text string but received no arguments"
    unless defined $_[0];

  my $root = my $ref = +{};
  my @descended;

  my ($level, $lineno) = (0,0);

  LINE: for my $line (split /(?:\015?\012)|\015/, $_[0]) {
    ++$lineno;
    # Prep string in-place & skip blank/comments-only:
    next LINE unless _decode_prepare_line($line);

    _decode_handle_level($lineno, $line, $root, $ref, $level, \@descended);

    if ( (my $sep_pos = index($line, '=')) > 0 ) {
      my ($key, $val) = _decode_parse_kv($lineno, $line, $level, $sep_pos);
      _decode_add_kv($lineno, $ref, $key, $val);
      next LINE
    } elsif (my ($subsect) = $line =~ /^(?:\s+)?($ValidName)(?:\s+?#.*)?$/) {
      _decode_add_subsection($lineno, $ref, $subsect, \@descended);
      next LINE
    }

    confess
       "Invalid ZPL (line $lineno); "
      ."unrecognized syntax or bad section name: '$line'"
  } # LINE

  $root
}

sub _decode_prepare_line {
  $_[0] =~ s/\s+$//;
  !(length($_[0]) == 0 || $_[0] =~ /^(?:\s+)?#/)
}

sub _decode_handle_level {
  # ($lineno, $line, $root, $ref, $level, $tree_ref)
  # 
  # Manage indentation-based hierarchy
  # Validates indent level
  # Munges current $ref, $level, $tree_ref in-place

  my $cur_indent = 0;
  $cur_indent++ while substr($_[1], $cur_indent, 1) eq ' ';
  if ($cur_indent % 4) {
    confess
       "Invalid ZPL (line $_[0]); "
      ."expected 4-space indent, indent is $cur_indent"
  }

  if ($cur_indent == 0) {
    $_[3] = $_[2];
    $_[4] = $cur_indent;
    @{ $_[5] } = ();
  } elsif ($cur_indent > $_[4]) {
    unless (defined $_[5]->[ ($cur_indent / 4) - 1 ]) {
      confess "Invalid ZPL (line $_[0]); no matching parent section"
    }
    $_[4] = $cur_indent;
  } elsif ($cur_indent < $_[4]) {
    my $wanted_idx = ( ($_[4] - $cur_indent) / 4 ) - 1 ;
    my $wanted_ref = $_[5]->[$wanted_idx];
    $_[3] = $wanted_ref;
    $_[4] = $cur_indent;
    @{ $_[5] } = @{ $_[5] }[ ($wanted_idx + 1) .. $#{ $_[5] } ];
  }
}

sub _decode_add_subsection {
  # ($lineno, $ref, $subsect, \@descended)
  if (exists $_[1]->{ $_[2] }) {
    confess "Invalid ZPL (line $_[0]); existing property '$_[2]'"
  }
  unshift @{ $_[3] }, $_[1];
  $_[1] = $_[1]->{ $_[2] } = +{};
}


sub _decode_parse_kv {
  # ($lineno, $line, $level, $sep_pos)
  #
  # Takes a line that appears to contain a k = v pair
  # Returns ($key, $val)

  my $key = substr $_[1], $_[2], ( $_[3] - $_[2] );
  $key =~ s/\s+$//;
  unless ($key =~ /^$ValidName$/) {
    confess "Invalid ZPL (line $_[0]); "
            ."'$key' is not a valid ZPL property name"
  }

  my $tmpval = substr $_[1], $_[3] + 1;
  $tmpval =~ s/^\s+//;

  my $realval;
  my $maybe_q = substr $tmpval, 0, 1;
  if ( ($maybe_q eq q{'} || $maybe_q eq q{"}) 
    && (my $matching_q_pos = index $tmpval, $maybe_q, 1) > 1 ) {
    # Quoted, consume up to matching and clean up tmpval
    $realval = substr $tmpval, 1, ($matching_q_pos - 1), '';
    substr $tmpval, 0, 2, '';
  } else {
    # Unquoted or mismatched quotes
    my $maybe_trailing = index $tmpval, ' ';
    $realval = substr $tmpval, 0,
      ($maybe_trailing > -1 ? $maybe_trailing : length $tmpval),
      '';
  }

  $tmpval =~ s/(?:\s+)?(?:#.*)?$//;
  if (length $tmpval) {
    confess "Invalid ZPL (line $_[0]); garbage at end-of-line: '$tmpval'"
  }

  ($key, $realval)
}

sub _decode_add_kv {
  # ($lineno, $ref, $key, $val)
  #
  # Add a value to property; create lists as-needed

  if (exists $_[1]->{ $_[2] }) {
    if (! ref $_[1]->{ $_[2] }) {
      $_[1]->{ $_[2] } = [ $_[1]->{ $_[2] }, $_[3] ]
    } elsif (ref $_[1]->{ $_[2] } eq 'ARRAY') {
      push @{ $_[1]->{ $_[2] } }, $_[3]
    } elsif (ref $_[1]->{ $_[2] } eq 'HASH') {
      confess
        "Invalid ZPL (line $_[0]); existing subsection with this name"
    }
    return
  }
  $_[1]->{ $_[2] } = $_[3]
}


sub encode_zpl {
  my ($obj) = @_;
  $obj = $obj->TO_ZPL if blessed $obj and $obj->can('TO_ZPL');
  confess "Expected a HASH but got $obj" unless ref $obj eq 'HASH';
  _encode($obj)
}

sub _encode {
  my ($ref, $indent) = @_;
  $indent ||= 0;
  my $str = '';

  KEY: for my $key (keys %$ref) {
    confess "$key is not a valid ZPL property name"
      unless $key =~ qr/^$ValidName$/;
    my $val = $ref->{$key};
    
    if (blessed $val && $val->can('TO_ZPL')) {
      $val = $val->TO_ZPL;
    }

    if (ref $val eq 'ARRAY') {
      $str .= _encode_array($key, $val, $indent);
      next KEY
    }

    if (ref $val eq 'HASH') {
      $str .= ' ' x $indent;
      $str .= "$key\n";
      $str .= _encode($val, $indent + 4);
      next KEY
    }
    
    if (ref $val) {
      confess "Do not know how to handle '$val'"
    }

    $str .= ' ' x $indent;
    $str .= "$key = " . _maybe_quote($val) . "\n";
  }

  $str
}

sub _encode_array {
  my ($key, $ref, $indent) = @_;
  my $str = '';
  for my $item (@$ref) {
    confess "ZPL does not support structures of this type in lists: ".ref $item
      if ref $item;
    $str .= ' ' x $indent;
    $str .= "$key = " . _maybe_quote($item) . "\n";
  }
  $str
}

sub _maybe_quote {
  my ($val) = @_;
  return qq{'$val'}
    if index($val, q{"}) > -1
    and index($val, q{'}) == -1;
  return qq{"$val"}
    if index($val, '#')  > -1
    or index($val, '=')  > -1
    or (index($val, q{'}) > -1 and index($val, q{"}) == -1)
    or $val =~ /\s/;  # last because slow :\
  $val
}

1;

=pod

=head1 NAME

Text::ZPL - Encode and decode ZeroMQ Property Language

=head1 SYNOPSIS

  # Decode ZPL to a HASH:
  my $data = decode_zpl( $zpl_text );

  # Encode a HASH to ZPL text:
  my $zpl = encode_zpl( $data );

  # From a shell; examine the Perl representation of a ZPL document:
  sh$ zpl_to_pl my_config.zpl

=head1 DESCRIPTION

An implementation of the C<ZeroMQ Property Language>, a simple ASCII
configuration file format; see L<http://rfc.zeromq.org/spec:4> for details.

Exports two functions by default: L</decode_zpl> and L</encode_zpl>. This
module uses L<Exporter::Tiny> to export functions, which allows for flexible
import options; see the L<Exporter::Tiny> documentation for details.

As a simple example, a C<ZPL> file as such:

  # This is my conf.
  # There are many like it, but this one is mine.
  confname = "My Config"

  context
      iothreads = 1

  main
      publisher
          bind = tcp://eth0:5550
          bind = tcp://eth0:5551
      subscriber
          connect = tcp://192.168.0.10:5555

... results in a structure like:

  {
    confname => "My Config",
    context => { iothreads => '1' },
    main => {
      subscriber => {
        connect => 'tcp://192.168.0.10:5555'
      },
      publisher => {
        bind => [ 'tcp://eth0:5550', 'tcp://eth0:5551' ]
      }
    }
  }

=head2 decode_zpl

Given a string of C<ZPL>-encoded text, returns an appropriate Perl C<HASH>; an
exception is thrown if invalid input is encountered.

(See L<Text::ZPL::Stream> for a streaming interface.)

=head2 encode_zpl

Given a Perl C<HASH>, returns an appropriate C<ZPL>-encoded text string; an
exception is thrown if the data given cannot be represented in C<ZPL> (see
L</CAVEATS>).

=head3 TO_ZPL

A blessed object can provide a B<TO_ZPL> method that will supply a plain
C<HASH> or C<ARRAY> (but see L</CAVEATS>) to the encoder:

  # Shallow-clone this object's backing hash, for example:
  sub TO_ZPL {
    my $self = shift;
    +{ %$self }
  }

=head2 CAVEATS

Not all Perl data structures can be represented in ZPL; specifically,
deeply-nested structures in an C<ARRAY> will throw an exception:

  # Simple list is OK:
  encode_zpl(+{ list => [ 1 .. 3 ] });
  #  -> list: 1
  #     list: 2
  #     list: 3
  # Deeply nested is not representable:
  encode_zpl(+{
    list => [
      'abc',
      list2 => [1 .. 3]
    ],
  });
  #  -> dies

Encoding skips empty lists (C<ARRAY> references).

(The spec is unclear on all this; issues welcome via RT or GitHub!)

=head1 SEE ALSO

The L<Text::ZPL::Stream> module for processing ZPL piecemeal.

The bundled L<zpl_to_pl> script for examining parsed ZPL.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
