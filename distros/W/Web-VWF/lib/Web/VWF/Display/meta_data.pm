package Web::VWF::Display::meta_data;

# Display the meta-data page - the internal status of the server and VWF system

# TODO:  Add breakdown by browser

use strict;
use warnings;

use version; our $VERSION = version->declare('0.002.0');

use parent 'Web::VWF::Display';

use HTML::D3;

# Filesys::Df refuses to install on Windows, so Makefile.PL does not require it
# there.  A server without it just has no disk figure: df() then answers as if
# the call had failed, which get_server_metrics() already copes with.
BEGIN {
	if(!eval { require Filesys::Df; Filesys::Df->import(); 1 }) {
		no strict 'refs';	## no critic (ProhibitNoStrict)
		*{__PACKAGE__ . '::df'} = sub { return };
	}
}

use List::Util qw(max sum0);
use Scalar::Util qw(looks_like_number);
use POSIX qw(strftime);
use Readonly;
use System::Info;
use Sys::Uptime;
use Sys::MemInfo;
use Time::Piece;
use Time::Seconds;

# The browser types counted in the breakdown chart.
# Keep this in step with VWF::Display::_types() and CGI::Info::browser_type().
Readonly my @BROWSER_TYPES => ('web', 'mobile', 'search', 'robot', 'ai');

# A request cannot have taken longer than the window these charts cover, so a
# duration beyond one day is not a measurement but a stale row written by the
# old timer bug (about 1.8e12 ms).  One such row would otherwise dominate the
# average, the 95th percentile and the slow-endpoint list for a whole day.
Readonly my $MAX_DURATION_MS => ONE_DAY * 1000;

# What each panel says when it has nothing to draw.  An empty frame looks like
# a broken chart, so every chart area explains itself instead - and the page
# has one place, not two, where that wording lives.
Readonly my $NO_REQUESTS => '<p>No requests logged yet.</p>';
Readonly my $NO_RECENT_REQUESTS => '<p>No requests logged in the last 24 hours.</p>';
Readonly my $NO_DURATIONS => '<p>No request durations logged in the last 24 hours.</p>';
Readonly my $NOT_ENOUGH_SAMPLES => '<p>Not enough data yet to rank endpoints.</p>';

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $vwf_log = $args{'vwf_log'} or die "Missing 'vwf_log' handle";
	my $domain_name = $self->{'info'}->domain_name();

	# --- Browser breakdown: one slice per browser type ---
	my @browser;
	foreach my $type (@BROWSER_TYPES) {
		my @entries = $vwf_log->type({ domain_name => $domain_name, type => $type });
		push @browser, [$type, scalar(@entries)];
		if($self->{'logger'}) {
			$self->{'logger'}->debug("$type = " . scalar(@entries));
		}
	}

	# --- Server metrics using CPAN modules ---
	my $server_metrics = $self->get_server_metrics();

	# --- Traffic metrics from vwf_log ---
	my $traffic_metrics = $self->get_traffic_metrics($vwf_log, $domain_name);

	# --- HTTP status breakdown: one slice per status code ---
	my %status_count;
	foreach my $http_code ($vwf_log->http_code({ domain_name => $domain_name })) {
		$status_count{$http_code}++;
	}
	my @status = map { [$_, $status_count{$_}] } sort keys %status_count;

	my $rate_24h = $self->get_request_rate_24h($vwf_log, $domain_name);
	my $latency_24h = $self->get_latency_24h($vwf_log, $domain_name);
	my $slow = $self->get_slow_endpoints_24h($vwf_log, $domain_name);

	# The charts are built here and the template only places them.  HTML::D3
	# escapes the labels it writes into the page, so nothing from the access log
	# is trusted as markup.  A chart with no data is a placeholder, never an
	# empty frame.
	my $charts = HTML::D3->new(width => 800, height => 400);
	my $browser_chart = (grep { $_->[1] } @browser)
		? _scoped_snippet($charts->render_pie_chart_snippet({ data => \@browser, id => 'browser_chart', donut => 1, sort_slices => 'value' }))
		: $NO_REQUESTS;
	my $status_chart = @status
		? _scoped_snippet($charts->render_pie_chart_snippet({ data => \@status, id => 'status_chart', donut => 1, sort_slices => 'label' }))
		: $NO_REQUESTS;
	# B::Lint reads an array dereference in a conditional as an implicit scalar
	# context and fails CI over it; scalar() is the count that was wanted anyway.
	my $rate_chart = scalar(@{$rate_24h->{'total'}})
		? _scoped_snippet($charts->render_multi_series_line_chart_snippet({
			series_data => _series(['Requests', $rate_24h->{'total'}], ['Errors', $rate_24h->{'errors'}]),
			id => 'rate_chart', x_label => 'Hour', y_label => 'Requests',
		}))
		: $NO_RECENT_REQUESTS;
	my $latency_chart = scalar(@{$latency_24h->{'avg'}})
		? _scoped_snippet($charts->render_multi_series_line_chart_snippet({
			series_data => _series(['Average', $latency_24h->{'avg'}], ['P95', $latency_24h->{'p95'}]),
			id => 'latency_chart', x_label => 'Hour', y_label => 'Milliseconds',
		}))
		: $NO_DURATIONS;
	my $slow_chart = scalar(@{$slow})
		? _scoped_snippet($charts->render_bar_chart_snippet({
			data => $slow, id => 'slow_chart', orientation => 'horizontal',
			sort_bars => 'value', show_values => 1, value_label => 'ms',
		}))
		# Too few requests to rank anything is normal, not an error
		: $NOT_ENOUGH_SAMPLES;

	return $self->SUPER::html({
		server => $server_metrics,
		traffic => $traffic_metrics,
		browser_chart => $browser_chart,
		status_chart => $status_chart,
		rate_chart => $rate_chart,
		latency_chart => $latency_chart,
		slow_chart => $slow_chart,
	});
}

# HTML::D3's multi-series charts take {name, data => [{label, value}, ...]};
# the counting methods above return [label, value] pairs.
sub _series
{
	my @series = @_;

	return [ map {
		my ($name, $points) = @{$_};
		{
			name => $name,
			data => [ map { { label => $_->[0], value => $_->[1] } } @{$points} ],
		}
	} @series ];
}

# The pie snippet writes its script at the top level of the page, while the
# line and bar snippets wrap theirs in a function.  Two pies on one page would
# therefore both declare "const data": the second script dies with
# "Identifier 'data' has already been declared" and leaves an empty frame.
# Giving every snippet its own function makes them independent; the snippets
# that already wrap themselves are simply wrapped twice, which is harmless.
sub _scoped_snippet
{
	my ($result) = @_;

	my $html = $result->{'html'};
	$html =~ s{(<script\b[^>]*>)(.*?)(</script>)}{$1 . "(function () {\n" . $2 . "\n})();\n" . $3}gse;

	return $html;
}

sub get_server_metrics {
	my $metrics = {};

	# CPU info
	my $si = System::Info->new;
	$metrics->{cpu_count} = $si->ncpu // 0;
	$metrics->{cpu_type} = $si->cpu_type // '';

	# Disk usage
	if(my $df = df('/')) {
		# prefer 'per' if present
		# A filesystem reporting no blocks has no meaningful percentage
		$metrics->{disk_used_pct} = $df->{per}
			// ($df->{blocks} ? int(100 * ($df->{blocks} - $df->{bfree}) / $df->{blocks}) : undef);
	} else {
		$metrics->{disk_used_pct} = undef;
	}

	# Memory usage (via Sys::MemInfo)
	my $total_mem = Sys::MemInfo::totalmem();
	my $free_mem = Sys::MemInfo::freemem();
	if (defined $total_mem && defined $free_mem && $total_mem > 0) {
		$metrics->{memory_used_pct} = int(100 * ($total_mem - $free_mem) / $total_mem);
	} else {
		$metrics->{memory_used_pct} = 0;
	}

	return $metrics;
}

# ------------------------------
# Traffic metrics from vwf_log
# ------------------------------

sub get_traffic_metrics {
	my (undef, $vwf_log, $domain_name) = @_;
	my $metrics = {};

	# Current time and one hour ago (local time)
	my $now = time();
	my $hour_ago = $now - ONE_HOUR + _utc_offset();

	# Get all entries as array of hashrefs
	my @entries = $vwf_log->selectall_array({ domain_name => $domain_name });

	# Filter entries from last hour
	my @recent;
	foreach my $entry (@entries) {
		next unless ref $entry eq 'HASH' && $entry->{time};

		my $tp;
		eval { $tp = Time::Piece->strptime($entry->{time}, '%Y-%m-%d %H:%M:%S') };
		next unless $tp;

		my $epoch = $tp->epoch;
		push @recent, $entry if $epoch > $hour_ago;
	}

	# Requests per hour
	$metrics->{requests_per_hour} = scalar @recent;

	# Active users (unique IPs)
	my %ips;
	foreach my $entry (@recent) {
		my $ip = $entry->{ip} // 'unknown';
		$ips{$ip} = 1;
	}
	$metrics->{active_users} = scalar keys %ips;

	# Top 5 endpoints
	# my %urls;
	# foreach my $entry (@recent) {
		# my $url = $entry->{url} // '/';
		# $urls{$url}++;
	# }
	# my @top_urls = sort { $urls{$b} <=> $urls{$a} } keys %urls;
	# $metrics->{top_urls} = [ @top_urls[0..(4 > $#top_urls ? $#top_urls : 4)] ];

	# Error count (HTTP code >= 400)
	my $errors = grep { ($_->{http_code} // 0) >= 400 } @recent;
	$metrics->{errors_last_hour} = $errors;

	return $metrics;
}

sub get_request_rate_24h {
	my (undef, $vwf_log, $domain_name) = @_;

	my $now = time();
	my $start = $now - ONE_DAY + _utc_offset();

	my %buckets;

	foreach my $entry ($vwf_log->selectall_array({ domain_name => $domain_name })) {
		next unless ref $entry eq 'HASH' && $entry->{time};

		my $tp;
		eval { $tp = Time::Piece->strptime($entry->{time}, '%Y-%m-%d %H:%M:%S') };
		next unless $tp;

		my $epoch = $tp->epoch;
		next if $epoch < $start;

		# Bucket by hour
		my $bucket = $tp->strftime('%H:00');

		$buckets{$bucket}{total}++;
		if(($entry->{http_code} // 0) >= 400) {
			$buckets{$bucket}{errors}++;
		}
	}

	# One [label, value] pair per hour, ready for HTML::D3
	my (@total, @errors, @error_pct);

	foreach my $hour (sort keys %buckets) {
		my $total = $buckets{$hour}{total} // 0;
		my $errors = $buckets{$hour}{errors} // 0;

		push @total, [$hour, $total];
		push @errors, [$hour, $errors];
		push @error_pct, [$hour, $total ? 0 + sprintf('%.2f', ($errors / $total) * 100) : 0];
	}

	return {
		total => \@total,
		errors => \@errors,
		error_pct => \@error_pct,
	};
}

sub get_latency_24h {
	my (undef, $vwf_log, $domain_name) = @_;

	my $start = time() - ONE_DAY + _utc_offset();

	my %buckets;

	foreach my $entry ($vwf_log->selectall_array({ domain_name => $domain_name })) {
		next unless ref $entry eq 'HASH';
		next unless $entry->{time};
		# The log is data, not code: only numbers are durations
		next unless defined($entry->{duration_ms}) && looks_like_number($entry->{duration_ms});
		next if $entry->{duration_ms} > $MAX_DURATION_MS;

		my $tp;
		eval { $tp = Time::Piece->strptime($entry->{time}, '%Y-%m-%d %H:%M:%S') };
		next unless $tp;

		my $epoch = $tp->epoch;
		next if $epoch < $start;

		my $hour = $tp->strftime('%H:00');

		push @{ $buckets{$hour} }, $entry->{duration_ms};
	}

	my (@avg, @p95);

	foreach my $hour (sort keys %buckets) {
		my @vals = sort { $a <=> $b } @{ $buckets{$hour} };
		next unless @vals;

		my $count = @vals;
		# Never eval() log contents: a crafted duration_ms would run as Perl
		my $avg = int(sum0(@vals) / $count);

		my $p95_index = int(0.95 * ($count - 1));
		my $p95 = $vals[$p95_index];

		push @avg, [$hour, $avg];
		push @p95, [$hour, $p95];
	}

	return {
		avg => \@avg,
		p95 => \@p95,
	};
}

sub get_slow_endpoints_24h {
	my (undef, $vwf_log, $domain_name) = @_;

	my $start = time() - ONE_DAY + _utc_offset();

	# Step 1: fetch rows filtered only by equality
	my @rows = $vwf_log->selectall_array({ domain_name => $domain_name });

	# Step 2: collect durations per template
	my %durations;

	foreach my $row (@rows) {
		next unless ref($row) eq 'HASH';
		next unless defined $row->{time};
		next unless defined($row->{duration_ms}) && looks_like_number($row->{duration_ms});
		next if $row->{duration_ms} <= 0;
		next if $row->{duration_ms} > $MAX_DURATION_MS;

		my $tp;
		eval { $tp = Time::Piece->strptime($row->{time}, '%Y-%m-%d %H:%M:%S') };
		next unless $tp;
		next if $tp->epoch < $start;

		my $tpl = $row->{template} // '';
		push @{ $durations{$tpl} }, $row->{duration_ms};
	}

	# Step 3: compute p95
	my @ranked;

	foreach my $tpl (keys %durations) {
		my @vals = sort { $a <=> $b } @{ $durations{$tpl} };
		my $count = @vals;
		next if $count < 5;

		my $p95_index = int(0.95 * ($count - 1));
		my $p95 = $vals[$p95_index];

		push @ranked, {
			template => $tpl,
			p95_ms => $p95,
		};
	}

	# Step 4: sort + top 10
	@ranked = sort { $b->{p95_ms} <=> $a->{p95_ms} } @ranked;
	splice(@ranked, 10) if @ranked > 10;

	# Step 5: [label, value] pairs.  The labels stay as the log wrote them;
	# HTML::D3 escapes them when it writes the chart.
	my @dp;
	foreach my $row (@ranked) {
		my $label = $row->{template};
		$label =~ s/^.+\/templates\///;

		push @dp, [$label, $row->{p95_ms}];
	}

	return \@dp;
}

sub _utc_offset
{
	my $local_time = time();
	my @local = localtime($local_time);
	my @gmt = gmtime($local_time);

	# Convert both to seconds since midnight
	my $local_seconds = $local[2] * 3600 + $local[1] * 60 + $local[0];
	my $gmt_seconds = $gmt[2] * 3600 + $gmt[1] * 60 + $gmt[0];

	# Account for day boundary crossing
	my $day_diff = $local[3] - $gmt[3];
	if ($day_diff > 1) { $day_diff = -1; }	# wrapped backwards
	if ($day_diff < -1) { $day_diff = 1; }	# wrapped forwards

	return $local_seconds - $gmt_seconds + ($day_diff * 86400);
}

1;
