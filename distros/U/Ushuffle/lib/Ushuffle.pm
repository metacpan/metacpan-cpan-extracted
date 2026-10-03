package Ushuffle;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = ('Exporter');
our @EXPORT_OK = qw(shuffle set_seed);

our $VERSION = '1.00';

# the class is defined in the XS file
$Ushuffle::Shuffler::VERSION = $VERSION;

require XSLoader;
XSLoader::load('Ushuffle', $VERSION);

1;
__END__

=head1 NAME

Ushuffle - shuffle sequences while preserving their k-let counts

=head1 VERSION

This document describes Ushuffle version 1.00.

=head1 SYNOPSIS

  use Ushuffle qw(shuffle set_seed);

  # one shuffle that keeps all dinucleotide counts of the input
  my $shuffled = shuffle('ACACGUAGAUGGGGA', 2);

  # many shuffles of the same sequence
  my $shuffler = Ushuffle::Shuffler->new('ACACGUAGAUGGGGA', 2);
  print $shuffler->shuffle, "\n" for 1 .. 100;

  # reproducible output
  set_seed(42);

=head1 DESCRIPTION

This module is a Perl interface to the uShuffle library by Minghui Jiang,
James Anderson, Joel Gillespie and Martin Mayne. uShuffle produces random
permutations of a sequence that have exactly the same k-let counts as the
original, for any let size k: the same single-letter composition for k=1,
the same dinucleotide counts for k=2, and so on. Such shuffles are the usual
null model when assessing the significance of a feature of a biological
sequence, such as the folding energy of an RNA or the number of occurrences
of a motif.

A shuffle for let size k has these properties:

=over 4

=item *

It contains every k-let exactly as often as the original sequence does. As a
consequence the same holds for all shorter lets, down to the single letters.

=item *

Its first k-1 and its last k-1 letters are those of the original sequence,
in the same place.

=item *

Every sequence that meets these conditions is equally likely to be returned.
The original sequence is one of them.

=back

The sequences need not be biological. Any string of bytes other than NUL can
be shuffled, and upper and lower case letters are different letters.

=head1 FUNCTIONS

Both functions can be imported on request; nothing is exported by default.

=head2 shuffle

  my $shuffled = shuffle($sequence, $k);

Returns a new shuffle of C<$sequence> for let size C<$k>. The sequence itself
is not modified.

C<$k> must be a positive integer. With C<$k> of 1 the result is a plain
permutation of the letters. If C<$k> is at least the length of the sequence,
the sequence is its own only shuffle, and a copy is returned.

The function dies if the sequence is undefined, contains a NUL byte or a
character above 255, or if C<$k> is not a positive integer.

=head2 set_seed

  set_seed($seed);

Seeds the random number generator with the unsigned integer C<$seed>. The
same seed followed by the same calls gives the same shuffles. See L</RANDOM
NUMBERS>. Note that the C library treats a seed of 0 as 1.

=head1 SHUFFLER OBJECTS

  my $shuffler = Ushuffle::Shuffler->new($sequence, $k);
  my $shuffled = $shuffler->shuffle;

A shuffler prepares a sequence once and then hands out any number of
shuffles, which is about twice as fast as calling C<shuffle> every time. The
class is loaded together with this module and is described in
L<Ushuffle::Shuffler>.

=head1 RANDOM NUMBERS

The library draws its random numbers from the C library's C<random()>. The
generator is seeded from the clock and the process id when the module is
loaded, so separate runs give different shuffles; call C<set_seed> for
reproducible ones. After C<set_seed($seed)>, a new shuffler returns the same
shuffles that the library's C<ushuffle> command-line program prints for the
same sequence, let size and C<-seed $seed> on the same system.

The generator's state is shared by the whole process: a child created with
C<fork> continues with the same state as its parent and should call
C<set_seed> itself, and other code calling C<random()> or C<srandom()>
affects the shuffles. Perl's own C<rand> and C<srand> use a different
generator and neither affect the shuffles nor are affected by them.

=head1 THREADS

The module can be used from several threads at once. The library's prepared
sequence and the random number generator exist once per process, so the
module lets only one thread at a time into the library. Threads therefore do
not make shuffling faster; use separate processes for that.

A shuffler belongs to the thread that created it. In a thread started later,
a variable holding a shuffler of the parent thread no longer holds an object,
and the thread has to create its own.

All threads draw from the same generator. C<set_seed> gives reproducible
shuffles only while a single thread is shuffling.

Load the module before starting threads, as C<use Ushuffle> does. Loading it
for the first time from several threads at the same moment is not supported.

=head1 LIMITATIONS

Sequences are treated as strings of bytes. A sequence must not contain NUL
bytes or characters above 255, and must be shorter than 2**31 bytes. The
result is always a byte string.

The library holds the prepared form of one sequence at a time. Using several
shufflers side by side is safe, but each switch from one shuffler to another,
and each call of the C<shuffle> function in between, makes the next
C<< $shuffler->shuffle >> prepare its sequence again. This holds across
threads as well.

Preparing a sequence temporarily takes roughly 30 bytes of memory per
letter.

If it runs out of memory, the library terminates the process.

=head1 INCOMPATIBLE CHANGES

Version 0.01 exposed the C functions directly as
C<Ushuffle::shuffle($s, $t, $l, $k)>, C<Ushuffle::shuffle1($s, $l, $k)> and
C<Ushuffle::shuffle2($t)>, which wrote the result into a preallocated C<$t>.
Those have been replaced by the interface described above.

=head1 DEPENDENCIES

Perl 5.10.1 or later. Building the module needs a C compiler and a C library
that provides C<random()> and C<srandom()>; Windows is therefore not
supported. No Perl modules outside the core are required.

=head1 SEE ALSO

L<Ushuffle::Shuffler>

Minghui Jiang, James Anderson, Joel Gillespie and Martin Mayne. uShuffle: a
useful tool for shuffling biological sequences while preserving the k-let
counts. BMC Bioinformatics 9:192, 2008.
L<https://doi.org/10.1186/1471-2105-9-192>

The bundled library source is taken unmodified from the master branch of
L<https://github.com/s-will/ushuffle> (commit 2c4b8f3).

=head1 SUPPORT

Please report bugs and send suggestions through the issue tracker at
L<https://github.com/mtw/ushuffle-perl/issues>.

=head1 AUTHOR

Michael T. Wolfinger E<lt>michael@wolfinger.euE<gt>

The uShuffle library was written by Minghui Jiang, James Anderson, Joel
Gillespie and Martin Mayne.

=head1 COPYRIGHT AND LICENSE

The Perl interface is Copyright (c) 2026 Michael T. Wolfinger. It is
distributed under the same terms as the uShuffle library in F<ushufflelib/>,
which are:

  Copyright (c) 2007
    Minghui Jiang, James Anderson, Joel Gillespie, and Martin Mayne.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
  3. The names of its contributors may not be used to endorse or promote
       products derived from this software without specific prior written
       permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
