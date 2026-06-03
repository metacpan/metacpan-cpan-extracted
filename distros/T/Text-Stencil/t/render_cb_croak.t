use strict;
use warnings;
use Test::More;
use Text::Stencil;

# A row callback that dies mid-render previously left the reused render buffer
# (t->render_buf) dangling, because a realloc during the render moved the local
# buffer without updating the persistent pointer -- a use-after-free / double-
# free on the next render or at DESTROY (ASAN-confirmed). The buffer is now
# detached for the render's duration, so a croak can no longer corrupt it.

my $s = Text::Stencil->new(row => ('x' x 300) . "{v}\n");

# 1. callback dies after the output buffer has grown well past its initial size
my $i = 0;
my $ok = eval {
    $s->render_cb(sub { $i++; die "boom\n" if $i > 60; return { v => $i }; });
    1;
};
ok !$ok, 'render_cb propagated the dying callback';

# 2. a subsequent render must work correctly (no corruption of the reused buffer)
$i = 0;
my $out = $s->render_cb(sub { $i++; return $i <= 3 ? { v => "r$i" } : undef; });
ok defined($out) && length($out) > 0, 'render_cb works after a croaked render';
like $out, qr/r1.*r2.*r3/s, '...and produced the expected rows in order';

# 3. plain render is fine afterwards too
is $s->render([{ v => 'A' }]), ('x' x 300) . "A\n", 'render works after the croak';

# 4. the filehandle form has its own write buffer; a dying callback must
#    propagate the error and not leak that buffer (valgrind-confirmed; the
#    leak itself is not observable from Perl).
{
    open my $fh, '>', \my $sink;
    my $ok = eval { $s->render_cb(sub { die "boom\n" }, $fh); 1 };
    ok !$ok, 'render_cb(fh) propagates a dying callback';

    open my $fh2, '>', \my $out2;
    my $n = 0;
    $s->render_cb(sub { $n++; $n <= 2 ? { v => "fh$n" } : undef }, $fh2);
    like $out2, qr/fh1.*fh2/s, 'render_cb(fh) works after a dying-callback render';
}

done_testing;
