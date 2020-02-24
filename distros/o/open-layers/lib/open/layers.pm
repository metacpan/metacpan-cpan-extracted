package open::layers;

use strict;
use warnings;
use Carp ();
use Scalar::Util ();

our $VERSION = '0.003';

# series of layers delimited by colons and consisting of non-space characters
# allow spaces before and between layers because core does, but don't require them
# we require a leading colon even though core doesn't, because it's expected anyway
my $LAYERS_SPEC = qr/\A\s*(?::[^\s:]+\s*)+\z/;

sub import {
  my $class = shift;
  while (@_) {
    my $arg = shift;
    my $ref = Scalar::Util::reftype $arg;
    if ((defined $ref and ($ref eq 'GLOB' or $ref eq 'IO'))
        or (!defined $ref and Scalar::Util::reftype \$arg eq 'GLOB')) {
      Carp::croak "open::layers: No layer provided for handle $arg" unless @_;
      my $layer = shift;
      Carp::croak "open::layers: Invalid layer specification $layer" unless $layer =~ m/$LAYERS_SPEC/;
      binmode $arg, $layer or Carp::croak "open::layers: binmode $arg failed: $!";
    } elsif ($arg =~ m/\ASTD(IN|OUT|ERR|IO)\z/) {
      my $which = $1;
      Carp::croak "open::layers: No layer provided for handle $arg" unless @_;
      my $layer = shift;
      Carp::croak "open::layers: Invalid layer specification $layer" unless $layer =~ m/$LAYERS_SPEC/;
      my @handles = $which eq 'IN' ? \*STDIN
        : $which eq 'OUT' ? \*STDOUT
        : $which eq 'ERR' ? \*STDERR
        : (\*STDIN, \*STDOUT, \*STDERR);
      binmode $_, $layer or Carp::croak "open::layers: binmode $_ failed: $!" for @handles;
    } elsif ($arg =~ m/\A(rw|r|w)\z/) {
      my $which = $1;
      Carp::croak "open::layers: No layer provided for $arg handles" unless @_;
      my $layer = shift;
      Carp::croak "open::layers: Invalid layer specification $layer" unless $layer =~ m/$LAYERS_SPEC/;
      my @layers = $layer =~ m/(:[^\s:]+)/g; # split up the layers so we can set ${^OPEN} like open.pm
      my ($in, $out) = split /\0/, (${^OPEN} || "\0"), -1;
      if ($which ne 'w') { # r, rw
        $in = join ' ', @layers;
      }
      if ($which ne 'r') { # w, rw
        $out = join ' ', @layers;
      }
      ${^OPEN} = join "\0", $in, $out;
    } else {
      Carp::croak "open::layers: Unknown flag $arg (expected STD(IN|OUT|ERR|IO), r/w/rw, or filehandle)";
    }
  }
}

1;

=head1 NAME

open::layers - Set default PerlIO layers

=head1 SYNOPSIS

  {
    # set default layers for open() in this lexical scope
    use open::layers r => ':encoding(UTF-8)';
  }
  # encoding layer no longer applied to handles opened here

  use open::layers r => ':encoding(cp1252)', w => ':encoding(UTF-8)';
  use open::layers rw => ':encoding(UTF-8)'; # all opened handles

  # push layers on the standard handles (not lexical)
  use open::layers STDIN => ':encoding(UTF-8)';
  use open::layers STDOUT => ':encoding(UTF-8)', STDERR => ':encoding(UTF-8)';
  use open::layers STDIO => ':encoding(UTF-8)'; # shortcut for all of above

=head1 DESCRIPTION

This pragma is a reimagination of the core L<open> pragma, which either pushes
L<PerlIO> layers on the global standard handles, or sets default L<PerlIO>
layers for handles opened in the current lexical scope (meaning, innermost
braces or the file scope). The interface is redesigned to be more explicit and
intuitive. See L</"COMPARISON TO open.pm"> for details.

=head1 ARGUMENTS

Each operation is specified in a pair of arguments: the flag specifying the
target of the operation, and the layer(s) to apply. Multiple layers can be
specified like C<:foo:bar>, as in L<open()|perlfunc/open> or
L<binmode()|perlfunc/binmode>.

The flag may be any one of:

=over

=item STDIN, STDOUT, STDERR, STDIO

These strings indicate to push the layer(s) onto the associated standard handle
with L<binmode()|perlfunc/binmode>, affecting usage of that handle globally,
equivalent to calling L<binmode()|perlfunc/binmode> on the handle in a C<BEGIN>
block. C<STDIO> is a shortcut to operate on all three standard handles.

Note that this will also affect reading from C<STDIN> via L<ARGV|perlvar/ARGV>
(empty C<< <> >>, C<<< <<>> >>>, or L<readline()|perlfunc/readline>).

=item $handle

An arbitrary filehandle (glob or reference to a glob, B<not> a bareword) will
have layer(s) pushed onto it directly, affecting all usage of that handle,
similarly to the operation on standard handles.

Note that the handle must be opened in the compile phase (such as in a
preceding C<BEGIN> block) in order to be available for this pragma to operate
on it.

=item r, w, rw

These strings indicate to set the default layer stack for handles opened in the
current lexical scope: C<r> for handles opened for reading, C<w> for handles
opened for writing (or C<O_RDWR>), and C<rw> for all handles.

This lexical effect works by setting L<${^OPEN}|perlvar/${^OPEN}>, like the
L<open> pragma and C<-C> switch. The functions L<open()|perlfunc/open>,
L<sysopen()|perlfunc/sysopen>, L<pipe()|perlfunc/pipe>,
L<socketpair()|perlfunc/socketpair>, L<socket()|perlfunc/socket>,
L<accept()|perlfunc/accept>, and L<readpipe()|perlfunc/readpipe> (C<qx> or
backticks) are affected by this variable. Indirect calls to these functions via
modules like L<IO::Handle> occur in a different lexical scope, so are not
affected, nor are directory handles such as opened by
L<opendir()|perlfunc/opendir>.

Note that this will also affect implicitly opened read handles such as files
opened by L<ARGV|perlvar/ARGV> (empty C<< <> >>, C<<< <<>> >>>, or
L<readline()|perlfunc/readline>), but B<not> C<STDIN> via C<ARGV>, or
L<DATA|perldata/"Special Literals">.

A three-argument L<open()|perlfunc/open> call that specifies layers will ignore
any lexical defaults. A single C<:> (colon) also does this, using the default
layers for the architecture.

  use open::layers rw => ':encoding(UTF-8)';
  open my $fh, '<', $file; # sets UTF-8 layer (and its implicit platform defaults)
  open my $fh, '>:unix', $file; # ignores UTF-8 layer and sets :unix
  open my $fh, '<:', $file; # ignores UTF-8 layer and sets platform defaults

=back

=head1 COMPARISON TO open.pm

=over

=item *

Unlike L<open>, C<open::layers> requires that the target of the operation is
always specified so as to not confuse global and lexical operations.

=item *

Unlike L<open>, C<open::layers> can push layers to the standard handles without
affecting handles opened in the lexical scope.

=item *

Unlike L<open>, multiple layers are not required to be space separated.

=item *

Unlike L<open>, duplicate existing encoding layers are not removed from the
standard handles. Either ensure that nothing else is setting encoding layers on
these handles, or use the C<:raw> pseudo-layer to "reset" the layers to a
binary stream before applying text translation layers.

  use open::layers STDIO => ':raw:encoding(UTF-16BE)';
  use open::layers STDIO => ':raw:encoding(UTF-16BE):crlf'; # on Windows 5.14+

=item *

Unlike L<open>, the C<:locale> pseudo-layer is not (yet) implemented. Consider
installing L<PerlIO::locale> to support this layer.

=back

=head1 PERLIO LAYERS

PerlIO layers are described in detail in the L<PerlIO> documentation. Their
implementation has several historical quirks that may be useful to know:

=over

=item *

Layers are an ordered stack; a read operation will go through the layers in the
order they are set (left to right), and a write operation in the reverse order.

=item *

The C<:unix> layer implements the lowest level unbuffered I/O, even on Windows.
Most other layers operate on top of this and usually a buffering layer like
C<:perlio> or C<:crlf>, and these low-level layers make up the platform
defaults.

=item *

Many layers are not real layers that actually implement I/O or translation;
these are referred to as pseudo-layers. Some (like C<:utf8>) set flags on
previous layers that change how they operate. Some (like C<:pop>) simply modify
the existing set of layers. Some (like C<:raw>) may do both.

=item *

The C<:crlf> layer is not just a translation between C<\n> and C<CRLF>. On
Windows, it is the layer that implements I/O buffering (like C<:perlio> on
Unix-like systems), and operations that would remove the C<CRLF> translation
(like L<binmode()|perlfunc/binmode> with no layers, or pushing a C<:raw>
pseudo-layer) actually just disable the C<CRLF> translation flag on this layer.
Since Perl 5.14, pushing a C<:crlf> layer on top of other translation layers on
Windows correctly adds a C<CRLF> translation layer in that position. (On
Unix-like systems, C<:crlf> is a mundane C<CRLF> translation layer.)

=item *

The C<:utf8> pseudo-layer sets a flag that indicates the preceding stack of
layers will translate the input to Perl's internal upgraded string format,
which may resemble UTF-8 or UTF-EBCDIC, or will translate the output from that
format. It is B<not> an encoding translation layer, but an assumption about the
byte stream; use C<:encoding(UTF-8)> or L<PerlIO::utf8_strict> to apply a
translation layer. Any encoding translation layer will generally set the
C<:utf8> flag, even when the desired encoding is not UTF-8, as they translate
between the desired encoding and Perl's internal format. (The C<:bytes>
pseudo-layer unsets this flag, which is very dangerous if encoding translation
layers are used.)

=item *

I/O to an in-memory scalar variable instead of a file is implemented by the
C<:scalar> layer taking the place of the platform defaults, see
L<PerlIO::scalar>. The scalar is expected to act like a file, i.e. only contain
or store bytes.

=item *

Layers specified when opening a handle, such as in a three-argument
L<open()|perlfunc/open> or default layers set in L<${^OPEN}|perlvar/${^OPEN}>
(via the lexical usage of this pragma or the L<open> pragma), will define the
complete stack of layers on that handle. Certain layers implicitly include
lower-level layers that are needed, for example C<:encoding(UTF-8)> will
implicitly prepend the platform defaults C<:unix:perlio> (or similar).

=item *

In contrast, when adjusting layers on an existing handle with
L<binmode()|perlfunc/binmode> (or the non-lexical usage of this pragma or the
L<open> pragma), the specified layers are pushed at the end of the handle's
existing layer stack, and any special operations of pseudo-layers take effect.
So you can open an unbuffered handle with only C<:unix>, but to remove existing
layers on an already open handle, you must push pseudo-layers like C<:pop> or
C<:raw> (equivalent to calling L<binmode()|perlfunc/binmode> with no layers).

=back

=head1 CAVEATS

The L<PerlIO> layers and L<open> pragma have experienced several issues over
the years, most of which can't be worked around by this module. It's
recommended to use a recent Perl if you will be using complex layers; for
compatibility with old Perls, stick to L<binmode()|perlfunc/binmode> (either
with no layers for a binary stream, or with a single C<:encoding> layer). Here
are some selected issues:

=over

=item *

Before Perl 5.8.8, L<open()|perlfunc/open> called with three arguments would
ignore L<${^OPEN}|perlvar/${^OPEN}> and thus any lexical default layers.
L<[perl #8168]|https://github.com/Perl/perl5/issues/8168>

=item *

Before Perl 5.8.9, the C<:crlf> layer did not preserve the C<:utf8> flag from
an earlier encoding layer, resulting in an improper translation of the bytes.
This can be worked around by adding the C<:utf8> pseudo-layer after C<:crlf>
(even if it is not a UTF-8 encoding).

=item *

Before Perl 5.14, the C<:crlf> layer does not properly apply on top of another
layer, such as an encoding layer, if it had also been applied earlier in the
stack such as is default on Windows. Thus you could not usefully use a layer
like C<:encoding(UTF-16BE)> with a following C<:crlf>.
L<[perl #8325]|https://github.com/Perl/perl5/issues/8325>

=item *

Before Perl 5.14, the C<:pop>, C<:utf8>, or C<:bytes> pseudo-layers did not
allow stacking further layers, like C<:pop:crlf>.
L<[perl #11054]|https://github.com/perl/perl5/issues/11054>

=item *

Before Perl 5.14, the C<:raw> pseudo-layer reset the handle to an unbuffered
state, rather than just removing text translation layers as when calling
L<binmode()|perlfunc/binmode> with no layers.
L<[perl #10904]|https://github.com/perl/perl5/issues/10904>

=item *

Before Perl 5.14, the C<:raw> pseudo-layer did not work properly with in-memory
scalar handles.

=item *

Before Perl 5.16, L<use|perlfunc/use> and L<require()|perlfunc/require> are
affected by lexical default layers when loading the source file, leading to
unexpected results. L<[perl #11541]|https://github.com/perl/perl5/issues/11541>

=back

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<open>, L<PerlIO>
