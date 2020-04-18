package WARC::Record::Sponge;					# -*- CPerl -*-

use strict;
use warnings;

use Carp;

our @ISA = qw(WARC::Record);

use File::Spec;
use File::Temp qw/:seekable/;	# imports SEEK_* constants
use MIME::Base32 qw/encode_rfc3548/;
use Symbol qw//;

use WARC; *WARC::Record::Sponge::VERSION = \$WARC::VERSION;

require WARC::Record;

use overload '*{}' => \&_as_handle;
use overload fallback => 1;

=head1 NAME

WARC::Record::Sponge - data sponge for WARC records

=head1 SYNOPSIS

  use Digest::SHA;
  use WARC::Builder;
  use WARC::Record::Sponge;

  $builder = new WARC::Builder ( ... );
  $sponge = new WARC::Record::Sponge ( type => 'response' );
  $sponge->begin_digest(block => sha1 => new Digest::SHA ('sha1'));

  while (<$socket>) {
    print $sponge $_;
    # ... other processing ...
    $sponge->begin_digest(payload => sha1 => new Digest::SHA ('sha1'))
     if $end_of_headers_reached;
  }

  $builder->add($sponge);	# add to growing WARC volume

=cut

# This implementation uses a filehandle tied to a hash.
#  Keys defined in the inner hash:
#
#   digests
#	Hash mapping digest names to [<tag>, <digest object>] pairs
#   file
#	File::Temp object
#   handle
#	Tied file handle
#   length
#	Number of valid bytes in the temporary file
#   writing
#	Current mode; true if in "soak" phase

=head1 DESCRIPTION

C<WARC::Record::Sponge> objects provide a streaming interface for
constructing WARC records as data is received using a temporary file to
store the record content.  This allows recording records that exceed
available memory.

This class provides objects with a tied filehandle interface using a data
sponge model.  In the "soak" phase, data is written to the handle, along
with markers indicating the computation of digests for that data.  In the
"squeeze" phase, data is read back from the handle and the digests are
collected.  The object can then be reset to return to the "soak" phase to
collect new data and "squeezed" again.  All digest markers are removed upon
returning to the "soak" phase.  The handle is seekable in the "squeeze"
phase, but append-only in the "soak" phase.

A C<WARC::Record::Sponge> isa C<WARC::Record> and inherits the C<fields>
method.  Header fields may be set on a C<WARC::Record::Sponge>, but all
fields other than "WARC-Type" are erased when the C<reset> method is used.

=head2 Methods

=over

=item $sponge = new WARC::Record::Sponge ( ... )

=cut

our $TmpDir = File::Spec->tmpdir;

sub new {
  my $class = shift;
  my $ob = $class->SUPER::new(@_);
  %$ob = (%$ob, digests => {}, length => undef, writing => 1);

  my $xhandle = Symbol::geniosym;
  tie *$xhandle, $class.'::TiedHandle', $ob;
  $ob->{handle} = $xhandle;

  $ob->{file} = File::Temp->new
      (UNLINK => 1, DIR => $TmpDir, TEMPLATE => 'warc-block-'.('X' x 12));
  binmode $ob->{file}, ':raw';

  { our $_total_constructed; $_total_constructed++ }

  return $ob
}

sub DESTROY { our $_total_destroyed; $_total_destroyed++ }

sub block {
  my $self = shift;

  unless (@_) {
    # slurp the current contents; may run out of memory but that is the
    # caller's problem if this method is called on a record data sponge
    my $pos = $self->{file}->sysseek(0, SEEK_CUR);
    $self->{file}->sysseek(0, SEEK_SET);
    my $buf = do {local $/ = undef; readline $self->{file}};
    $self->{file}->sysseek($pos, SEEK_SET);
    return $buf
  }

  # otherwise, replace the file contents with the provided data
  croak "attempt to replace block during squeeze phase"
    unless $self->{writing};
  # setting digest markers is not possible if a block is supplied
  $self->{digests} = {};
  $self->SUPER::block(@_);
  $self->{file}->sysseek(0, SEEK_SET);
  $self->{file}->syswrite($self->{block});
  delete $self->{block};
}

=item $sponge-E<gt>begin_digest ( $key , $tag , $digest )

Insert a digest marker using a digest object that must support the C<add>,
C<clone>, and C<digest> methods from the C<Digest> API.  All data written
to the record is included in all digests active when the data is written.

=cut

sub begin_digest {
  my $self = shift;

  $self->{digests}{$_[0]} = [$_[1], $_[2]];
  return
}

=item $value = $sponge-E<gt>get_digest ( $key )

Return a digest value for the data from the digest marker inserted with the
given key to the current end of the data.  The result is a Base32 value
labelled with the tag given when the digest was started.

=cut

sub get_digest {
  my $self = shift;
  my $cell = $self->{digests}{$_[0]};

  return undef unless $cell;
  return $cell->[0].':'.encode_rfc3548($cell->[1]->clone->digest)
}

=item $sponge-E<gt>readback

End the "soak" phase and switch to the "squeeze" phase.

=cut

sub readback {
  my $self = shift;

  $self->{length} = $self->{file}->sysseek(0, SEEK_CUR);
  $self->{fields}->field('Content-Length', $self->{length});
  $self->{writing} = 0;
  $self->{file}->sysseek(0, SEEK_SET);

  return
}

=item $sponge-E<gt>content_length

Return the length of the data stored in the sponge if called in the
"squeeze" phase.  Returns undefined if called during the "soak" phase.

=cut

# The inherited method will work, but this is slightly more efficient.
sub content_length { (shift)->{length} }

=item $sponge-E<gt>reset

End the "squeeze" phase and return to a new "soak" phase.

=cut

sub reset {
  my $self = shift;

  $self->{length} = undef;
  $self->{digests} = {};
  $self->{writing} = 1;
  $self->{file}->sysseek(0, SEEK_SET);

  foreach my $key (keys %{$self->{fields}})
    { delete $self->{fields}{$key} unless $key eq 'WARC-Type' }

  return
}

=back

=cut

sub _as_handle { (shift)->{handle} }

sub _add_syswrite_buffer {
  my $self = shift; my $buf = substr $_[0], $_[2] || 0, $_[1];
  foreach (values %{$self->{digests}}) { $_->[1]->add($buf) }
}

{
  package WARC::Record::Sponge::TiedHandle;

  use Errno qw/EBADF/;		# POSIX defines this, so we should have it.
  use Fcntl qw/SEEK_CUR/;
  use Scalar::Util qw/weaken/;

  # The underlying object is a weak reference to the parent record sponge.

  sub TIEHANDLE {
    my $class = shift;
    my $parent = shift;

    my $ob = bless \ $parent, $class;
    weaken $$ob;
    return $ob
  }

  # The Perl debugger uses the fileno operator when printing a handle.
  sub FILENO	{ my $self = ${(shift)}; fileno $self->{file}		}

  sub BINMODE	{ my $self = ${(shift)}; binmode $self->{file}, shift	}
  sub CLOSE	{ my $self = ${(shift)};
		  if ($self->{writing}) { $self->readback }
		  else			{ $self->reset }
					 return 1			}

  sub WRITE	{ my $self = ${(shift)};
		  unless ($self->{writing}) { $! = EBADF; return }
		  $self->_add_syswrite_buffer(@_);
					 $self->{file}->syswrite(@_)	}
  sub PRINT	{ my $self = ${(shift)};
		  my $buf = join(defined($,) ? $, : '', @_);
		  $buf .= $\ if defined($\);
					 syswrite $self, $buf		}
  sub PRINTF	{ my $self = ${(shift)}; my $fmt = shift;
		  local $\ = '';	 print $self sprintf $fmt, @_	}

  sub SEEK	{ my $self = ${(shift)};
		  return undef if $self->{writing};
					 $self->{file}->sysseek(@_)	}
  sub TELL	{ my $self = ${(shift)};
				$self->{file}->sysseek(0, SEEK_CUR)	}

  sub EOF	{ my $self = ${(shift)}; return 1 if $self->{writing};
		  return (tell $self >= $self->{length})		}

  # This sub must rely on the aliasing effect of @_.
  sub READ {
    my $self = ${(shift)};
    # args now:  0: buffer  1: length  2: offset into buffer or undef
    my $length = $_[1];
    my $offset = $_[2] || 0;

    if ($self->{writing}) { $! = EBADF; return undef }

    my $excess = (($length + $self->{file}->sysseek(0, SEEK_CUR))
		  - $self->{length});
    $length -= $excess if $excess > 0;
    return 0 unless $length;

    my $buf; my $count = sysread $self->{file}, $buf, $length;
    return undef unless defined $count;

    $_[0] = '' unless defined $_[0];
    $_[0] .= "\0" x ($offset - length($_[0])) if $offset > length $_[0];
    substr $_[0], $offset, (length($_[0]) - $offset), $buf;
    return $count;
  }
}

1;
__END__

=head1 CAVEATS

The readback mode only implements block reads using C<read> or C<sysread>;
C<readline> and C<getc> are not implemented.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>, L<WARC::Builder>, L<WARC>, L<Digest>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
