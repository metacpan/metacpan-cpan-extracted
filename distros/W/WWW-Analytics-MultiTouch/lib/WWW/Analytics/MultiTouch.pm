package WWW::Analytics::MultiTouch;

use warnings;
use strict;
use Net::Google::Analytics;
use Net::Google::Analytics::OAuth2;
use DateTime;
use Data::Dumper;
use Params::Validate qw(:all);
use List::Util qw/sum max/;
use List::MoreUtils qw/part/;
use Config::General qw/ParseConfig SaveConfig/;
use Hash::Merge qw/merge/;
use Path::Class qw/file/;

use WWW::Analytics::MultiTouch::Tabular;

our $VERSION = '0.36';

my $client_id = "452786331228.apps.googleusercontent.com";
my $client_secret = "ZNSff9Rzw0WS0I4M-F_8NUL7";

my $default_header_colour = { bold => 1,
			      color => 'white',
			      bg_color => 'gray',
			      right => 'white',
};
my $default_column_formats = [ 
    { bg_color => '#D0D0D0', },
    { bg_color => '#E8E8E8', },
];

my $default_title_format = { bold => 1 };

my $default_row__heading = { bold => 1 };

my %formatting_params = (
    title_format => { type => HASHREF,
		      default => $default_title_format,
    },
    column_heading_format => { type => HASHREF, 
			       default => $default_header_colour,
    },
    column_formats => { type => ARRAYREF, 
			default => $default_column_formats,
    },
    row_heading_format => { type => HASHREF, 
			    default => $default_row__heading,
    },
    heading_map => { type => HASHREF,
		     default => {},
    },
    header_layout => 0,
    footer_layout => 0,
    strict_integer_values => 0,
    );

sub new {
    my $class = shift;

    my %params = validate(@_, { 
        auth_token => 0,
        refresh_token => 0,
        auth_file => 0,
        id => 1,
        event_category => { default => 'multitouch' },
        fieldsep => { default => '!' },
        recsep => { default => '*' },
        patsep => { default => '-' },
        debug => { default => 0 },
        bugfix1 => { default => 0 },
        channel_map => { type => HASHREF,
                         default => {} },
        date_format => { default => '%d %b %Y' },
        time_format => { default => '%Y-%m-%d %H:%M:%S' },
        ga_timezone => { default => 'UTC' },
        report_timezone => { default => 'UTC' },
        revenue_scale => { default => 1 },
			  });
    my $self = bless \%params, ref $class || $class;

    return $self;
}

sub get_data {
    my $self = shift;
    my %params = validate(@_, { start_date => 0,
				end_date => 0,
			  });

    unless (exists $self->{analytics}) {
        $self->{oauth} = Net::Google::Analytics::OAuth2->new(
            client_id     => $client_id,
            client_secret => $client_secret,
            );
        if (! $self->{refresh_token}) {
            $self->authorise;
        }
	$self->{analytics} = Net::Google::Analytics->new();
    }
    my $token = $self->{oauth}->refresh_access_token($self->{refresh_token});
    $self->{analytics}->token($token);

    my $req = $self->{analytics}->new_request();
    $req->ids("ga:" . $self->{id});
    $req->dimensions('ga:eventCategory,ga:eventAction,ga:eventLabel');
    $req->metrics('ga:totalEvents');
    $req->sort('ga:eventAction');
    $req->filters('ga:eventCategory==' . $self->{event_category});

    my $start_date = _to_date_time($params{start_date}, $self->{report_timezone});
    my $end_date = _to_date_time($params{end_date}, $self->{report_timezone})->add(days => 1);
    my $date = $start_date->clone;
    my %data;
    while (DateTime->compare($date, $end_date) <= 0) {
	my $ymd = $date->ymd('-');
	my $ga_ymd = $date->clone->set_time_zone($self->{ga_timezone})->ymd('-');
	$self->_debug("Processing $ga_ymd\n");
	$req->start_date($ga_ymd);
	$req->end_date($ga_ymd);

        my $res = $self->retrieve_paged($req);
	for my $entry (@{$res->rows}) {
            my @events = $self->split_events($entry->get('event_label'));

            # Keep event if within reporting time range (not GA time range)
            my $t = DateTime->from_epoch(epoch => $events[0][3])->set_time_zone($self->{report_timezone});
            if ($start_date <= $t && $t < $end_date) {
                my ($key, $events) = $self->condition_entry($entry->get('event_action'), \@events);
                $data{$key} = [ $ymd, @$events ] if $key;
            }
	}
	$date->add(days => 1);
    }

    $self->{current_data} = { start_date => $start_date,
			      end_date => $end_date->subtract(days => 1),
			      transactions => \%data,
    };
    $self->_debug(sub { Dumper($self->{current_data}) });
}

sub retrieve_paged {
    my ($self, $req) = @_;

    my $start_index = $req->start_index;
    $start_index = 1 if !defined($start_index);
    my $remaining_items = $req->max_results;
    my $max_items_per_page = 10_000;
    my $res;

    while (!defined($remaining_items) || $remaining_items > 0) {
        my $max_results =
            defined($remaining_items) &&
            $remaining_items < $max_items_per_page ?
            $remaining_items : $max_items_per_page;

        my $page = $self->{analytics}->retrieve($req, $start_index, $max_results);
#        $self->_debug("Page data: " . Dumper($page));
        if (! $page->is_success) {
            die "There was a problem fetching analytics data.  Authorisation errors such as 'Forbidden' can occur if the Analytics ID you have specified is not accessible via the authorised Google account.\n Error reported was: " . $page->message;
        }

        if (!defined($res)) {
            $res = $page;
        }
        else {
            push(@{ $res->rows }, @{ $page->rows });
        }

        my $items_per_page = $page->items_per_page;
        last if $page->total_results == 0 || $items_per_page < $max_results;

        $remaining_items -= $items_per_page if defined($remaining_items);
        $start_index     += $items_per_page;
    }

    $res->items_per_page(scalar(@{ $res->rows }));

    return $res;
}


sub set_data {
    my $self = shift;
    my %params = validate(@_, { start_date => 0,
				end_date => 0,
                                transactions => { required => 1,
                                                  type => HASHREF,
                                },
			  });
    
    my $start_date = _to_date_time($params{start_date}, $self->{report_timezone});
    my $end_date = _to_date_time($params{end_date}, $self->{report_timezone});

    $self->{current_data} = { start_date => $start_date,
			      end_date => $end_date,
			      transactions => $params{transactions},
    };
}

sub condition_entry {
    my ($self, $key, $touches) = @_;

    return ($key, $touches);
}


sub _to_date_time {
    my $date = shift;
    my $tz = shift || 'UTC';

    if ($date) {
	my ($y, $m, $d) = ( $date =~ m/^(\d{4})-?(\d{2})-?(\d{2})/ );
	die "Invalid date format: $date\n" if ! defined $d;
	return DateTime->new(year => $y, month => $m, day => $d, time_zone => $tz);
    }
    return DateTime->now->set_time_zone($tz)->truncate(to => 'day');
}

# Splits event label into array of [ source, medium, subcat, time ]
# or for orders, [ __ORD, TID, revenue, time ]
sub split_events {
    my ($self, $events) = @_;

    return unless $events;
    my $rs = $self->{recsep};
    my $fs = $self->{fieldsep};
    my @events = split(/\Q$rs\E/, $events);
    my @rec = map { [ split(/\Q$fs\E/, $_) ] } @events;

    if ($self->{bugfix1}) {
	for (@rec) {
	    if ($_->[0] eq 'organic' && $_->[1] ne 'organic') {
		my $tmp = $_->[1]; $_->[1] = $_->[0]; $_->[0] = $tmp;
	    }
	}
    }
    return @rec;
}

sub summarise {
    my $self = shift;

    my %params = validate(@_, { window_length =>  { default => 45 },
				single_order_model => 0,
				channel_pattern => { default => join($self->{patsep}, qw/source med subcat/) },
				channel => 0,
				adjustments => { type => HASHREF, default => {} },
			  });
    my $patsubst = $self->_compile_channel_pattern($params{channel_pattern});
    my $dt = $params{window_length} * 24 * 3600;

    my %distr_touches;
    my %even_touches;
    my %all_touches;
    my @trans;
    my @touchlist;
    my %transdist;
    my %transdistoverall;
    my %firstlast;
    my %overlap;
    my %first_touch_channels = map { $_ => 1 } grep { $params{channel}{$_}{requires_first_touch} } keys %{$params{channel}};

    # Each event has category 'multitouch', action TIDtid, label ORDER*TOUCH*TOUCH...
    # Each order is of format __ORD!tid!rev!time
    # Each touch is of format source!medium!subcat!time
    for my $tid (keys %{$self->{current_data}->{transactions}}) {
	my $rec = $self->{current_data}->{transactions}->{$tid};
	my $order = $rec->[1];
	if (! ($order->[0] eq '__ORD' 
	       && 'TID' . $order->[1] eq $tid 
	       && $order->[3] =~ m/^\d+$/)) {
	    $self->_debug("Bad record for TID $tid: no __ORD. " . Dumper($rec));
	    next;
	}
	my $rev = $self->_currency_conversion($order->[2]);

	# Set window start based on browser timestamps
	my $window_start = $order->[3] - $dt;

	# work out adjustment factors, if any
	my $trans_adj = $params{adjustments}{$rec->[0]}{transactions} || 1;
	my $rev_adj = $params{adjustments}{$rec->[0]}{revenue} || $trans_adj;

	# Iterate through list of touches and summarise in %touches and @touchlist
	my %touches;
	push(@touchlist, []);
	my $first_touch = 1;
	my %seen_first_touch;
	for my $entry (@$rec[2 .. @$rec - 1]) {
	    if (@$entry != 4) {
		$self->_debug("Bad record for TID $tid: invalid entry. " . Dumper($entry));
		next;
	    }
	    last if $entry->[3] < $window_start;
	    if ($entry->[0] =~ m/__ORD/) {
		last if $params{single_order_model};
		unshift(@{$touchlist[-1]}, [ "ORDER($entry->[1])", $entry->[-1] ]);
		next;
	    }
	    if (my $channel = $self->_map_channel(join($self->{patsep}, map { $entry->[$_] || '(none)' } @$patsubst ))) {
		if ($first_touch) {
		    $first_touch = 0;
		    $seen_first_touch{$channel}++;
		}

		unless ($first_touch_channels{$channel} && !$seen_first_touch{$channel}) {
		    $touches{$channel}{count} += $trans_adj;
		    $touches{$channel}{transactions} = $trans_adj;
		    $touches{$channel}{revenue} = $rev * $rev_adj;
		    unshift(@{$touchlist[-1]}, [ $channel, $entry->[-1] ]);
		}
	    }
	}

	# Summarise first/last touch attribution using @touchlist
	if (@{$touchlist[-1]} > 0) {
	    my $start = 0;
	    my $end = @{$touchlist[-1]} - 1;
	    my $firstchannel = $touchlist[-1][$start][0];
	    my $lastchannel = $touchlist[-1][$end][0];

	    while (defined($firstchannel) && $firstchannel =~ m/^ORDER\(/) {
		$start++;
		if ($start > $end) {
		    $firstchannel = undef;
		    last;
		}
		$firstchannel = $touchlist[-1][$start][0];
	    }
	    while (defined($lastchannel) && $lastchannel =~ m/^ORDER\(/) {
		$end--;
		if ($end <= $start) {
		    $lastchannel = $firstchannel;
		    last;
		}
		$lastchannel = $touchlist[-1][$end][0];
	    }

	    if (defined $firstchannel) {
		$firstlast{'first'}{$firstchannel}{count} += $trans_adj;
		$firstlast{'first'}{$firstchannel}{transactions} += $trans_adj;
		$firstlast{'first'}{$firstchannel}{revenue} += $rev * $rev_adj;
		$firstlast{'last'}{$lastchannel}{count} += $trans_adj;
		$firstlast{'last'}{$lastchannel}{transactions} += $trans_adj;
		$firstlast{'last'}{$lastchannel}{revenue} += $rev * $rev_adj;
	    }

	    # for hybrid, only count once if first/last channel are the same touch
	    if ($end == $start) {
		$lastchannel = undef;
	    }
	    # Attribute to first or last channel or both for hybrid
	    my @channels;
	    push(@channels, $firstchannel) if defined $firstchannel;
	    push(@channels, $lastchannel) if defined $lastchannel; 
	    if (@channels) {
		my $scale = 1/@channels;
		for my $channel (@channels) {
		    $firstlast{hybrid}{$channel}{count} += $trans_adj;
		    $firstlast{hybrid}{$channel}{transactions} += $scale * $trans_adj;
		    $firstlast{hybrid}{$channel}{revenue} += $scale * $rev * $rev_adj;
		}
	    }
	}
	# Finish off touchlist by attaching order details as prefix and last touch
	push(@{$touchlist[-1]}, [ "ORDER($order->[1])", $order->[3] ]);
	unshift(@{$touchlist[-1]}, $order->[1], $order->[2], $order->[3]); # order details prefix

	# Summarise according to various attribution methods using %touches
	if (scalar keys %touches > 0) {
	    for my $sum (qw/count transactions revenue/) {
		$all_touches{$_}{$sum} += $touches{$_}{$sum} for keys %touches;
	    }
	    # normalise
	    my %touches_norm;
	    my $touches_total = sum(map { $touches{$_}{count} } keys %touches);
	    for my $sum (qw/transactions revenue/) {
		$touches_norm{$_}{$sum} = $touches{$_}{$sum} * $touches{$_}{count} / ($touches_total || 1) for keys %touches;
	    }
	    for (keys %touches) {
		my $c = $touches{$_}{count};
		$touches_norm{$_}{count} += $c;
		$distr_touches{$_}{count} += $c;
		$even_touches{$_}{count} += $c;
	    }
	    my $scale = 1 / (scalar keys %touches);
	    for my $sum (qw/transactions revenue/) {
		$distr_touches{$_}{$sum} += $touches_norm{$_}{$sum} for keys %touches;
		$even_touches{$_}{$sum} += $touches{$_}{$sum} * $scale  for keys %touches;
	    }
	    push(@trans, { tid => $order->[1], 
			   timestamp => $order->[3], 
			   date => $rec->[0],
			   rev => $order->[2], 
			   touches => \%touches_norm }); 
	    # distribution of touches by number of conversions
	    $transdist{$touches{$_}{count}}{$_} += $trans_adj for keys %touches;
	    $transdistoverall{sum(map { $touches{$_}{count}} keys %touches)} += $trans_adj;

	    my $key = join('+', sort keys %touches);
	    $overlap{joint}{$key}{transactions} += $trans_adj;
	    $overlap{joint}{$key}{revenue} += $rev * $rev_adj;
	    $overlap{joint}{$key}{touches} += $touches_total;
	    $key = scalar keys %touches;
	    $overlap{count}{$key}{transactions} += $trans_adj;
	    $overlap{count}{$key}{revenue} += $rev * $rev_adj;
	    $overlap{count}{$key}{touches} += $touches_total;

	}
    }
    @touchlist = sort { $a->[0] cmp $b->[0] } @touchlist;
    $self->{summary} = {
	all_touches => \%all_touches,
	distr_touches => \%distr_touches,
	even_touches => \%even_touches,
	trans => \@trans,
	touchlist => \@touchlist,
	transdist => \%transdist,
	transdistoverall => \%transdistoverall,
	firstlast => \%firstlast,
	overlap => \%overlap,
	window_length => $params{window_length},
    };

}

sub _map_channel {
    my ($self, $channel) = @_;
    return $channel if defined $self->{no_mappings};

    if (! exists $self->{compiled_mappings}) {
	if (scalar keys %{$self->{channel_map}} == 0) {
	    $self->{no_mappings} = 1;
	    return $channel;
	}
	$self->{compiled_mappings} = [];
	for my $key (keys %{$self->{channel_map}}) {
	    eval {
	    if ($key =~ m{ ^/(.*)/$ }x) {
		my $re = $1;
		push(@{$self->{compiled_mappings}}, [ qr/$re/, $self->{channel_map}{$key} ]);
	    }
	    };
	    if ($@) {
		warn "Failed to compile channel mapping for $key: $@\n";
	    }
	}
    }

    if (exists $self->{channel_map}{$channel}) {
	return $self->{channel_map}{$channel};
    }

    for my $match (@{$self->{compiled_mappings}}) {
	return $match->[1] if $channel =~ $match->[0];
    }
    return $channel;
}

sub _map_header {
    my ($header, $header_map) = @_;

    return exists $header_map->{$header} ? $header_map->{$header} : $header;
}

sub report {
    my $self = shift;
    my %params = validate(@_, { all_touches_report =>  { default => 1 },
				even_touches_report => { default => 1 },
				distributed_touches_report =>  { default => 1 },
				first_touch_report => { default => 1 },
				last_touch_report => { default => 1 },
				fifty_fifty_report => { default => 1 },
				transactions_report => { default => 1 },
				touchlist_report => { default => 1 },
				transaction_distribution_report => { default => 1 },
				channel_overlap_report => { default => 1 },

				all_touches => 0,
				even_touches => 0,
				distributed_touches => 0,
				first_touch => 0,
				last_touch => 0,
				fifty_fifty => 0,
				transactions => 0,
				touchlist => 0,
				transaction_distribution => 0,
				channel_overlap => 0,

				report_order => { type => ARRAYREF,
						  default => [ qw/all_touches even_touches distributed_touches first_touch last_touch fifty_fifty transactions touchlist transaction_distribution channel_overlap/ ],
				},
				filename => 1,
				'format' => 0,
				title => 0,
				column_heading_format => 0,
				column_formats => 0,
				header_layout => 0,
				footer_layout => 0,
				strict_integer_values => 0,
				heading_map => 0,
                                report_writer => { type => CODEREF,
                                                   optional => 1,
                                },
			  });
    if ($params{filename} =~ m/\.(xls|txt|csv)$/i) {
	$params{'format'} = lc($1);
    }
    elsif (! defined $params{format}) {
	$params{'format'} = 'csv';
    }

    my @reports;
    my @report_options = (qw/title sheetname/, keys %formatting_params);

    for my $report (@{$params{report_order}}) {
	my $method = $report . '_report';
	if (! $self->can($method)) {
	    warn "Report type $report is not valid\n";
	    next;
	}
	next unless $params{$method};
	$self->_debug("Generating report '$report'\n");
	push(@reports, 
	     $self->$method(_opts_subset(_merge_params(\%params, $params{$report}),
					 @report_options))) 
    }
    if ($params{report_writer}) {
        $params{report_writer}->(\@reports, \%params);
    }
    else {
        my $output = WWW::Analytics::MultiTouch::Tabular->new(_opts_subset(\%params,
                                                                           qw/format filename/));
        $output->print(\@reports);
        $output->close();
    }
}

sub _merge_params {
    my $h1 = shift;
    my $h2 = shift;
    return $h1 unless ref($h2) eq 'HASH';

    Hash::Merge::set_behavior('RIGHT_PRECEDENT');
    return merge($h1, $h2);
}

sub all_touches_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => 'All Touches' },
				sheetname => { default => 'All Touches' },
 				%formatting_params,
			  });
    $params{total_100} = 0;
    $params{total_header} = 'ACTUAL TOTALS';

    return $self->_touches_report(\%params, 
				  $self->{summary}{all_touches},
				  $self->{summary}{distr_touches});
}

sub even_touches_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => 'Even Touches' },
				sheetname => { default => 'Even Touches' },
 				%formatting_params,
			  });

    $params{total_100} = 1;
    $params{total_header} = 'TOTAL';

    return $self->_touches_report(\%params, 
				  $self->{summary}{even_touches},
				  $self->{summary}{even_touches});

}
sub distributed_touches_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => 'Distributed Touches' },
				sheetname => { default => 'Distributed Touches' },
 				%formatting_params,
			  });

    $params{total_100} = 1;
    $params{total_header} = 'TOTAL';

    return $self->_touches_report(\%params, 
				  $self->{summary}{distr_touches},
				  $self->{summary}{distr_touches});

}

sub first_touch_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => 'First Touch' },
				sheetname => { default => 'First Touch' },
 				%formatting_params,
			  });
    $params{total_100} = 1;
    $params{total_header} = 'TOTAL';

    return $self->_touches_report(\%params, 
				  $self->{summary}{firstlast}{'first'},
				  $self->{summary}{firstlast}{'first'});

}

sub last_touch_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => 'Last Touch' },
				sheetname => { default => 'Last Touch' },
 				%formatting_params,
			  });
    $params{total_100} = 1;
    $params{total_header} = 'TOTAL';

    return $self->_touches_report(\%params, 
				  $self->{summary}{firstlast}{'last'},
				  $self->{summary}{firstlast}{'last'});

}

sub fifty_fifty_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => '50/50 First-Last Touch' },
				sheetname => { default => 'Fifty Fifty' },
 				%formatting_params,
			  });
    $params{total_100} = 1;
    $params{total_header} = 'TOTAL';

    return $self->_touches_report(\%params, 
				  $self->{summary}{firstlast}{hybrid},
				  $self->{summary}{distr_touches});

}

sub _touches_report {
    my ($self, $params, $summary, $summary_for_total) = @_;

     # Total based on distributed touches to get actual totals
    my @totals;
    my %totals;
    my $formatter = sub { shift };
    $formatter = sub { sprintf("%d", shift) } if $params->{strict_integer_values};

    for my $col (qw/count transactions revenue/) {
	push(@totals, $formatter->(sum map { $summary_for_total->{$_}{$col} } keys %{$summary_for_total}));
	$totals{$col} = $totals[-1];
    }
    if ($params->{total_100}) {
	push(@totals, 100, 100); # % transactions, % revenue
    }
    else {
	push(@totals, '', ''); # % transactions, % revenue
    }
    my @data;
    for my $channel (sort keys %{$summary}) {
	my $i = 0;
	push(@data, [ [ $channel, $params->{row_heading_format} ],
		      (map { [ $formatter->($summary->{$channel}{$_}), $params->{column_formats}->[$i++ % @{$params->{column_formats}}] ] } qw/count transactions revenue/),
		      (map { [ sprintf("%.2f", $summary->{$channel}{$_} / ($totals{$_} || 1) * 100), $params->{column_formats}->[$i++ % @{$params->{column_formats}}] ] } qw/transactions revenue/),
	     ]);
    }

    # sort by revenue, transactions descending
    @data = sort { $b->[3][0] <=> $a->[3][0] || $b->[2][0] <=> $a->[2][0] } @data;

    push(@data, [ map { [ $_, $params->{column_heading_format} ] } 
		  _map_header($params->{total_header}, $params->{heading_map}), @totals ]);

    my $i = 0;
    my @heading = ('Channel', 'Touches', 'Transactions', 'Revenue', '% Transactions', '% Revenue');
    my %report = ( title => [ $params->{title}, $params->{title_format} ],
		   sheetname => $params->{sheetname},
		   headings => [ map { [ _map_header($_, $params->{heading_map}), $params->{column_heading_format} ] } @heading ],
		   data => \@data,
		   chart => [ map { { type => 'pie',
				      title => { name => $heading[$_],
						 name_formula => [-1, $_],
				      },
				      abs_row => 20 * $i++,
				      abs_col => 7,
				      x_scale => 1,
				      y_scale => 1,
				      series => [ 
					  { categories => [ 0, scalar @data - 2, 0, 0 ],
					    values => [ 0, (scalar @data - 2), $_, $_ ],
					    name_formula => [$_, 0],
					    name => $data[$_][0][0],
					  } ],
		       } } (2, 3) ],
		   start_date => $self->_format_date($self->{current_data}{start_date}),
		   end_date => $self->_format_date($self->{current_data}{end_date}),
		   generation_date => $self->_format_date(),
		   window_length => $self->{summary}->{window_length},

	);
    
    _add_layout(\%report, $params);
    return \%report;
    
}

sub transactions_report {
    my $self = shift;
    my %params = validate(@_, { title => { default => 'Transactions' },
				sheetname => { default => 'Transactions' },
 				%formatting_params,
			  });

    my @summary = sort { $a->{tid} cmp $b->{tid} } @{$self->{summary}{trans}};
    my %channels;
    for my $rec (@summary) {
	$channels{$_}++ for keys %{$rec->{touches}};
    }
    my @channels = sort { $channels{$b} <=> $channels{$a} || $b cmp $a } keys %channels;
    my @data = ( [ map { [ _map_header($_, $params{heading_map}), $params{column_heading_format} ] } ('', '', map { qw/Touches Transactions Revenue/ } @channels )] );


    for my $rec (@summary) {
	my $i = 0;
	push(@data, [ [ $rec->{tid}, $params{row_heading_format} ], 
		      $rec->{'date'}, 
		      map { my $cf = $params{column_formats}->[$i++ % @{$params{column_formats}}];
			    ( [ $rec->{touches}{$_}{count} || '', $cf ],
			      [ $rec->{touches}{$_}{transactions} || '', $cf ],
			      [ $rec->{touches}{$_}{revenue} || '', $cf ] ) 
		      } @channels ]);
    }

    my %report = ( title => [ $params{title}, $params{title_format} ],
		   sheetname => $params{sheetname},
		   headings => [  map { [  _map_header($_, $params{heading_map}), $params{column_heading_format} ] } ('Transaction ID', 'Date', map { (' ', $_, ' ') } @channels) ],
		   data => \@data,
		   start_date => $self->_format_date($self->{current_data}{start_date}),
		   end_date => $self->_format_date($self->{current_data}{end_date}),
		   generation_date => $self->_format_date(),
		   window_length => $self->{summary}->{window_length},

	);

    _add_layout(\%report, \%params);
    return \%report;
}


sub touchlist_report {
    my $self = shift;

    my %params = validate(@_, { title => { default => 'Touch List' },
				sheetname => { default => 'Touch List' },
 				%formatting_params,
			  });

    my @data;
    for my $touchlist (sort { $a->[0] cmp $b->[0] } @{$self->{summary}{touchlist}}) {
	my $i = 0;
	push(@data, [ 
		 [ $touchlist->[0], $params{row_heading_format} ], #tid
		 $self->_format_time($touchlist->[2]), # date
		 $touchlist->[1], # revenue
		 map { my $cf = $params{column_formats}->[$i++ % @{$params{column_formats}}];
		       ( [ $_->[0], $cf ], [ $self->_format_time($_->[1]), $cf ] ) } @$touchlist[3 .. @$touchlist - 1]
	     ]);
    }
    my $maxcols = max(map { 2 * ( @$_ - 3 ) } @{$self->{summary}{touchlist}}) || 0;
    
    my %report = ( title => [ $params{title}, $params{title_format} ],
		   sheetname => $params{sheetname},
		   headings => [  map { [  _map_header($_, $params{heading_map}), $params{column_heading_format} ] } ('Transaction ID', 'Date', 'Revenue', 'Touches', ('') x $maxcols) ],
		   data => \@data,
		   start_date => $self->_format_date($self->{current_data}{start_date}),
		   end_date => $self->_format_date($self->{current_data}{end_date}),
		   generation_date => $self->_format_date(),
		   window_length => $self->{summary}->{window_length},

	);

    _add_layout(\%report, \%params);
    return \%report;
}

sub transaction_distribution_report {
    my $self = shift;

    my %params = validate(@_, { title => { default => 'Transaction Distribution' },
				sheetname => { default => 'Transaction Distribution' },
 				%formatting_params,
			  });

    my $transdist = $self->{summary}{transdist};
    my $transdistoverall = $self->{summary}{transdistoverall};

    # find 95th percentile so last column contains remaining 5%
    my @total;
    my %channels;
    my %bins = map { $_ => 1 } keys %$transdist;
    $bins{$_}++ for keys %$transdistoverall;

    for my $count (sort { $a <=> $b } keys %bins) {
	push(@total, [ $count, ($transdistoverall->{$count} || 0) + (@total > 0 ? $total[-1][1] : 0) ]);
	$channels{$_}++ for keys %{$transdist->{$count}};
    }
    my $main = \@total;
    my $rest;
    if (@total > 10) {
	my $threshold = 0.95 * $total[-1][1];
	my $i = 0;
	($main, $rest) = part { $total[$i++][1] <= $threshold ? 0 : 1 } @total;
    }
    my @headings = ("No. of Touches", map { $_->[0] } @$main);
    # create last roll-up heading
    push(@headings, ">" . $main->[-1][0]) if $rest;
    
    my @data;
    for my $channel ((sort keys %channels), 'OVERALL') {
	my $i = 0;
	push(@data, [ [ $channel, $params{row_heading_format} ],
		      map { 
			  my $cf = $params{column_formats}->[$i++ % @{$params{column_formats}}];
			  [ ($channel eq 'OVERALL' ? $transdistoverall->{$_} : $transdist->{$_}{$channel}) || 0, $cf ] 
		      } map { $_->[0] } @$main ]);
	if ($rest) {
	    # append a bin containing the sum of remaining values
	    push(@{$data[-1]}, sum(map {  ($channel eq 'OVERALL' ? $transdistoverall->{$_->[0]} : $transdist->{$_->[0]}{$channel}) || 0 } @$rest));
	}
    }

    my %report = ( title => [ $params{title}, $params{title_format} ],
		   sheetname => $params{sheetname},
		   headings => [  map { [  _map_header($_, $params{heading_map}), $params{column_heading_format} ] } @headings ],
		   data => \@data,
		   chart => [ { type => 'column',
				x_scale => 1.5,
				y_scale => 1.5,
				series => [ map {
				    { categories => [ -1, -1, 1, scalar @{$data[0]} ],
				      values => [ $_, $_, 1, scalar @{$data[0]} ],
				      name_formula => [$_, 0],
				      name => $data[$_][0],
				    } } (0 .. @data - 1) ]
			      } ],
		   start_date => $self->_format_date($self->{current_data}{start_date}),
		   end_date => $self->_format_date($self->{current_data}{end_date}),
		   generation_date => $self->_format_date(),
		   window_length => $self->{summary}->{window_length},

	);

    _add_layout(\%report, \%params);
    return \%report;
    
}

sub channel_overlap_report {
    my $self = shift;

    my %params = validate(@_, { title => { default => 'Channel Overlap' },
				sheetname => { default => 'Channel Overlap' },
 				%formatting_params,
			  });
    
    my @data;
    my @offsets; # row offsets into data array for each report

    push(@offsets, scalar @data);
    $self->_overlap_report(\%params, "Channel Count", 
			   \@data, sub { $a->[0][0] <=> $b->[0][0] }, $self->{summary}{overlap}{count});
    push(@data, [ ' ' ]);
    push(@offsets, scalar @data);
    $self->_overlap_report(\%params, "Channel Combination", 
			   \@data, sub { $b->[6][0] <=> $a->[6][0] }, $self->{summary}{overlap}{joint});

    push(@offsets, scalar @data);

    my $i = 0;
    my %report = ( title => [ $params{title}, $params{title_format} ],
		   sheetname => $params{sheetname},
		   data => \@data,
		   chart => [ map { { type => 'pie',
				      title => { name => $data[$offsets[$_]][0][0],
						 name_formula => [$offsets[$_], 0],
				      },
				      abs_row => 20 * $i++,
				      abs_col => 8,
				      x_scale => 1,
				      y_scale => 1,
				      series => [ 
					  { categories => [ $offsets[$_] + 1, $offsets[$_ + 1] - 1,
							    0, 0 ],
					    values => [ $offsets[$_] + 1, $offsets[$_ + 1] - 1, 1, 1 ],
					    name_formula => [$offsets[$_] + 1, 0],
					    name => $data[$offsets[$_]][0][0],
					  } ],
		       } } (0 .. 0) ], # just doing first pie, second is too busy
		   start_date => $self->_format_date($self->{current_data}{start_date}),
		   end_date => $self->_format_date($self->{current_data}{end_date}),
		   generation_date => $self->_format_date(),
		   window_length => $self->{summary}->{window_length},

	);

    _add_layout(\%report, \%params);
    return \%report;
}

sub _overlap_report {
    my ($self, $params, $heading1, $result, $comparator, $src) = @_;

    push(@$result, [ map { [ _map_header($_, $params->{heading_map}), $params->{column_heading_format} ] } 
		   ($heading1, 'Touches', 'Transactions', 'Revenue', '% Transactions', '% Revenue', 'Efficiency' ) ]);

    my %totals;
    for my $sum (qw/transactions revenue/) {
	$totals{$sum} += $src->{$_}{$sum} for keys %$src;
    }

    my @data;
    for my $row (keys %$src) {
	my $i = 0;
	push(@data, [ [ $row, $params->{row_heading_format} ],
		       (map { [ $src->{$row}{$_}, $params->{column_formats}->[$i++ % @{$params->{column_formats}}] ] } qw/touches transactions revenue/),
		       (map { [ sprintf("%.2f", $src->{$row}{$_} / ($totals{$_} || 1) * 100), $params->{column_formats}->[$i++ % @{$params->{column_formats}}] ] } qw/transactions revenue/),
		      [ sprintf("%.2f", $src->{$row}{transactions} / ($src->{$row}{touches} || 1)) ]
	     ]);
    }
    push(@$result, sort $comparator @data);
}

		       

sub _add_layout {
    my $report = shift;
    my $params = shift;

    for (qw/header_layout footer_layout strict_integer_values/) {
	$report->{$_} = $params->{$_} if defined $params->{$_};
    }
}

sub _compile_channel_pattern {
    my ($self, $pat) = @_;

    my @parts = split($self->{patsep}, $pat);
    my @idx;
    for (@parts) {
	m/source/ && do { push(@idx, 0); next };
	m/med/ && do { push(@idx, 1); next };
	m/sub|cat/ && do { push(@idx, 2); next };
	warn "Invalid channel pattern component: $_\n";
    }
    if (! @idx) {
	@idx = (0, 1, 2);
    }
    return \@idx;
}

sub _currency_conversion {
    my ($self, $dv) = @_;
    return $self->{revenue_scale} * $dv if $dv =~ m/^[0-9.]+$/;

    die "Currency conversion not implemented: rev = $dv\n";
}

sub _debug {
    my $self = shift;
    my @args = map { ref($_) eq 'CODE' ? $_->() : $_ } @_;
    print STDERR @args if $self->{debug};
}

sub process {
    my $class = shift;
    my $opts = shift;

    my $mt = $class->new(_opts_subset($opts, qw/id event_category fieldsep recsep patsep debug bugfix1 channel_map date_format time_format ga_timezone report_timezone revenue_scale auth_file refresh_token auth_token/));

    $mt->get_data(_opts_subset($opts, qw/start_date end_date/));
    $mt->summarise(_opts_subset($opts, qw/window_length single_order_model channel_pattern channel adjustments/));
    $mt->report(_opts_subset($opts, qw/
all_touches_report even_touches_report distributed_touches_report first_touch_report last_touch_report fifty_fifty_report 
transactions_report touchlist_report transaction_distribution_report channel_overlap_report

all_touches even_touches distributed_touches first_touch last_touch fifty_fifty 
transactions touchlist transaction_distribution channel_overlap

report_order filename format column_heading_format column_formats header_layout footer_layout strict_integer_values heading_map/));
}

sub _opts_subset {
    my ($opts, @fields) = @_;

    my %result;
    for (@fields) {
	$result{$_} = $opts->{$_} if exists $opts->{$_};
    }

    return %result;
}

sub _format_date {
    my $self = shift;
    my $date = shift || DateTime->now->set_time_zone($self->{report_timezone})->truncate(to => 'day');

    return $date->strftime( $self->{date_format} );
}

sub _format_time {
    my $self = shift;
    my $t = shift;

    return DateTime->from_epoch(epoch => $t)
	->set_time_zone($self->{report_timezone})
	->strftime( $self->{time_format} ) 
	if defined $t;
    return 'UNKNOWN';
}

sub authorise {
    my $self = shift;

    my $url = $self->{oauth}->authorize_url;

    print(<<"EOF");
Multitouch Analytics requires access to data from your Google Analytics account.

Please visit the following URL, grant access to this application, and enter
the code you will be shown:

$url

EOF

print("Enter code: ");
    my $code = <STDIN>;
    chomp($code);

    my $res = $self->{oauth}->get_access_token($code);

    SaveConfig($self->{auth_file} || _default_auth_file(), 
               { access_token => $res->{access_token},
                 refresh_token => $res->{refresh_token}});
    $self->{refresh_token} = $res->{refresh_token};
}

sub parse_config {
    my $class = shift;
    my $opts = shift;
    my $conf_file = shift;

    Hash::Merge::set_behavior('RIGHT_PRECEDENT');

    if ($conf_file) {
        die "Config file $conf_file does not exist or is not readable" unless -f $conf_file && -r $conf_file;

        my %file_opts = ParseConfig(-ConfigFile => $conf_file, 
                                    -AutoTrue => 1, 
                                    -SplitPolicy => 'equalsign',
                                    -UTF8 => 1,
                                    -InterPolateVars => 1,
                                    -InterPolateEnv => 1,
                                    -IncludeRelative => 1,
                                    -DefaultConfig => { 
                                        cwd => file($conf_file)->dir->absolute->stringify,
                                    },
            );
        _fix_array_keys(\%file_opts, 'column_formats');

        $opts = merge($opts, \%file_opts);
    }

    $opts->{auth_file} ||= _default_auth_file($conf_file);
    if (-f $opts->{auth_file}) {
        my %auth_opts = ParseConfig(-ConfigFile => $opts->{auth_file});
        $opts = merge($opts, \%auth_opts);
        if ($opts->{debug}) {
            print "Opened auth_file $opts->{auth_file}\n";
            open my $fh, '<', $opts->{auth_file} or die "Failed to open $opts->{auth_file}: $!";
            local $/ = undef;
            my $s = <$fh>;
            close($fh);
            print "Contents:\n$s\n";
            print "Parsed content:\n" . Dumper(\%auth_opts);
        }
    }

    return $opts;
}

sub _default_auth_file {
    my $conf_file = shift || 'multitouchanalytics';

    my (@parts) = grep { $_ } split(/\./, $conf_file);
    pop(@parts) if @parts > 1;
    push(@parts, 'auth');
    return '.' . join('.', @parts);
}

sub _fix_array_keys {
    my $hash = shift;
    my $key = shift;
    if (exists($hash->{$key}) && ref($hash->{$key}) ne 'ARRAY') {
	$hash->{$key} = [ $hash->{$key} ];
    }
    for my $v (values %$hash) {
	if (ref($v) eq 'HASH') {
	    _fix_array_keys($v, $key);
	}
    }
}

=head1 NAME

WWW::Analytics::MultiTouch - Multi-touch web analytics, using Google Analytics

=head1 SYNOPSIS

    use WWW::Analytics::MultiTouch;

    # Simple, all-in-one approach
    WWW::Analytics::MultiTouch->process(id => $analytics_id,
                                        start_date => '2010-01-01',
                                        end_date => '2010-02-01',
                                        filename => 'report.xls');

    # Or step by step
    my $mt = WWW::Analytics::MultiTouch->new(id => $analytics_id);
    $mt->get_data(start_date => '2010-01-01',
                  end_date => '2010-02-01');

    $mt->summarise(window_length => 45);
    $mt->report(filename => 'report-45day.xls');
    
    $mt->summarise(window_length => 30);
    $mt->report(filename => 'report-30day.xls');

=head1 DESCRIPTION

This module provides reporting for multi-touch web analytics, as described at
L<http://www.multitouchanalytics.com>.  

Unlike typical last-session attribution web analytics, multi-touch gives insight
into all of the various marketing channels to which a visitor is exposed before
finally making the decision to buy.

Multi-touch analytics uses a javascript library to send information from a
web user's browser to Google Analytics for raw data collection; this module uses
the Google Analytics API to collate the data and then summarises it in a
spreadsheet, showing (for example):

=over 4

=item * Summary of marketing channels and number of transactions to which each channel
had some contribution (sum of transactions > total transactions)

=item * Summary of channels and fair attribution of transactions (sum of
transactions = total transactions)

=item * First touch, last touch, fifty-fifty first/last touch, and even attribution of transactions.

=item * Overlap analysis

=item * Transaction/touch distribution

=item * List of each transaction and the contributing channels

=back

=head1 GOOGLE ACCOUNT AUTHORISATION

In order to give permission for the multitouch reporting to access your data, you must follow the authorisation process.  On first use, a URL will be displayed.  You must click on this URL or cut and paste it into a browser, log in as the Google user that has access to the Google Analytics profile that you wish to analyse, grant permission, and paste the resulting authorisation code into the console.  After this, the authorisation tokens will be stored and there should be no need to repeat the process.

In case you need to change user or profile or re-authenticate, see the information on the L<auth_file> option.

=head1 BASIC USAGE

=head2 process

    WWW::Analytics::MultiTouch->process(%options)

The process() function integrates all of the steps required to generate a report
into one, i.e. it creates a WWW::Analytics::MultiTouch object, fetches data from
the Google Analytics API, summarises the data and generates a report.

Options available are all of the options for L<new>, L<get_data>, L<summarise>
and L<report>.  Minimum options are id, and typically start_date,
end_date and filename.

Typically the most time consuming part of the process is fetching the data from
Google.  The process() function is suitable if only one set of parameters is to
be used for the reports; to generate multiple reports using, for example,
different attribution windows, it is more efficient to use the full API to fetch
the data once and then run all the needed reports.

=head1 METHODS

=head2 new

  my $mt = WWW::Analytics::MultiTouch->new(%options)

Creates a new WWW::Analytics::MultiTouch object.

Options are:

=over 4

=item * id

This is the Google Analytics reporting ID.  This parameter is mandatory.  This is NOT the ID that you use in the javascript code!  You can find the reporting id in the URL when you log into the Google Analytics console; it is the number following the letter 'p' in the URL, e.g.

  https://www.google.com/analytics/web/#dashboard/default/a111111w222222p123456/

In this example, the ID is 123456.

=item * auth_file

This is the file in which authentication keys received from Google are kept for subsequent use.  The default filename is derived from the configuration file (look for a file in the same directory as the configuration file ending in '.auth').  You may specify an alternative filename if you wish.  

The auth_file will be created on initial usage when authorisation keys are received from Google.  If you need to change the Google username, or re-authorise the software for any other reason, delete the auth_file or specify an auth_file of a different name that does not exist.  Then the initial authorisation process will be repeated and a new auth_file will be created.

=item * event_category

The name of the event category used in Google Analytics to store multi-touch
data.  Defaults to 'multitouch' and only needs to be changed if the equivalent
variable in the associated javascript library has been customised.

=item * fieldsep, recsep

Field and record separators for stored multi-touch data.  These default to '!'
and '*' respectively and only need to be changed if the equivalent variables in
the associated javascript library has been customised.

=item * patsep

The pattern separator for turning source, medium and subcategory information
into a "channel" identifier.  See the C<channel_pattern> option under
L<summarise> for more information.  Defaults to '-'.

=item * channel_map

This is a hashref of channel name (after applying C<channel_pattern>) that maps
the extracted name to a more friendly name.  For example, if channel_pattern is
'med-subcat', then direct traffic appears as '(none)-(none), organic traffic as
organic-(none), etc.  An appropriate channel_map might be:

    channel_map => {
                      '(none)-(none)' => 'Direct',
                      'organic-(none)' => 'Organic'
                   }


=item * date_format, time_format

The format to be used for printing dates and times, respectively, using strftime
patterns.  See L<DateTime/strftime Patterns> for details.  Defaults are '%d %b
%Y' (e.g. 1 Jan 2010) and '%Y-%m-%d %H:%M:%S' (e.g. 2010-01-01 01:00:00).

=item * ga_timezone, report_timezone

Timezone used by Google Analytics, and timezone to be used in the reports,
respectively.  May be specified either as an Olson DB time zone name
("America/Chicago", "UTC") or an offset string ("+0600").  Default is UTC for both.

=item * revenue_scale

Scaling factor for revenue amounts.  Useful if, for example, you wish to display
revenue in thousands of dollars instead of dollars.

=item * debug

Enable debug output.

=back

=head2 get_data

  $mt->get_data(%options)

Get data via the Google Analytics API.

Options are:

=over 4

=item * start_date, end_date

Start and end dates respectively.  The total interval includes both start and
end dates.  Date format is YYYY-MM-DD or YYYYMMDD.  (These dates are with
respect to the report timezone).

=back

=head2 summarise

  $mt->summarise(%options)

Summarise data.

Options are:

=over 4

=item * window_length

The analysis window length, in days.  Only touches this many days prior to any
given order will be included in the analysis.

=item * single_order_model

If set, any touch is counted only once, toward the next order only; subsequent
repeat orders do not include touches prior to the initial order.

=item * channel_pattern

Each "channel" is derived from the Google source (source), Google medium (med)
and a subcategory (subcat) field that can be set in the javascript calls, joined
using the pattern separator patsep (defined in L<new>, default '-').  

For example, the source might be 'yahoo' or 'google' and the medium 'organic' or
'cpc'.  To see a report on channels yahoo-organic, google-organic, google-cpc
etc, the channel pattern would be 'source-med'.  To see the report just at the
search engine level, channel pattern would be 'source', and to see the report
just at the medium level, the channel pattern would be 'med'.

Arbitrary ordering is permissible, e.g. med-subcat-source.

The default channel pattern is 'source-med-subcat'.

=item * channel

A hashref containing channel-specific options.  This is a mapping from channel
name (the friendly name, given in the L<channel_map>) to option hash.

Currently the only option is 'requires_first_touch' (boolean).  If set, a
transaction will only be attributed to the channel if it received the first
touch in the analysis window.  This is mainly used to correct for
over-attribution to the direct channel.  Example:

  {
    Direct => { requires_first_touch => 1 }
  }

=item * adjustments

A hashref containing transactions and revenue corrections that may be
applied for a given day.  This allows, for example, compensation for
lost data for short periods of time.  A typical form of the adjustments hash is:

  {
    2010-09-01 => { transactions => 1.4, revenue => 1.3 }
  }

which would apply correction factors of 1.4 and 1.3 for transaction counts
and revenue respectively for any transactions occurring on the date
2010-09-01.

=back

=head2 report

  $mt->report(%options)

Generate reports.

=head3 Report Type Options

=over 4

=item * all_touches_report

If set, the generated report includes the all-touches report; enabled by
default.  The all-touches report shows, for each channel, the total number of
transactions and the total revenue amount in which that channel played a role.
Since multiple channels may have contributed to each transaction, the total of
all transactions across all channels will exceed the actual number of
transactions.

=item * even_touches_report

If set, the generated report includes the even-touches report; enabled by
default.  The even-touches report shows, for each channel, a number of
transactions and revenue amount evenly distributed between the participating
channels.  For example, if Channel A has 3 touches and Channel B 2 touches, half
of the revenue/transactions will be allocated to Channel A and half to Channel
B.  Since each individual transaction is evenly distributed across the
contributing channels, the total of all transactions (revenue) across all
channels will equal the actual number of transactions (revenue).

=item * distributed_touches_report

If set, the generated report includes the distributed-touches report; enabled by
default.  The distributed-touches report shows, for each channel, a number of
transactions and revenue amount in proportion to the number of touches for that
channel.  Since each individual transaction is distributed across the
contributing channels, the total of all transactions (revenue) across all
channels will equal the actual number of transactions (revenue).

=item * first_touch_report

If set, the generated report includes the first-touch report; enabled by
default.  The first-touch report allocates transactions and revenue to the
channel that received the first touch within the analysis window.

=item * last_touch_report

If set, the generated report includes the last-touch report; enabled by
default.  The last-touch report allocates transactions and revenue to the
channel that received the last touch prior to the transaction.

=item * fifty_fifty_report

If set, the generated report includes the fifty-fifty report; enabled by
default.  The fifty-fifty report allocates transactions and revenue equally
between first touch and last touch contributors.

=item * transactions_report

If set, the generated report includes the transactions report; enabled by default.
The transactions report lists each transaction and the channels that contributed
to it. 

=item * touchlist_report

If set, the generated report includes the touchlist report; enabled by default.
The touchlist report lists the touches for each transaction in chronological
order.  Note that this can be a very large amount of data compared to other reports.

=item * transaction_distribution_report

If set, the generated report includes the transaction distribution report;
enabled by default.  The transaction distribution report shows the number of
transactions that had one touch, two touches, etc, both by channel and as a
total.

=item * channel_overlap_report

If set, the generated report includes the channel overlap report; enabled by
default.  The channel overlap report shows the number of transactions that were
touched by 1 channel, 2 channels, etc, and the number of transactions by channel
combination.

=back

=head3 Report Output Options

=over 4

=item * filename

Name of file in which to save reports.  If not specified, output is sent to STDOUT.  The filename extension, if given, is used to determine the file format, which can be xls, csv or txt.

=item * format

May be set to xls, csv or txt to specify Excel, CSV and Text format output
respectively.  The filename extension takes precedence over this parameter.

=back

=head3 Report Formatting Options

=over 4

=item * title

Title to insert into reports.

=item * column_heading_format

The cell format (see L<WWW::Analytics::MultiTouch/CELL FORMATS>) to use for column headings.

=item * column_formats

An array of one or more cell formats (see L<WWW::Analytics::MultiTouch/CELL
FORMATS>) to use in a round-robin manner across the columns of the data.

=item * header_layout, footer_layout

Page headers and footers.  See L<WWW::Analytics::MultiTouch/HEADERS AND FOOTERS> for details.

=item * strict_integer_values

If set, transactions and revenue will be reported in integer formats.
Where a reasonable number of transactions are being counted, the
fractional part of the transaction count in a distributed transactions
report is rarely of consequence, and for some the concept of a
fractional transaction attribution can be a distraction from the key
messages of these reports, so this option helps to keep it simple.

=item * heading_map

A mapping from default report headings to custom report headings.  For example,

  heading_map => { 
                   Transactions => 'Distributed Transactions',
                   'Revenue' => 'Distributed Revenue (US$)'
                 }


=back 

For every type of report, (all_touches_report, first_touch_report,
transactions_report, etc), report-specific formatting options can be given in a
hashref with corresponding name, e.g. 'all_touches', 'first_touch',
'transactions'.  For example,

  column_heading_format => { 
                             bold => 1,
			     color => 'white',
			     bg_color => 'gray',
			     right => 'white',
                           },
  column_format => [ 
                              { bg_color => '#D0D0D0', },
                              { bg_color => '#E8E8E8', },
                           ],

  all_touches => {
    column_heading_format => { 
                               color => 'blue'
                             }
                 }
      

The report-specific options are merged with the top level options and then used.

=head2 all_touches_report

=head2 even_touches_report

=head2 distributed_touches_report

=head2 first_touch_report

=head2 last_touch_report

=head2 fifty_fifty_report

=head2 touchlist_report

=head2 transaction_distribution_report

=head2 channel_overlap_report

These implement the individual reports, taking options similar to those described under L<report> above.

=head1 DEVELOPER METHODS

As well as the user API methods list above, there are also a number of methods
that have been exposed as part of the API for developer purposes, e.g. for
developing subclasses to override specific functionality, or for integrating
into systems other than Google Analytics.

=head2 set_data

    $mt->set_data(start_date => 20100101,
                  end_date => 20100130,
                  transactions => \%transactions,
    );

Instead of invoking get_data to retrieve data from Google Analytics, it is also
possible to set data directly - e.g. data collected through another mechanism,
or data from Google Analytics that has been saved to file.  set_data allows you
to directly specify the data for subsequent analysis.

Parameters 'start_date' and 'end_date' are used for reporting and should have the form YYYYMMDD.

Parameter 'transactions' is a hash of transaction ID to [date (YMD), list of touches] (see
L<split_events> for description).

=head2 split_events

    @events = $mt->split_events($cookie_value)

Splits event label (i.e. 'multitouch' cookie value) into a list comprising order and touch arrayrefs.  A touch has format 
  [ source, medium, subcat, time ]
and an order has format 
  [ '__ORD', transactionID, revenue, time ].

=head2 condition_entry

    ($conditioned_key, $conditioned_touches) = $self->condition_entry($key, \@touches)

condition_entry is called by L<get_data> for each data entry retrieved from
Google Analytics.  It is possibly useful for subclasses to override, in case any
special data conditioning is required.  $key is the event label (transaction ID)
and @touches is the list of touches, each touch being an array as described
under L<split_events>.  Conditioning might include removal of duplicates, or
normalisation of transaction IDs.

=head2 parse_config

    $opts = WWW::Analytics::MultiTouch->parse_config($opts, $config_file)

Parses $config_file and merges options with $opts.


=head1 RELATED INFORMATION

See L<http://www.multitouchanalytics.com> for further details.

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-analytics-multitouch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Analytics-MultiTouch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Analytics::MultiTouch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Analytics-MultiTouch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Analytics-MultiTouch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Analytics-MultiTouch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Analytics-MultiTouch/>

=back


=head1 COPYRIGHT & LICENSE

 Copyright 2010 YourAmigo Ltd.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.


=cut

1; # End of WWW::Analytics::MultiTouch
