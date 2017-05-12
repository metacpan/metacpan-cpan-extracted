# this example is to verify that the example on the man page works.
# It's been modified mostly to print statistics and timing
# information.
#
# The problem is just prepending a string with "Ex-", which is mostly
# serving here as an example of the benefits of the lazy deep copying
# approach: it generally can only help performance.
#
# For example, with threads => 1 and a 1.5MB, 46k line input:
#   loading input: 134ms
#   processing: 330ms
#   Workers processed: 0% :  ()
#   Master processed: 100% : 46332
#   Total processed: 46332
#
# Setting threads => 2 on a 2-way system shows:
#
#   loading input: 134ms
#   processing: 274ms
#   Workers processed: 32.8% : 15203 (1 15203)
#   Master processed: 67.2% : 31129
#   Total processed: 46332
#
# Of course you could argue that the operation is not finished at the
# instrumented points; the lazy deep copying out of the results is
# still yet to happen.  But still, the total wallclock time showed a
# slight decrease with threads => 2, from ~0.74s to ~0.67s - showing
# that even though we started two interpreters, and even though the
# program is completely trivial, some performance improvement can be
# seen at the end of it.  Of course the main thread here was able to
# process data at approximately 2-3 times the speed of the workers.
# For this problem, simply copying the data in and out is the major
# overhead, and so it helps that the master thread can proceed at
# "full steam" for avoiding the overheads exceeding the return.

# 8-way/EC2 results (on EC2):

# # 1-way
# loading input: 132ms
# processing: 371ms
# Workers processed: 0.0% :  ()
# Master processed: 100.0% : 71063
# Total processed: 71063
# # 2-way
# loading input: 126ms
# processing: 270ms
# Workers processed: 37.5% : 26649 (1 26649)
# Master processed: 62.5% : 44414
# Total processed: 71063
# # 4-way
# loading input: 125ms
# processing: 191ms
# Workers processed: 59.0% : 41916 (1 15544 3 12909 2 13463)
# Master processed: 41.0% : 29147
# Total processed: 71063
# # 8-way
# loading input: 125ms
# processing: 263ms
# Workers processed: 62.5% : 44412 (6 6348 1 6384 4 6246 3 4546 7 7216 2 7010 5 6662)
# Master processed: 37.5% : 26651
# Total processed: 71063

# with LD_PRELOAD=libtbbmalloc_proxy.so.2:
#
# # 1-way
# loading input: 163ms
# processing: 370ms
# Workers processed: 0.0% :  ()
# Master processed: 100.0% : 71063
# Total processed: 71063
# # 2-way
# loading input: 162ms
# processing: 263ms
# Workers processed: 37.5% : 26649 (1 26649)
# Master processed: 62.5% : 44414
# Total processed: 71063
# # 4-way
# loading input: 167ms
# processing: 155ms
# Workers processed: 60.4% : 42913 (1 14158 3 14208 2 14547)
# Master processed: 39.6% : 28150
# Total processed: 71063
# # 8-way
# loading input: 168ms
# processing: 125ms
# Workers processed: 69.8% : 49637 (6 2342 1 7531 4 8632 3 9087 7 3886 2 8363 5 9796)
# Master processed: 30.2% : 21426
# Total processed: 71063

 package Incredible::Threadable;
 use threads::tbb;

 sub new {
     my $class = shift;
     # make containers which are efficient and thread-safe
     tie my @input, "threads::tbb::concurrent::array";
     push @input, @_;  # coming soon: @input = @_
     tie my @output, "threads::tbb::concurrent::array";
     bless { input => \@input,
             output => \@output, }, $class;
 }

 sub threads { our $threads; shift if UNIVERSAL::isa($_[0],__PACKAGE__);
	$threads = $_[0] if @_;
	return $threads };
 sub chunk_size { our $chunk_size; shift if UNIVERSAL::isa($_[0],__PACKAGE__);
	$chunk_size = $_[0] if @_;
	return $chunk_size };
 sub parallel_transmogrify {
     my $self = shift;

     # Initialize the TBB library, and set a specification of required
     # modules and/or library paths for worker threads.
     my $tbb = threads::tbb->new(
	     (threads() ? ("threads" => threads()) : ()),
	     requires => [ $0 ] );

     my $min = 0;
     my $max = scalar(@{ $self->{input} });
     my $range = threads::tbb::blocked_int->new( $min, $max, chunk_size()||1 );

     my $body = $tbb->for_int_method( $self, "my_callback" );

     $body->parallel_for( $range );
 }

 sub my_callback {
     my $self = shift;
     my $int_range = shift;

     for my $idx ($int_range->begin .. $int_range->end-1) {
         my $item = $self->{input}->[$idx];

         my $transmuted = $item->transmogrify($threads::tbb::worker);

         $self->{output}->[$idx] = $transmuted;
     }
 }

 sub results { @{ $_[0]->{output} } }

 package Item;
 sub transmogrify {
     my $self = shift;
     my $worker = shift;
     "Ex-$self->{id} ".($worker?"worker $worker":"master");;
 }

 package main;
 use feature 'say';

 use Scriptalicious;
 use List::Util qw(sum);
 getopt(
	"threads|t=i" => \(my $num_threads),
	"chunk-size|chunk|c=i" => \(my $chunk_size),
	);
 Incredible::Threadable->threads($num_threads);
 Incredible::Threadable->chunk_size($chunk_size);

 unless ($threads::tbb::worker) {  # single script uses can use this
     start_timer();
     my $parallel_transmogrificator = Incredible::Threadable->new(
         map { chomp; bless { id => $_ }, "Item" } <>
     );
     say "loading input: ".show_delta;
     $parallel_transmogrificator->parallel_transmogrify();
     say "processing: ".show_delta;
     my $x = $parallel_transmogrificator;
     my %workers;
     my ($master, $total);
     for ($parallel_transmogrificator->results) {
	     $total++;
	     if ( m{worker (\d+)$} ) {
		     $workers{$1}++;
	     }
	     else {
		     $master++;
	     }
     }
     my $workers_sum = sum values %workers;
     say "Workers processed: ".sprintf("%.1f", ($workers_sum/$total*100))."% : $workers_sum (@{[%workers]})";
     say "Master processed: ".sprintf("%.1f", ($master/$total*100))."% : $master";
     say "Total processed: $total";
 }
