#!/usr/bin/env perl

# Smoke test for the meta_data charts, without a browser.
#
# "Headless" here means no DOM and no JavaScript engine: the CI container is a
# bare perl, so there is nothing to run the inline D3 scripts.  What a browser
# needs before it can draw is checked instead - every one of the five charts
# must render its own SVG and carry at least one data point.  A chart that
# loses its id, or whose data comes back empty, is a blank frame in the browser
# and fails here.
#
# The other way a chart ends up blank - two snippets both declaring
# "const data", so the second script throws - is covered by the script-scoping
# checks in t/function.t.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use JSON::MaybeXS qw(decode_json);
use POSIX qw(strftime);
use Readonly;

use lib File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

use Web::VWF::Display;
use Web::VWF::Display::meta_data;

Readonly my @CHARTS => qw(browser_chart status_chart rate_chart latency_chart slow_chart);

# Every empty panel must say why it is empty; a blank one looks like a bug
Readonly my %EMPTY_TEXT => (
	browser_chart => 'No requests logged yet',
	status_chart => 'No requests logged yet',
	rate_chart => 'No requests logged in the last 24 hours',
	latency_chart => 'No request durations logged in the last 24 hours',
	slow_chart => 'Not enough data yet to rank endpoints',
);

# ---------------------------------------------------------------------------
# Stand-ins for the objects the page is handed at run time
# ---------------------------------------------------------------------------

package Local::Info {
	sub new { return bless { domain_name => 'example.com' }, shift }
	sub domain_name { return $_[0]->{'domain_name'} }
}

# The access log, in the shape Web::VWF::Data::vwf_log gives the page
package Local::VwfLog {
	sub new { my ($class, @rows) = @_; return bless { rows => \@rows }, $class }
	sub selectall_array { return @{$_[0]->{'rows'}} }
	sub type {
		my ($self, $args) = @_;
		return grep { ref($_) eq 'HASH' && ($_->{'type'} // '') eq $args->{'type'} } @{$self->{'rows'}};
	}
	sub http_code {
		return map { $_->{'http_code'} } grep { ref($_) eq 'HASH' } @{$_[0]->{'rows'}};
	}
}

package main;

# How many marks the browser will draw from a chart snippet: one per slice or
# bar, and one per point for a multi-series line chart.  Returns 0 when the
# snippet has no data at all, which is the failure this test is looking for.
sub chart_points
{
	my ($html) = @_;

	my ($json) = $html =~ /(?:const|var|let)\s+(?:data|series)\s*=\s*(\[.*?\]);/s;
	return 0 unless defined($json);

	my $data = decode_json($json);
	my $points = 0;
	foreach my $item (@{$data}) {
		if(ref($item) eq 'HASH' && ref($item->{'data'}) eq 'ARRAY') {
			$points += scalar(@{$item->{'data'}});
		} else {
			$points++;
		}
	}

	return $points;
}

# The first headless browser we can find, or undef.  CI names the one it
# installed in CHROME_BIN; anywhere without a browser the DOM test skips.
sub find_browser
{
	my @names = grep { defined($_) && length($_) } ($ENV{'CHROME_BIN'}, qw(chromium chromium-browser google-chrome google-chrome-stable));

	foreach my $name (@names) {
		return $name if($name =~ m{/} && -x $name);

		foreach my $dir (File::Spec->path()) {
			my $path = File::Spec->catfile($dir, $name);
			return $path if -x $path;
		}
	}

	return;
}

# What the browser calls itself, for the log.  CI pins one chromium and one
# D3, and the log should name the pair that actually drew the charts rather
# than the pair the workflow meant to install.
sub browser_version
{
	my ($browser) = @_;

	open(my $fh, '-|', $browser, '--version') or return;
	my $line = <$fh>;
	close($fh);
	return unless defined($line);
	$line =~ s/\s+\z//;

	return $line;
}

# How many drawing marks a browser put inside one chart's SVG.  Legends live
# outside the SVG and axis labels are text, so both count only when a snippet
# puts them there; a chart that never ran has no marks at all.
#
# The DOM is cut out by id and counted with a regex rather than parsed as a
# tree: HTML::TreeBuilder and other HTML4 parsers treat the contents of an
# <svg> element as CDATA, so they throw away exactly the marks being counted.
sub svg_marks
{
	my ($dom, $id) = @_;

	my ($svg) = $dom =~ /<svg\b[^>]*\bid="\Q$id\E"[^>]*>(.*?)<\/svg>/s;
	return 0 unless defined($svg);

	my $count = () = $svg =~ /<(?:path|rect|circle|line|polyline|text)\b/g;

	return $count;
}

my $stamp = sub { strftime('%Y-%m-%d %H:%M:%S', localtime(CORE::time() - shift)) };
my $when = $stamp->(60);

# Enough traffic for all five charts: every browser type, several status
# codes, two templates with enough samples to rank, and plausible durations
my @rows = (
	(map { { time => $when, ip => "10.0.0.$_", type => 'web', http_code => 200, duration_ms => 120, template => '/srv/templates/web/index.tmpl' } } 1 .. 6),
	(map { { time => $when, ip => "10.0.1.$_", type => 'mobile', http_code => 404, duration_ms => 400, template => '/srv/templates/web/meta_data.tmpl' } } 1 .. 6),
	{ time => $when, ip => '10.0.2.1', type => 'search', http_code => 500, duration_ms => 50 },
	{ time => $when, ip => '10.0.2.2', type => 'robot', http_code => 200, duration_ms => 50 },
	{ time => $when, ip => '10.0.2.3', type => 'ai', http_code => 200, duration_ms => 50 },
);

my $display = bless {
	info => Local::Info->new(),
	config => {},
}, 'Web::VWF::Display::meta_data';

my %chart;
mock 'Web::VWF::Display::html' => sub { %chart = %{$_[1]}; return 'page' };
mock 'Web::VWF::Display::meta_data::get_server_metrics' => sub {
	return { cpu_count => 1, cpu_type => 'test', disk_used_pct => 1, memory_used_pct => 1 };
};

is($display->html(vwf_log => Local::VwfLog->new(@rows)), 'page', 'meta_data renders');

my $page = join("\n", map { $chart{$_} // '' } @CHARTS);

foreach my $id (@CHARTS) {
	my $html = $chart{$id};
	ok(defined($html) && length($html), "$id rendered");

	# An SVG with the right id is what the snippet's script selects; without
	# it d3.select() finds nothing and the chart is blank
	my $svgs = () = $page =~ /<svg id="\Q$id\E"/g;
	is($svgs, 1, "exactly one $id svg");

	my $points = chart_points($html // '');
	cmp_ok($points, '>=', 1, "$id has data to draw ($points point(s))");
	unlike($html // '', qr/No requests logged|No request durations|Not enough data yet/, "$id is a real chart, not a placeholder");
}

# An empty log must give a clear placeholder, never a frame with nothing in it
%chart = ();
$display->html(vwf_log => Local::VwfLog->new());
foreach my $id (@CHARTS) {
	my $html = $chart{$id} // '';
	unlike($html, qr/<svg/, "$id is not rendered as a blank frame");
	like($html, qr/\Q$EMPTY_TEXT{$id}\E/, "$id explains why it is empty");
}

# The example's template is the one a site copies, so these tests render that
# file - not a stand-in - with the chart variables and inspect the finished
# HTML.
sub render_example_template
{
	my ($vars) = @_;

	require Template;

	my $templates = File::Spec->catdir($Bin, File::Spec->updir(), 'example', 'templates');
	my $template = File::Spec->catfile('web', 'Web', 'VWF', 'Display', 'meta_data.tmpl');
	die "Missing example template $template\n" unless -f File::Spec->catfile($templates, $template);

	my $tt = Template->new({ INCLUDE_PATH => $templates }) or die Template->error();
	my $output = '';
	$tt->process($template, $vars, \$output) or die $tt->error();

	return $output;
}

# The placeholders above only help if the real template prints them.  The log
# here has nothing that can draw a chart, so every panel must explain itself.
subtest 'the example template prints every placeholder' => sub {
	my $output = render_example_template(\%chart);

	like($output, qr{<script src="https://d3js\.org/d3\.v7\.min\.js"></script>}, 'loads D3 once');
	unlike($output, qr/<svg/, 'no chart is drawn from nothing');
	foreach my $id (@CHARTS) {
		like($output, qr/\Q$EMPTY_TEXT{$id}\E/, "$id placeholder reaches the page");
	}
};

# Two requests fill four panels, but ranking an endpoint needs five samples:
# the slow panel alone must still explain itself, and the other four must not.
subtest 'a two-request log draws four charts and one placeholder' => sub {
	my @sparse = (
		{ time => $when, ip => '10.0.3.1', type => 'web', http_code => 200, duration_ms => 120, template => '/srv/templates/web/index.tmpl' },
		{ time => $when, ip => '10.0.3.2', type => 'web', http_code => 200, duration_ms => 340, template => '/srv/templates/web/index.tmpl' },
	);

	%chart = ();
	$display->html(vwf_log => Local::VwfLog->new(@sparse));
	my $output = render_example_template(\%chart);

	foreach my $id (qw(browser_chart status_chart rate_chart latency_chart)) {
		like($output, qr/<svg id="\Q$id\E"/, "$id draws in the page");
		unlike($output, qr/\Q$EMPTY_TEXT{$id}\E/, "$id is not a placeholder");
	}
	like($output, qr/\Q$EMPTY_TEXT{'slow_chart'}\E/, 'the slow panel explains why it is empty');
	unlike($output, qr/<svg id="slow_chart"/, 'the slow panel has no empty frame');
};

# Five samples from one endpoint is the smallest log that can rank it.  Every
# panel must draw from that, including the slow one, and none may fall back to
# a placeholder.
subtest 'a five-request log from one endpoint fills every panel' => sub {
	my @same = map {
		{
			time => $when, ip => "10.0.4.$_", type => 'web', http_code => 200,
			duration_ms => 100 + ($_ * 50), template => '/srv/templates/web/index.tmpl',
		}
	} 1 .. 5;

	%chart = ();
	$display->html(vwf_log => Local::VwfLog->new(@same));
	my $output = render_example_template(\%chart);

	like($output, qr{<script src="https://d3js\.org/d3\.v7\.min\.js"></script>}, 'loads D3 once');
	foreach my $id (@CHARTS) {
		like($output, qr/<svg id="\Q$id\E"/, "$id draws in the page");
		unlike($output, qr/\Q$EMPTY_TEXT{$id}\E/, "$id is not a placeholder");
	}
	my $svgs = () = $output =~ /<svg id="/g;
	is($svgs, scalar(@CHARTS), 'every panel has one chart');
};

# The inspector itself is checked on a hand-built DOM, so it cannot silently
# report marks for everything
subtest 'the DOM inspector' => sub {
	my $sample = '<html><body><svg id="browser_chart"><g><path d="M0 0h1"></path><text>1</text></g></svg><svg id="status_chart"></svg></body></html>';
	is(svg_marks($sample, 'browser_chart'), 2, 'counts paths and text inside the chart');
	is(svg_marks($sample, 'status_chart'), 0, 'an empty SVG has no marks');
	is(svg_marks($sample, 'missing_chart'), 0, 'a missing SVG has no marks');
};

# The data checks above stop a chart from being blank because it has nothing
# to draw; only a browser proves D3 turns the data into marks.  CI installs
# chromium for this, so it runs there and skips on a machine without one.
subtest 'the five charts draw in a real browser' => sub {
	my $browser = find_browser();
	if(!$browser) {
		plan skip_all => 'No headless browser found (CI installs chromium for this test)';
	}
	my $chromium = browser_version($browser);

	# Render the chart area again, then wrap it in the same page shape as the
	# template: D3 once in the head, one snippet after another in the body
	%chart = ();
	$display->html(vwf_log => Local::VwfLog->new(@rows));
	my $d3 = $ENV{'D3_URL'} // 'https://d3js.org/d3.v7.min.js';
	my $page = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>charts</title>'
		. '<script src="' . $d3 . '"></script>'
		# Record what the page loaded, not what we asked for: a CDN or a
		# changed file serving another version must show up in the log.
		. '<script>document.documentElement.setAttribute("data-d3-version", (typeof d3 === "undefined" ? "not loaded" : d3.version));</script>'
		. '</head><body>'
		. join("\n", map { $chart{$_} // '' } @CHARTS)
		. '</body></html>';

	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'charts.html');
	open(my $out, '>', $file) or die "Can't write $file: $!";
	print $out $page;
	close($out);

	# --dump-dom returns the page once it has loaded, so the blocking D3 script
	# and every snippet have run.  The virtual time budget lets a slow script
	# answer first; there is no sandbox because CI runs this as root in a
	# container, and no GPU because there is nothing to draw to.
	open(my $fh, '-|', $browser,
		'--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
		"--user-data-dir=$dir", '--hide-scrollbars', '--virtual-time-budget=15000',
		'--dump-dom', "file://$file");
	my $dom = do { local $/; <$fh> };
	my $status = close($fh);

	my ($d3_version) = ($dom // '') =~ /data-d3-version="([^"]*)"/;
	diag('Chromium: ' . ($chromium // 'unknown') . '; D3: ' . ($d3_version // 'unknown'));

	ok(length($dom // ''), 'the browser returned a DOM');
	diag("browser exited with status $status") unless $status;
	foreach my $id (@CHARTS) {
		cmp_ok(svg_marks($dom // '', $id), '>=', 1, "$id drew marks");
	}
};

restore_all();

done_testing();
