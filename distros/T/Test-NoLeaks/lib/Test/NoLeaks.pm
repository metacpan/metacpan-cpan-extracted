package Test::NoLeaks;

use strict;
use warnings;
use POSIX qw/sysconf _SC_PAGESIZE/;
use Test::Builder;
use Test::More;

our $VERSION = '0.06';

use base qw(Exporter);

our @EXPORT    = qw/test_noleaks/;    ## no critic (ProhibitAutomaticExportation)
our @EXPORT_OK = qw/noleaks/;

=head1 NAME

Test::NoLeaks - Memory and file descriptor leak detector

=head1 SYNOPSYS

  use Test::NoLeaks;

  test_noleaks (
      code          => sub{
        # code that might leak
      },
      track_memory  => 1,
      track_fds     => 1,
      passes        => 2,
      warmup_passes => 1,
      tolerate_hits => 0,
  );

  Sample output:
  # pass 1, leaked: 225280 bytes 0 file descriptors
  # pass 36, leaked: 135168 bytes 0 file descriptors
  # pass 52, leaked: 319488 bytes 0 file descriptors
  # pass 84, leaked: 135168 bytes 0 file descriptors
  # pass 98, leaked: 155648 bytes 0 file descriptors
  not ok 1214 - Leaked 970752 bytes (5 hits) 0 file descriptors

  test_noleaks (
      code          => sub { ... },
      track_memory  => 1,
      passes        => 2,
  );

  # old-school way
  use Test::More;
  use Test::NoLeaks qw/noleaks/;
  ok noleaks(
      code          => sub { ... },
      track_memory  => ...,
      track_fds     => ...,
      passes        => ...,
      warmup_passes => ...,
    ), "non-leaked code description";

=head1 DESCRIPTION

It is hard to track memory leaks. There are a lot of perl modules (e.g.
L<Test::LeakTrace>), that try to B<detect> and B<point> leaks. Unfortunately,
they do not always work, and they are rather limited because they are not
able to detect leaks in XS-code or external libraries.

Instead of examining perl internals, this module offers a bit naive empirical
approach: let the suspicious code to be launched in infinite loop
some time and watch (via tools like C<top>)if the memory consumption by
perl process increses over time. If it does, while it is expected to
be constant (stabilized), then, surely, there are leaks.

This approach is able only to B<detect> and not able to B<point> them. The
module C<Test::NoLeaks> implements the general idea of the approach, which
might be enough in many cases.

=head1 INTERFACE

=head3 C<< test_noleaks >>

=head3 C<< noleaks >>

The mandatory hash has the following members

=over 2

=item * C<code>

Suspicious for leaks subroutine, that will be executed multiple times.

=item * C<track_memory>

=item * C<track_fds>

Track memory or file descriptor leaks. At leas one of them should be
specified.

In B<Unices>, every socket is file descriptor too, so, C<track_fds>
will be able to track unclosed sockets, i.e. network connections.

=item * C<passes>

How many times C<code> should be executed. If memory leak is too small,
number of passes should be large enough to trigger additional pages
allocation for perl process, and the leak will be detected.

Page size is 4kb on linux, so, if C<code> leaks 4 bytes on every
pass, then C<1024> passes should be specified.

In general, the more passes are specified, the more chance to
detect possible leaks.

It is good idea to initally define C<passes> to some large number,
e.g. C<10_000> to be sure, that the suspicious code leaks, but then
decrease to some smaller number, enough to produce test fail report,
i.e. enough to produces 3-5 memory hits (additional pages allocations).
This will speed up tests execution and will save CO2 atmospheric
emissions a little bit.

Default value is C<100>. Minimal value is C<2>.

=item * C<warmup_passes>

How many times the C<code> should be executed before module starts
tracking resources consumption on executing the C<code> C<passes>
times.

If you have caches, memoizes etc., then C<warmup_passes> is your
friend.

Default value is C<0>.

=item * C<tolerate_hits>

How many passes, which considered leaked, should be ingnored, i.e.
maximal number of possible false leak reports.

Even if your code has no leaks, it might cause perl interpreter
allocate additional memory pages, e.g. due to memory fragmentation.
Those allocations are legal, and should not be treated as leaks.

Use this B<only> when memory leaks are already fixed, but there
are still false leak reports from C<test_leak>. This value expected
to be small enough, i.e. C<1> or C<2>. For additional assurance, please,
increase C<passes> value, if C<tolarate_hits> is non-zero.

Default value is C<0>.

=back

=head1 MEMORY LEAKS TESTING TECHNIQUES

C<Test::NoLeaks> can be used to test web applications for memory leaks.

Let's consider you have the following suspicious code

  sub might_leak {
    my $t = Test::Mojo->new('MyApp');
    $t->post_ok('/search.json' => form => {q => 'Perl'})
        ->status_is(200);
    ...;
  }

  test_noleaks (
      code          => \&might_leak,
      track_memory  => 1,
      track_fds     => 1,
      passes        => 1000,
  );

The C<might_leak> subroutine isn't optimal for leak detection, because it
mixes infrastructure-related code (application) with request code. Let's
consider, that there is a leak: every request creates some data and puts
it into application, but forgets to do clean up. As soon as the application
is re-created on every pass, the leaked data might be destroyed together
with the application, and leak might remain undetected.

So, the code under test should look much more production like, i.e.

  my $t = Test::Mojo->new('MyApp');
  ok($t);
  sub might_leak {
    $t->post_ok('/search.json' => form => {q => 'Perl'})
        ->status_is(200);
    ...;
  }

That way web-application is created only once, and leaks will be tracked
on request-related code.

Anyway, C<might_leak> still wrong, because it unintentionally leaks due to
use of direct or indirect L<Test::More> functions, like C<ok> or
C<post_ok>. They should not be used; if you still need to assert, that
C<might_leak> works propertly, you can use C<BAIL_OUT> subroutine,
to cancel any further testing, e.g.

  sub might_leak {
    my $got = some_function_might_leak;
    my $expected = "some_value";
    BAIL_OUT('some_function_might_leak does not work propertly!')
      unless $got eq $expected;
  }



Please, B<do not> use C<test_noleaks> more then once per test file. Consider
the following example:

  # (A)
  test_noleaks(
    code => &does_not_leak_but_consumes_large_amount_of_memory,
    ...,
  )

  # (B)
  test_noleaks(
    code => &leaks_but_consumes_small_amount_of_memory,
    ...
  )

In A-case OS already allocated large amount of memory for Perl interpreter.
In case-B perl might just re-use them, without allocating new ones, and
this will be false negative, i.e. memory leak might B<not> be reported.


=head1 LIMITATIONS

=over 2

=item * Currently it works propertly only on B<Linux>

Patches or pull requests to support other OSes are welcome.

=item * The module will not work propertly in B<fork>ed child

It seems a little bit strange to use C<test_noleaks> or
C<noleaks> in forked child, but if you really need that, please,
send PR.

=back

=head1 SEE ALSO

L<Test::MemoryGrowth>

=cut

my $PAGE_SIZE;

BEGIN {
    no strict "subs";    ## no critic (ProhibitNoStrict ProhibitProlongedStrictureOverride)

    $PAGE_SIZE = sysconf(_SC_PAGESIZE)
        or die("page size cannot be determined, Test::NoLeaks cannot be used");

    open(my $statm, '<', '/proc/self/statm')    ## no critic (RequireBriefOpen)
        or die("couldn't access /proc/self/status : $!");
    *_platform_mem_size = sub {
        my $line = <$statm>;
        seek($statm, 0, 0);
        my ($pages) = (split / /, $line)[0];
        return $pages * $PAGE_SIZE;
    };

    my $fd_dir = '/proc/self/fd';
    opendir(my $dh, $fd_dir)
        or die "can't opendir $fd_dir: $!";
    *_platform_fds = sub {
        my $open_fd_count = () = readdir($dh);
        rewinddir($dh);
        return $open_fd_count;
    };
}

sub _noleaks {
    my %args = @_;

    # check arguments
    my $code = $args{code};
    die("code argument (CODEREF) isn't provided")
        if (!$code || !(ref($code) eq 'CODE'));

    my $track_memory = $args{'track_memory'};
    my $track_fds    = $args{'track_fds'};
    die("don't know what to track (i.e. no 'track_memory' nor 'track_fds' are specified)")
        if (!$track_memory && !$track_fds);

    my $passes = $args{passes} || 100;
    die("passes count too small (should be at least 2)")
        if $passes < 2;

    my $warmup_passes = $args{warmup_passes} || 0;
    die("warmup_passes count too small (should be non-negative)")
        if $passes < 0;

    # warm-up phase
    # a) warm up code
    $code->() for (1 .. $warmup_passes);

    # b) warm-up package itself, as it might cause additional memory (re) allocations
    # (ignore results)
    _platform_mem_size if $track_memory;
    _platform_fds      if $track_fds;
    my @leaked_at = map { [0, 0] } (1 .. $passes);    # index: pass, value array[$mem_leak, $fds_leak]

    # pre-allocate all variables, including those, which are used in cycle only
    my ($total_mem_leak, $total_fds_leak, $memory_hits) = (0, 0, 0);
    my ($mem_t0, $fds_t0, $mem_t1, $fds_t1) = (0, 0, 0, 0);

    # execution phase
    for my $pass (0 .. $passes - 1) {
        $mem_t0 = _platform_mem_size if $track_memory;
        $fds_t0 = _platform_fds      if $track_fds;
        $code->();
        $mem_t1 = _platform_mem_size if $track_memory;
        $fds_t1 = _platform_fds      if $track_fds;

        my $leaked_mem = $mem_t1 - $mem_t0;
        $leaked_mem = 0 if ($leaked_mem < 0);

        my $leaked_fds = $fds_t1 - $fds_t0;
        $leaked_fds = 0 if ($leaked_fds < 0);

        $leaked_at[$pass]->[0] = $leaked_mem;
        $leaked_at[$pass]->[1] = $leaked_fds;
        $total_mem_leak += $leaked_mem;
        $total_fds_leak += $leaked_fds;

        $memory_hits++ if ($leaked_mem > 0);
    }

    return ($total_mem_leak, $total_fds_leak, $memory_hits, \@leaked_at);
}

sub noleaks(%) {    ## no critic (ProhibitSubroutinePrototypes)
    my %args = @_;

    my ($mem, $fds, $mem_hits) = _noleaks(%args);

    my $tolerate_hits = $args{tolerate_hits} || 0;
    my $track_memory  = $args{'track_memory'};
    my $track_fds     = $args{'track_fds'};

    my $has_fd_leaks = $track_fds && ($fds > 0);
    my $has_mem_leaks = $track_memory && ($mem > 0) && ($mem_hits > $tolerate_hits);
    return !($has_fd_leaks || $has_mem_leaks);
}

sub test_noleaks(%) {    ## no critic (ProhibitSubroutinePrototypes)
    my %args = @_;
    my ($mem, $fds, $mem_hits, $details) = _noleaks(%args);

    my $tolerate_hits = $args{tolerate_hits} || 0;
    my $track_memory  = $args{'track_memory'};
    my $track_fds     = $args{'track_fds'};

    my $has_fd_leaks = $track_fds && ($fds > 0);
    my $has_mem_leaks = $track_memory && ($mem > 0) && ($mem_hits > $tolerate_hits);
    my $has_leaks = $has_fd_leaks || $has_mem_leaks;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if (!$has_leaks) {
        pass("no leaks have been found");
    } else {
        my $summary = "Leaked " . ($track_memory ? "$mem bytes ($mem_hits hits) " : "") . ($track_fds ? "$fds file descriptors" : "");

        my @lines;
        for my $pass (1 .. @$details) {
            my $v = $details->[$pass - 1];
            my ($mem, $fds) = @$v;
            if ($mem || $fds) {
                my $line = "pass $pass, leaked: " . ($track_memory ? $mem . " bytes " : "") . ($track_fds ? $fds . " file descriptors" : "");
                push @lines, $line;
            }
        }
        my $report = join("\n", @lines);

        note($report);
        fail("$summary");
    }
    return;
}

=head1 SOURCE CODE

L<GitHub|https://github.com/binary-com/perl-Test-NoLeaks>

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/binary-com/perl-Test-NoLeaks/issues>.

=cut

1;
