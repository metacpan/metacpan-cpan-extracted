#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2020 -- leonerd@leonerd.org.uk

package Test::MemoryGrowth;

use strict;
use warnings;
use base qw( Test::Builder::Module );

our $VERSION = '0.04';

our @EXPORT = qw(
   no_growth
);

use constant HAVE_DEVEL_GLADIATOR => defined eval { require Devel::Gladiator };

use constant HAVE_DEVEL_MAT_DUMPER => defined eval { require Devel::MAT::Dumper };

=head1 NAME

C<Test::MemoryGrowth> - assert that code does not cause growth in memory usage

=head1 SYNOPSIS

   use Test::More;
   use Test::MemoryGrowth;

   use Some::Class;

   no_growth {
      my $obj = Some::Class->new;
   } 'Constructing Some::Class does not grow memory';

   my $obj = Some::Class->new;
   no_growth {
      $obj->do_thing;
   } 'Some::Class->do_thing does not grow memory';


   #### This test will fail ####
   my @list;
   no_growth {
      push @list, "Hello world";
   } 'pushing to an array does not grow memory';

   done_testing;

=head1 DESCRIPTION

This module provides a function to check that a given block of code does not
result in the process consuming extra memory once it has finished. Despite the
name of this module it does not, in the strictest sense of the word, test for a
memory leak: that term is specifically applied to cases where memory has been
allocated but all record of it has been lost, so it cannot possibly be
reclaimed. While the method employed by this module can detect such bugs, it
can also detect cases where memory is still referenced and reachable, but the
usage has grown more than would be expected or necessary.

The block of code will be run a large number of times (by default 10,000), and
the difference in memory usage by the process before and after is compared. If
the memory usage has now increased by more than one byte per call, then the
test fails.

In order to give the code a chance to load initial resources it needs, it will
be run a few times first (by default 10); giving it a chance to load files,
AUTOLOADs, caches, or any other information that it requires. Any extra memory
usage here will not count against it.

This simple method is not a guaranteed indicator of the absence of memory
resource bugs from a piece of code; it has the possibility to fail in both a
false-negative and a false-positive way.

=over 4

=item False Negative

It is possible that a piece of code causes memory usage growth that this
module does not detect. Because it only detects memory growth of at least one
byte per call, it cannot detect cases of linear memory growth at lower rates
than this. Most memory usage growth comes either from Perl-level or C-level
bugs where memory objects are created at every call and not reclaimed again.
(These are either genuine memory leaks, or needless allocations of objects
that are stored somewhere and never reclaimed). It is unlikely such a bug
would result in a growth rate smaller than one byte per call.

A second failure case comes from the fact that memory usage is taken from the
Operating System's measure of the process's Virtual Memory size, so as to be
able to detect memory usage growth in C libraries or XS-level wrapping code,
as well as Perl functions. Because Perl does not aggressively return unused
memory to the Operating System, it is possible that a piece of code could use
un-allocated but un-reclaimed memory to grow into; resulting in an increase in
its requirements despite not requesting extra memory from the Operating
System.

=item False Positive

It is possible that the test will claim that a function grows in memory, when
the behaviour is in fact perfectly normal for the code in question. For
example, the code could simply be some function whose behaviour is required to
store extra state; for example, adding a new item into a list. In this case it
is in fact expected that the memory usage of the process will increase.

=back

By careful use of this test module, false indications can be minimised. By
splitting tests across many test scripts, each one can be started in a new
process state, where most of the memory assigned from the Operating System is
in use by Perl, so anything extra that the code requires will have to request
more. This should reduce the false negative indications.

By keeping in mind that the module simply measures the change in allocated
memory size, false positives can be minimised, by not attempting to assert
that certain pieces of code do not grow in memory, when in fact it would be
expected that they do.

=head2 Devel::Gladiator Integration

I<Since version 0.04.>

If L<Devel::Gladiator> is installed, this test module will use it as a second
potential source of detecting memory growth. A walk of the Perl memory heap is
taken before running the code, in order to count the number of every kind of
object present. This is then compared to a second count taken afterwards. Any
object types that have increased by at least one per call are reported.

For example, the output might contain the following extra lines of diagnostic
output:

   # Growths in arena object counts:
   #   ARRAY 1735 -> 11735 (1.00 per call)
   #   HASH 459 -> 10459 (1.00 per call)
   #   REF 1387 -> 21387 (2.00 per call)
   #   REF-ARRAY 163 -> 10163 (1.00 per call)
   #   REF-HASH 66 -> 10066 (1.00 per call)
   #   WithContainerSlots 10 -> 10010 (1.00 per call)

=head2 Devel::MAT Integration

If L<Devel::MAT> is installed, this test module will use it to dump the state
of the memory after a failure. It will create a F<.pmat> file named the same
as the unit test, but with the trailing F<.t> suffix replaced with
F<-TEST.pmat> where C<TEST> is the number of the test that failed (in case
there was more than one). It will then run the code under test one more time,
before writing another file whose name is suffixed with F<-TEST-after.pmat>.
This pair of files may be useful for differential analysis.

=cut

=head1 FUNCTIONS

=cut

sub get_heapcounts
{
   return {} unless HAVE_DEVEL_GLADIATOR;

   my $counts = Devel::Gladiator::arena_ref_counts();

   return $counts;
}

sub get_memusage
{
   # TODO: This implementation sucks piggie. Write a proper one
   open( my $statush, "<", "/proc/self/status" ) or die "Cannot open status - $!";

   m/^VmSize:\s+([0-9]+) kB/ and return $1 for <$statush>;

   die "Unable to determine VmSize\n";
}

=head2 no_growth

   no_growth { CODE } %opts, $name

Assert that the code block does not consume extra memory.

Takes the following named arguments:

=over 8

=item calls => INT

The number of times to call the code during growth testing.

=item burn_in => INT

The number of times to call the code initially, before watching for memory
usage.

=back

=cut

sub no_growth(&@)
{
   my $code = shift;
   my $name; $name = pop if @_ % 2;
   my %args = @_;

   my $tb = __PACKAGE__->builder;

   my $burn_in = $args{burn_in} || 10;
   my $calls   = $args{calls}   || 10_000;

   my $i = 0;
   $code->() while $i++ < $burn_in;

   # Fetch usage twice; first to allocate memory for it to run in so the
   #   second can account for it.
   my $before_usage = get_memusage;
   my $before_counts = get_heapcounts;

   # Fetch a second copy before code, to preallocate memory for it now
   my $after_counts = get_heapcounts;
   $before_counts = $after_counts;

   my $after_usage = get_memusage;
   $before_usage = $after_usage;

   $i = 0;
   $code->() while $i++ < $calls;

   undef $after_usage;
   undef $after_counts;

   $after_usage = get_memusage;
   $after_counts = get_heapcounts;

   # Collect up various test results
   my $ok = 1;

   my $increase = ( $after_usage - $before_usage ) * 1024; # in bytes
   # Even if we increased in memory usage, it's OK as long as we didn't gain
   # more than one byte per call
   $ok = 0 if $increase >= $calls;

   my $growth_counts;
   foreach my $type ( keys %$after_counts ) {
      my $growth = $after_counts->{$type} - $before_counts->{$type};
      next unless $growth >= $calls;

      $growth_counts->{$type} = sprintf "%d -> %d (%.2f per call)",
         $before_counts->{$type}, $after_counts->{$type}, $growth / $calls;
   }
   $ok = 0 if $growth_counts;

   $tb->ok( $ok, $name );
   return $ok if $ok;

   if( $increase >= $calls ) {
      $tb->diag( sprintf "Lost %d bytes of memory over %d calls, average of %.2f per call",
         $increase, $calls, $increase / $calls );
   }

   if( $growth_counts ) {
      $tb->diag( "Growths in arena object counts:\n" .
         join( "\n", map { "  $_ $growth_counts->{$_}" } sort keys %$growth_counts ) );
   }

   if( HAVE_DEVEL_MAT_DUMPER ) {
      my $file = $0;
      my $num = $tb->current_test;

      # Trim the .t off first then append -$num.pmat, in case $0 wasn't a .t file
      $file =~ s/\.(?:t|pm|pl)$//;

      my $beforefile = "$file-$num.pmat";
      my $afterfile  = "$file-$num-after.pmat";

      # Try to arrange the memory in as similar as state as possible by running
      # one more iteration now before we take the "before" snapshot
      $code->();

      $tb->diag( "Writing heap dump to $beforefile" );
      Devel::MAT::Dumper::dump( $beforefile );

      $code->();

      $tb->diag( "Writing heap dump after one more iteration to $afterfile" );
      Devel::MAT::Dumper::dump( $afterfile );
   }

   return $ok;
}

=head1 TODO

=over 8

=item * Don't be Linux Specific

Currently, this module uses a very Linux-specific method of determining
process memory usage (namely, by inspecting F</proc/self/status>). This should
really be fixed to some OS-neutral abstraction. Currently I am unaware of a
simple portable mechanism to query this. Patches very much welcome. :)

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
