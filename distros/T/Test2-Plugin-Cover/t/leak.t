use Test2::V0;
use Test2::Plugin::Cover ();
use Fcntl qw/O_RDONLY/;

# Regression test: add_entry() used to leak one SV on nearly every sub call
# once the (file, sub, from) entry already existed (~70 bytes/call), which
# ballooned sub-call heavy tests into multi-GB processes.

skip_all "requires a linux-style /proc/self/statm" unless -r "/proc/self/statm";

my $pagesize = eval { require POSIX; POSIX::sysconf(POSIX::_SC_PAGESIZE()) } || 4096;

sub rss_kb {
    open(my $fh, '<', '/proc/self/statm') or die "Could not read statm: $!";
    my @stats = split /\s+/, scalar <$fh>;
    return $stats[1] * $pagesize / 1024;
}

Test2::Plugin::Cover->enable;

sub foo { 42 }

# Warmup, allocates the report entries and buckets.
foo() for 1 .. 10_000;
Test2::Plugin::Cover->set_from('leak_check');
foo() for 1 .. 10_000;

my $before = rss_kb();

foo() for 1 .. 500_000;
for (1 .. 100_000) { open(my $fh, '<', 'no_such_file.json') }
for (1 .. 100_000) { sysopen(my $fh, 'no_such_file.json', O_RDONLY) }

my $growth = rss_kb() - $before;

# The old leak grew ~50,000KB in this loop. Allow generous slack for
# allocator noise.
ok($growth < 8192, "no per-call memory leak in the op hooks")
    or diag("RSS grew ${growth}KB over 700k hooked calls");

Test2::Plugin::Cover->reset_coverage;

done_testing;
