package Text::KDL::XS::Parser;

use strict;
use warnings;

use Scalar::Util ();
use Carp ();

# Constructor:
#   Text::KDL::XS::Parser->new($source, %opts)
#     $source : string | filehandle | coderef returning chunks
#     %opts   : version       => 'detect'|'1'|'2'   (default: detect)
#               emit_comments => 0|1                (default: 0)
sub new {
    my ($class, $source, %opts) = @_;

    Carp::croak("Text::KDL::XS::Parser: source is required")
        unless defined $source;

    my $opts_int = _build_opt_flags(\%opts);

    if (my $reftype = ref $source) {
        return $class->_new_stream_parser($source, $opts_int)
            if $reftype eq 'CODE';

        my $reader = _make_io_reader($source);
        return $class->_new_stream_parser($reader, $opts_int)
            if $reader;

        Carp::croak("Text::KDL::XS::Parser: unsupported source ref type '$reftype'");
    }

    return $class->_new_string_parser($source, $opts_int);
}

# Returns the next event hashref, or undef at EOF. Dies on parse error.
sub next_event {
    my ($self) = @_;
    return $self->_next_event;
}

# --- internals -------------------------------------------------------------

sub _build_opt_flags {
    my ($opts) = @_;

    my $version = lc($opts->{version} // 'detect');
    my $flags
        = $version eq 'detect' ? Text::KDL::XS::_OPT_DETECT()
        : $version eq '1'      ? Text::KDL::XS::_OPT_V1()
        : $version eq '2'      ? Text::KDL::XS::_OPT_V2()
        : Carp::croak("unknown version '$version' (expected 'detect', '1', or '2')");

    $flags |= Text::KDL::XS::_OPT_EMIT_COMMENTS() if $opts->{emit_comments};
    return $flags;
}

# Wrap a filehandle / IO object as a Perl sub the XS layer can call.
sub _make_io_reader {
    my ($source) = @_;

    my $reftype = Scalar::Util::reftype($source) // '';
    return undef unless $reftype eq 'GLOB' || Scalar::Util::blessed($source);

    # Duck-type: must support sysread or read.
    my $can_sysread = $reftype eq 'GLOB' || (Scalar::Util::blessed($source)
        && ($source->can('sysread') || $source->can('read')));
    return undef unless $can_sysread;

    return sub {
        my ($want) = @_;
        my $buf = '';
        my $n;
        if ($reftype eq 'GLOB') {
            $n = sysread($source, $buf, $want);
        }
        elsif ($source->can('sysread')) {
            $n = $source->sysread($buf, $want);
        }
        else {
            $n = $source->read($buf, $want);
        }
        return defined $n && $n > 0 ? $buf : '';
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Parser - Streaming KDL event parser

=head1 SYNOPSIS

  use Text::KDL::XS::Parser;

  my $p = Text::KDL::XS::Parser->new(\*STDIN, version => 'detect');
  while (my $ev = $p->next_event) {
      printf "%-12s %s\n", $ev->{event}, $ev->{name} // '';
  }

=head1 DESCRIPTION

A thin wrapper over ckdl's C<kdl_parser> exposing a SAX-like iterator.

=head2 Source types

=over 4

=item * String - parsed in-memory.

=item * Filehandle / blessed IO object - read in chunks via C<sysread>.

=item * Code reference - invoked with a desired buffer size, returning
bytes (or C<undef>/empty at EOF).

=back

=head2 Event hash

Each event is a hash reference with these keys (most are optional and only
present on relevant event kinds):

  {
      event      => 'start_node' | 'end_node' | 'argument' | 'property' | 'comment',
      commented  => 0 | 1,                # slashdash marker
      name       => $string,              # for start_node and property
      type       => $string,              # node type annotation, optional
      value      => Text::KDL::XS::Value, # for argument and property
  }

C<comment> events are only produced when the parser was constructed with
C<< emit_comments => 1 >>. C<next_event> returns C<undef> at end of input
and C<die>s on a parse error.

=cut
