package Text::KDL::XS::Parser;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Text::KDL::XS ();

our @CARP_NOT = qw(
    Text::KDL::XS Text::KDL::XS::Document Text::KDL::XS::Emitter
    Text::KDL::XS::Node Text::KDL::XS::Value
);

my $DEFAULT_MAX_DEPTH = 512;
my $LARGEST_MAX_DEPTH = ~0 >> 1;
my %IS_OPTION         = map { $_ => 1 } qw(version emit_comments max_depth);

sub new {
    my ($class, $source, @options) = @_;

    Carp::croak(__PACKAGE__ . ": source is required") unless defined $source;
    my $options   = Text::KDL::XS::_parse_named_arguments(__PACKAGE__, 'option', \%IS_OPTION, @options);
    my $flags     = _option_flags($options);
    my $max_depth = _max_depth($options->{max_depth});
    my $reader    = _is_text_source($source) ? undef : _reader_for($source);

    my $parser;
    eval {
        $parser = $reader
            ? $class->_new_stream_parser($reader, $flags, $max_depth)
            : $class->_new_string_parser($source, $flags, $max_depth);
        1;
    } or Text::KDL::XS::_rethrow($@, __FILE__);
    return $parser;
}

sub next_event {
    my ($self) = @_;
    my $event;
    eval { $event = $self->_next_event; 1 } or Text::KDL::XS::_rethrow($@, __FILE__);
    return $event;
}

sub _option_flags {
    my ($options) = @_;
    my $version = Text::KDL::XS::_normalize_version(__PACKAGE__, $options->{version});
    my $flags
        = $version eq '1' ? Text::KDL::XS::_OPT_V1()
        : $version eq '2' ? Text::KDL::XS::_OPT_V2()
        :                   Text::KDL::XS::_OPT_DETECT();
    $flags |= Text::KDL::XS::_OPT_EMIT_COMMENTS() if $options->{emit_comments};
    return $flags;
}

sub _max_depth {
    my ($max_depth) = @_;
    return $DEFAULT_MAX_DEPTH unless defined $max_depth;
    Carp::croak(__PACKAGE__ . ": max_depth must be a non-negative integer, got '$max_depth'")
        unless $max_depth =~ /\A[0-9]+\z/ && $max_depth <= $LARGEST_MAX_DEPTH;
    return $max_depth;
}

# A plain string, as opposed to a reference or a bare glob such as *STDIN.
sub _is_text_source {
    my ($source) = @_;
    return !ref $source && ref \$source ne 'GLOB';
}

# The code reference that delivers the chunks of a callback, filehandle or IO
# object source to the XS layer.
sub _reader_for {
    my ($source) = @_;
    my $reftype = Scalar::Util::reftype($source) // '';

    return $source if $reftype eq 'CODE';
    return _reader_for_handle($source) if Scalar::Util::openhandle($source);
    Carp::croak(__PACKAGE__ . ": filehandle is not open")
        if $reftype eq 'GLOB' || $reftype eq 'IO' || ref \$source eq 'GLOB';
    return _reader_for_object($source)
        if Scalar::Util::blessed($source) && ($source->can('read') || $source->can('sysread'));
    Carp::croak(__PACKAGE__ . ": unsupported source ref type '" . ref($source) . "'");
}

# Reads an open filehandle with the PerlIO-aware read, so that layers such as
# :encoding(UTF-8), data buffered by earlier reads and in-memory handles work.
sub _reader_for_handle {
    my ($handle) = @_;
    return sub {
        my ($wanted_bytes) = @_;
        my $count = read($handle, my $chunk, $wanted_bytes);
        Carp::croak(__PACKAGE__ . ": read failed: $!") unless defined $count;
        return $chunk;
    };
}

sub _reader_for_object {
    my ($object) = @_;
    my $read = $object->can('read') || $object->can('sysread');
    return sub {
        my ($wanted_bytes) = @_;
        my $count = $object->$read(my $chunk, $wanted_bytes);
        Carp::croak(__PACKAGE__ . ": read failed: $!") unless defined $count;
        return $chunk;
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Parser - Streaming, event-based KDL parser

=head1 SYNOPSIS

=for highlighter language=Perl

  use Text::KDL::XS::Parser;

  open my $fh, '<:raw', 'big.kdl' or die $!;
  my $parser = Text::KDL::XS::Parser->new($fh, version => 'detect');

  while (my $ev = $parser->next_event) {
      if ($ev->{event} eq 'start_node') {
          print "node ", $ev->{name}, "\n";
      }
      elsif ($ev->{event} eq 'argument') {
          print "  arg ", $ev->{value}->as_string // '#null', "\n";
      }
      elsif ($ev->{event} eq 'property') {
          print "  $ev->{name} = ", $ev->{value}->as_string // '#null', "\n";
      }
  }
  # next_event returned undef: end of input

=for highlighter

=head1 DESCRIPTION

C<Text::KDL::XS::Parser> exposes ckdl's event stream directly. Instead of
building a tree, it hands you one event at a time: a node starts, an
argument or property was read, a node ends. With a filehandle or code
reference source the input is consumed in chunks, so memory use does not
grow with the document (a string source is copied once in full), and you
can stop reading at any point.

L<Text::KDL::XS/parse_kdl> is built on this class; use it unless you need
streaming, early termination, or access to comments and slashdashed
elements.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=Perl

  my $parser = Text::KDL::XS::Parser->new($source);
  my $parser = Text::KDL::XS::Parser->new($source, version => '2', emit_comments => 1);

=for highlighter

Creates a parser over C<$source>, which must be one of the following.

=over 4

=item String

The whole document as a Perl character string (decode UTF-8 bytes first,
see L<Text::KDL::XS/ENCODING>). The parser keeps a copy, so the caller may
discard or modify the original afterwards.

=item Filehandle or IO object

A glob (C<*STDIN>), a glob reference (C<\*STDIN>, C<$fh>), an IO object
(C<*STDIN{IO}>, L<IO::Handle>, L<IO::File>), a tied handle, or an object
with a C<read> or C<sysread> method. Open handles are read with Perl's
C<read> in chunks whose size ckdl chooses, so every PerlIO layer, data
buffered by earlier reads and in-memory handles work; other objects are
read through their C<read> method (preferred) or C<sysread> method. See
L<Text::KDL::XS/"FILEHANDLE SOURCES">.

=item Code reference

Called as C<< $code->($wanted_bytes) >> whenever the parser needs more
input. Return the next chunk of UTF-8 bytes (a character string is
encoded to UTF-8), or an empty string or C<undef> at the end of the
input; the code reference is not called again after that.
C<$wanted_bytes> is a hint: longer chunks are kept and handed over in
pieces, and chunk boundaries need not align with lines, tokens or
characters. An exception thrown inside the code reference propagates
unchanged out of the C<new> or C<next_event> call that needed the input,
and the parser is failed from then on (see L</next_event>).

=back

The source is read once before C<new> returns: ckdl reads ahead to look
for a byte order mark, so a code reference is called for the first time,
and a read error or exception can occur, inside C<new>.

C<undef> dies with C<Text::KDL::XS::Parser: source is required>; any other
reference type dies with C<Text::KDL::XS::Parser: unsupported source ref
type '...'>, and a closed filehandle with C<Text::KDL::XS::Parser:
filehandle is not open>.

Options:

=over 4

=item version => 'detect' | '1' | '2'

Which KDL version to accept; also C<'v1'> and C<'v2'>, in any letter
case; default C<'detect'>. See L<Text::KDL::XS/"KDL VERSIONS">.

=item emit_comments => 0 | 1

When true, comments produce C<comment> events, and nodes, arguments and
properties that were commented out with a slashdash (C</->) are reported
with C<< commented => 1 >> instead of being dropped. Default false.

=item max_depth => $levels

The deepest nesting of nodes allowed (a top-level node is at depth 1);
default 512, C<0> for unlimited. The event that would go deeper dies with
C<KDL parse error: nesting depth exceeds max_depth (512)>.

=back

Unknown options, an odd number of option arguments and invalid values
die. An option whose value is C<undef> is treated as not given.

C<new> may be called on a subclass, and the parser is then an object of
that class. A parser cannot be used in a thread other than the one that
created it (see L<Text::KDL::XS/THREADS>).

=head1 METHODS

=head2 next_event

=for highlighter language=Perl

  my $ev = $parser->next_event;   # hashref, or undef at end of input

=for highlighter

Returns the next event as a hash reference, or C<undef> once the document
has been consumed. Calling it again after C<undef> keeps returning
C<undef> without reading from the source.

On malformed input it dies with C<KDL parse error: REASON>, where
C<REASON> is ckdl's explanation (for example C<Unexpected end of data
(unclosed lists of children)>); an exception thrown by a source code
reference is passed through unchanged. After an error the parser is
finished: every further call dies with the same error. Errors are
reported at the line of your call.

C<next_event> must not be called from inside the parser's own source code
reference; that dies with C<Text::KDL::XS::Parser: next_event called from
inside the parser's own source callback>.

=head1 EVENT HASH

Each event is a hash reference with these keys:

  key        present for                  value
  ---------  ---------------------------  ----------------------------------------
  event      always                       'start_node' | 'end_node' | 'argument'
                                          | 'property' | 'comment'
  commented  always                       1 if the element was slashdashed (/-),
                                          otherwise 0 (see below)
  name       start_node, property         node name / property key (character string)
  type       start_node, when annotated   the node's type annotation
  value      argument, property           a Text::KDL::XS::Value
  text       comment                      the comment, delimiters included

Notes:

=over 4

=item * C<commented> is only ever 1 when the parser was created with
C<< emit_comments => 1 >>; without that option slashdashed elements are
not reported at all. A slashdashed node reports all of its arguments,
properties, children and its C<end_node> with C<< commented => 1 >>.

=item * C<comment> events (only with C<emit_comments>) carry the comment
as written in C<text>, including its delimiters: C<// note> for a
single-line comment (without the line end), C</* note */> for a
multi-line one. They have C<< commented => 1 >>.

=item * Type annotations on argument and property values are on the
L<Text::KDL::XS::Value> object (C<< $ev->{value}->type_annotation >>), not
in the event hash.

=item * Every C<start_node> is eventually matched by exactly one
C<end_node>, unless a parse error intervenes. Arguments and properties of a
node arrive between its C<start_node> and the C<start_node> of its first
child (or its own C<end_node>).

=item * The event hashes and the value objects in them are fresh Perl data
and may be kept or modified.

=back

=head1 EXAMPLES

=head2 Event sequence for a small document

=for highlighter language=KDL

  node 1 key=2 {
      child 3
  }

=for highlighter

produces, in order:

  start_node  name=node
  argument    value=1
  property    name=key value=2
  start_node  name=child
  argument    value=3
  end_node
  end_node

=head2 Seeing slashdashed elements and comments

=for highlighter language=Perl

  my $p = Text::KDL::XS::Parser->new("// note\nnode 1 /-2 {\n  /-gone\n}\n", emit_comments => 1);
  while (my $ev = $p->next_event) {
      printf "%-10s commented=%d %s\n", $ev->{event}, $ev->{commented}, $ev->{name} // $ev->{text} // '';
  }

=for highlighter

  comment    commented=1 // note
  start_node commented=0 node
  argument   commented=0
  argument   commented=1
  start_node commented=1 gone
  end_node   commented=1
  end_node   commented=0

=head2 Stopping early

Because events are pulled on demand, you can stop as soon as you have what
you need. Here we find the first top-level C<version> node and stop:

=for highlighter language=Perl

  my $p = Text::KDL::XS::Parser->new($big_document);
  my ($depth, $version) = (0);
  while (my $ev = $p->next_event) {
      if ($ev->{event} eq 'start_node') {
          if ($depth == 0 && $ev->{name} eq 'version') {
              my $next = $p->next_event;                    # the next event: usually its first argument
              $version = $next->{value}->as_string if $next && $next->{event} eq 'argument';
              last;
          }
          $depth++;
      }
      elsif ($ev->{event} eq 'end_node') { $depth-- }
  }

=for highlighter

=head2 Building your own structure

The tree builder in L<Text::KDL::XS::Document> is a short loop over these
events and is a good template for custom builders: keep a stack of open
nodes, push on C<start_node>, pop on C<end_node>, attach values to the top
of the stack, and skip events with C<commented> set.

=head1 SEE ALSO

L<Text::KDL::XS>, L<Text::KDL::XS::Value>,
L<Text::KDL::XS::Cookbook/"Stream a large file without building a tree">.

=head1 AUTHOR

Davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 LICENSE

Copyright (C) 2026 Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.

=cut
