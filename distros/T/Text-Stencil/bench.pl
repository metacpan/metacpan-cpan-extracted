#!/usr/bin/env perl
use v5.20;
use Benchmark qw'cmpthese';
use Text::Stencil;

my @arows = sort { $a->[1] cmp $b->[1] } (
    [11, '<script>alert("This should not be displayed in a browser alert box.");</script>'],
    [4, 'A bad random number generator: 1, 1, 1, 1, 1, 4.33e+67, 1, 1, 1'],
    [5, 'A computer program does what you tell it to do, not what you want it to do.'],
    [2, "A computer scientist is someone who fixes things that aren\x{27}t broken."],
    [8, "A list is only as strong as its weakest link. \x{2014} Donald Knuth"],
    [0, 'Additional fortune added at request time.'],
    [3, 'After enough decimal places, nobody gives a damn.'],
    [7, 'Any program that runs right is obsolete.'],
    [10, 'Computers make very fast, very accurate mistakes.'],
    [6, "Emacs is a nice operating system, but I prefer UNIX. \x{2014} Tom Christaensen"],
    [9, 'Feature: A bug with seniority.'],
    [1, 'fortune: No such file or directory'],
    [12, "\x{30D5}\x{30EC}\x{30FC}\x{30E0}\x{30EF}\x{30FC}\x{30AF}\x{306E}\x{30D9}\x{30F3}\x{30C1}\x{30DE}\x{30FC}\x{30AF}"],
);
my @hrows = map { { id => $_->[0], message => $_->[1] } } @arows;

# --- 1. HTML table (13 rows, html escape, vs Text::Xslate) ---
say "=== 1. HTML table (13 rows, html escape) ===";

my $xs_arr = Text::Stencil->new(
    header => '<!DOCTYPE html><html><head><title>Fortunes</title></head><body><table><tr><th>id</th><th>message</th></tr>',
    row    => '<tr><td>{0:int}</td><td>{1:html}</td></tr>',
    footer => '</table></body></html>',
);
my $xs_hash = Text::Stencil->new(
    header => '<!DOCTYPE html><html><head><title>Fortunes</title></head><body><table><tr><th>id</th><th>message</th></tr>',
    row    => '<tr><td>{id:int}</td><td>{message:html}</td></tr>',
    footer => '</table></body></html>',
);
my $xs_chain = Text::Stencil->new(
    header => '<!DOCTYPE html><html><head><title>Fortunes</title></head><body><table><tr><th>id</th><th>message</th></tr>',
    row    => '<tr><td>{0:int}</td><td>{1:trim|html}</td></tr>',
    footer => '</table></body></html>',
);

my %bench1 = (
    'render arrayref'  => sub { $xs_arr->render(\@arows) },
    'render hashref'   => sub { $xs_hash->render(\@hrows) },
    'render chained'   => sub { $xs_chain->render(\@arows) },
    'render_one'       => sub { $xs_arr->render_one($arows[0]) },
);
if (eval { require Text::Xslate; 1 }) {
    my $xslate = Text::Xslate->new(path => {
        'fortune.tx' => <<'HTML' =~ s/(?<=[\r\n])\s+//gr
<!DOCTYPE html>
<html>
<head><title>Fortunes</title></head>
<body>
<table>
<tr><th>id</th><th>message</th></tr>
: for $rows -> $r {
<tr><td><: $r.0 :></td><td><: $r.1 :></td></tr>
: }
</table>
</body>
</html>
HTML
    });
    $xslate->load_file('fortune.tx');
    $bench1{'Text::Xslate'} = sub { $xslate->render('fortune.tx', { rows => \@arows }) };
}
cmpthese(-3, \%bench1);

# --- 2. Transform throughput (1000 rows, single transform) ---
say "\n=== 2. Transform throughput (1000 rows) ===";

my @numrows = map { [$_, "value $_", $_ * 1.5, "<b>$_</b>"] } 1..1000;
my @hnum    = map { { id => $_->[0], name => $_->[1], val => $_->[2], tag => $_->[3] } } @numrows;

my %xf_bench;
my @xf_tests = (
    ['raw',       '{0:raw}'],
    ['int',       '{0:int}'],
    ['int_comma', '{0:int_comma}'],
    ['float:2',   '{2:float:2}'],
    ['html',      '{3:html}'],
    ['url',       '{1:url}'],
    ['json',      '{1:json}'],
    ['trim|html', '{1:trim|html}'],
    ['uc',        '{1:uc}'],
    ['trunc:20',  '{1:trunc:20}'],
    ['default:x', '{1:default:x}'],
);
for my $t (@xf_tests) {
    my $s = Text::Stencil->new(row => $t->[1], separator => "\n");
    $xf_bench{$t->[0]} = sub { $s->render(\@numrows) };
}
cmpthese(-3, \%xf_bench);

# --- 3. Chaining depth (1000 rows) ---
say "\n=== 3. Chain depth (1000 rows) ===";

my @strrows = map { ["  <b>Hello World $_</b>  "] } 1..1000;
my %chain_bench;
my @chains = (
    ['1 (html)',          '{0:html}'],
    ['2 (trim|html)',     '{0:trim|html}'],
    ['3 (trim|uc|html)',  '{0:trim|uc|html}'],
    ['4 (trim|uc|trunc:20|html)', '{0:trim|uc|trunc:20|html}'],
);
for my $c (@chains) {
    my $s = Text::Stencil->new(row => $c->[1], separator => "\n");
    $chain_bench{$c->[0]} = sub { $s->render(\@strrows) };
}
cmpthese(-3, \%chain_bench);

# --- 4. Row count scaling ---
say "\n=== 4. Row count scaling ===";

my $simple = Text::Stencil->new(row => '{0:int},{1:html}', separator => "\n");
for my $n (10, 100, 1000, 10000) {
    my @rows = map { [$_, "<v$_>"] } 1..$n;
    my $iters = int(500000 / $n) || 1;
    my $t = Benchmark::timeit(1, sub { $simple->render(\@rows) for 1..$iters });
    my $elapsed = $t->[1] + $t->[2];
    printf "  %5d rows x%d: %.3fs (%.1fM rows/s)\n", $n, $iters, $elapsed, $n * $iters / ($elapsed || 0.001) / 1e6;
}

# --- 5. render vs render_one (single row, no overhead) ---
say "\n=== 5. render vs render_one (single row) ===";

my $one = Text::Stencil->new(row => '{0:int},{1:html}');
my $row = [42, '<hello>'];
cmpthese(-3, {
    'render([$row])'  => sub { $one->render([$row]) },
    'render_one($row)' => sub { $one->render_one($row) },
});

# --- 6. render_cb vs render ---
say "\n=== 6. render_cb vs render (1000 rows) ===";

my $cb_tpl = Text::Stencil->new(row => '{0:int},{1:html}', separator => "\n");
my @cbrows = map { [$_, "<v$_>"] } 1..1000;
cmpthese(-3, {
    'render'    => sub { $cb_tpl->render(\@cbrows) },
    'render_cb' => sub { my $i = 0; $cb_tpl->render_cb(sub { $i <= $#cbrows ? $cbrows[$i++] : undef }) },
});

# --- 7. skip_if overhead ---
say "\n=== 7. skip_if overhead (1000 rows, skip ~half) ===";

my @skiprows = map { [$_, $_ % 2 ? 'yes' : ''] } 1..1000;
my $no_skip = Text::Stencil->new(row => '{0:int}', separator => ',');
my $with_skip = Text::Stencil->new(row => '{0:int}', separator => ',', skip_if => 1);
cmpthese(-3, {
    'no skip'   => sub { $no_skip->render(\@skiprows) },
    'skip_if'   => sub { $with_skip->render(\@skiprows) },
});
