package Test::Presenter::Dbt2;

=head1 NAME

Test::Presenter::Dbt2 - Perl module to parse output files from a DBT-2 test run.

=head1 SYNOPSIS

 use Test::Presenter::Dbt2;

 my $parser = new Test::Presenter::Dbt2;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms DBT-2 output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Presenter> for functions available from the base class.

=cut

use strict;
use warnings;
use CGI;
use CGI::Pretty;
use Chart::Graph::Gnuplot qw(gnuplot);
use Test::Presenter::Iostat;
use Test::Presenter::Sar;
use Test::Presenter::Vmstat;
use XML::Simple;

use fields qw(
              cmdline
              data
              datadir
              db
              format
              log
              outdir
              sample_length
              sysctl
              system
              tablespace
              xml
);

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '0.5';

sub format {
    my $self = shift;
    if (@_) {
        $self->{format} = shift;
    }
    return $self->{format};
}

=head2 new()

Creates a new Test::Presenter::Dbt2 instance.
Also calls the Test::Presenter base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my $input = shift;
    my Test::Presenter::Dbt2 $self = fields::new($class);

    if (-f $input) {
        $self->{xml} = XMLin($input);
    } elsif (ref($input) eq 'HASH') {
        $self->{xml} = $input->{dbt2};
    } else {
        print "I don't know what to do\n";
        exit(1);
    }

    $self->{db} = undef;
    $self->{sample_length} = 60; # Seconds.
    $self->{sysctl} = undef;
    $self->{system} = {};
    #
    # Hash of devices to plot for iostat per tablespace.
    #
    $self->{tablespace} = undef;

    $self->process_mix();

    return $self;
}

=head3 set_devices()

Set the devices devices used for iostat analysis.

=cut
sub set_devices {
    my $self = shift;
    my $tablespace = shift;
    if (@_) {
        @{$self->{tablespace}->{$tablespace}} = @_;
    }
    return @{$self->{tablespace}->{$tablespace}};
}

sub plot {
    my $self = shift;

    $self->plot_metric();
    $self->plot_distributions();
    $self->plot_response_times();
}

sub plot_distributions {
    my $self = shift;

    my @x;
    my @y;
    my @t = ("Delivery", "New Order", "Order Status", "Payment", "Stock Level");
    my @f = ("dist_d", "dist_n", "dist_o", "dist_p", "dist_s");

    for (my $i = 0; $i < 5; $i++) {
        @x = ();
        @y = ();
        my %gopts = (
                'title' => "$t[$i] Transaction Response Time Distribution",
                'yrange' => '[0:]',
                'x-axis label' => 'Response Time (Seconds)',
                'y-axis label' => 'Number of Transactions',
                'extra_opts' => 'set grid xtics ytics',
                'output type' => $self->{format},
                'output file' => "$self->{outdir}/$f[$i].$self->{format}"
        );
        my %dsopts = (
                'title' => $t[$i],
                'type' => 'columns',
        );
        foreach my $x2 (sort { $a <=> $b } keys %{$self->{xml}->{$f[$i]}}) {
            push @x, $x2;
            push @y, $self->{xml}->{$f[$i]}->{$x2};
        }
        gnuplot(\%gopts, [\%dsopts, \@x, \@y]);
    }
}

sub plot_metric {
    my $self = shift;

    my @x = ();
    my @y = ();
    my %gopts = (
            'title' => 'New Order Transactions per Minute',
            'yrange' => '[0:]',
            'x-axis label' => 'Elapsed Time (Minutes)',
            'y-axis label' => 'New-Order Transactions',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/notpm.$self->{format}"
    );
    my %dsopts = (
            'title' => 'New Order',
            'style' => 'lines',
            'type' => 'columns',
    );
    for my $i (@{$self->{xml}->{rt}->{data}}) {
        push @x, $i->{elapsed_time};
        push @y, $i->{n};
    }
    gnuplot(\%gopts, [\%dsopts, \@x, \@y]);
}

sub plot_response_times {
    my $self = shift;

    my @x;
    my @y;
    my @t = ("Delivery", "New Order", "Order Status", "Payment", "Stock Level");
    my @f = ("rt_d", "rt_n", "rt_o", "rt_p", "rt_s");

    for (my $i = 0; $i < 5; $i++) {
        @x = ();
        @y = ();
        my %gopts = (
                'title' => "$t[$i] Transaction Response Time",
                'yrange' => '[0:]',
                'x-axis label' => "Elapsed Time (Minutes)",
                'y-axis label' => 'Response Time (Seconds)',
                'extra_opts' => 'set grid xtics ytics',
                'output type' => $self->{format},
                'output file' => "$self->{outdir}/$f[$i].$self->{format}"
        );
        my %dsopts = (
                'style' => 'lines',
                'title' => $t[$i],
                'type' => 'columns',
        );
        for my $j (@{$self->{xml}->{$f[$i]}}) {
            push @x, $j->{elapsed_time};
            push @y, $j->{response_time};
        }
        gnuplot(\%gopts, [\%dsopts, \@x, \@y]);
    }
}

sub plot_tablespaces {
    my $self = shift;
    my $iostat = shift;

    foreach my $tablespace (sort keys %{$self->{tablespace}}) {
        $iostat->outdir("$self->{outdir}/db/iostat/$tablespace");
        $iostat->plot(@{$self->{tablespace}->{$tablespace}});
    }
}

=head3 to_html()

Create HTML pages.

=cut
sub to_html {
    my $self = shift;

    my $links = '';

    my $q = new CGI;
    my $h = $q->start_html('Database Test 2 Report');

    $h .= $q->h1('Database Test 2 Report');
    $h .= $q->p($self->{xml}->{date});
    #
    # Test summary.
    #
    my $t1 = $q->table(
            $q->Tr(
                    $q->td({align => 'right'},
                            'New Order Transactions per Minute (notpm):') .
                    $q->td({align => 'right'}, sprintf('%.2f',
                            $self->{xml}->{metric}))
            ) .
            $q->Tr(
                    $q->td({align => 'right'}, 'Scale Factor:') .
                    $q->td($self->{xml}->{scale_factor})
            ) .
            $q->Tr(
                    $q->td({align => 'right'}, 'Test Duration (min.):') .
                    $q->td(sprintf('%.2f', $self->{xml}->{duration}))
            ) .
            $q->Tr(
                    $q->td({align => 'right'}, 'Ramp-up Time (min.):') .
                    $q->td(sprintf('%.2f', $self->{xml}->{rampup} / 60.0))
            ) .
            $q->Tr(
                    $q->td({align => 'right'}, 'Total Unknown Errors:') .
                    $q->td($self->{xml}->{errors})
            )
    );
    my $t2 = $q->td($self->image_check("notpm.$self->{format}"));
    $h .= $q->p(
            $q->table($q->caption('Results Summary') .
                    $q->Tr($q->td($t1) . $q->td($t2))));
    my $s = '';
    #
    # Building an XML hash in memory may not be exactly the same as reading it
    # back from a file.  Compensating...
    #
    my $blob;
    if (ref($self->{xml}->{transactions}->{transaction}) eq 'ARRAY') {
        $blob = $self->{xml}->{transactions}->{transaction};
    } else {
        $blob = [];
        foreach my $i (keys %{$self->{xml}->{transactions}->{transaction}}) {
            $self->{xml}->{transactions}->{transaction}->{$i}->{name} = $i;
            push @$blob, $self->{xml}->{transactions}->{transaction}->{$i};
        }
    }

    for my $i (@$blob) {
        my $tname = $i->{name};
        $links = '';
        my $txn = '';
        if ($tname eq 'Delivery') {
            $txn = 'd';
        } elsif ($tname eq 'New Order') {
            $txn = 'n';
        } elsif ($tname eq 'Order Status') {
            $txn = 'o';
        } elsif ($tname eq 'Payment') {
            $txn = 'p';
        } elsif ($tname eq 'Stock Level') {
            $txn = 's';
        } else {
            next;
        }
        #
        # Add links to a transaction's response time charts.
        #
        $links .= $q->td({align => 'center'},
                $self->image_check("rt_$txn." . $self->{format}));
        #
        # Add links to a transaction's time distribution charts.
        #
        $links .= $q->td({align => 'center'},
                $self->image_check("dist_$txn." . $self->{format}));

        $s .= $q->Tr(
                $q->td($tname) .
                $q->td({align => "right"}, sprintf('%.2f', $i->{mix})) .
                $q->td({align => "right"}, $i->{total}) .
                $q->td({align => "right"}, sprintf('%.2f', $i->{rt_avg})) .
                $q->td({align => "right"}, sprintf('%.2f', $i->{rt_90th})) .
                $q->td({align => "right"}, $i->{rollbacks}) .
                $q->td({align => "right"}, sprintf('%.2f',
                        $i->{rollback_per})) .
                $links
        );
    }
    $h .= $q->p(
            $q->table({border => 1},
                    $q->caption('Transaction Summary') .
                    $q->Tr(
                            $q->th({colspan => 3}, 'Transaction') .
                            $q->th({colspan => 2}, 'Response Time') .
                            $q->th({colspan => 2}, 'Rollbacks') .
                            $q->th({colspan => 2}, 'Charts')
                    ) .
                    $q->Tr(
                            $q->th('Name') .
                            $q->th('Mix %') .
                            $q->th('Total') .
                            $q->th('Average (s)') .
                            $q->th('90th %') .
                            $q->th('Total') .
                            $q->th('%') .
                            $q->th('Response Time') .
                            $q->th('Time Distribution')
                    ) .
                    $s
            )
    );
    #
    # Building an XML hash in memory may not be exactly the same as reading it
    # back from a file.  Compensating...
    #
    if ($self->{xml}->{db}->{database}) {
        $self->{xml}->{db}->{name} = $self->{xml}->{db}->{database}->{name};
        $self->{xml}->{db}->{version} =
                $self->{xml}->{db}->{database}->{version};
    }
    $h .= $q->p(
            $q->table(
                    $q->caption('System Summary') .
                    $q->Tr(
                            $q->td({align => 'right'}, 'Operating System:') .
                            $q->td($self->{xml}->{os}{name} . ' ' .
                                    $self->{xml}->{os}{version}) .
                            $q->td($q->a({href => '../proc.out'}, 'Settings'))
                    ) .
                    $q->Tr(
                            $q->td({align => 'right'}, 'Database:') .
                            $q->td($self->{xml}->{db}->{name} . ' ' .
                                    $self->{xml}->{db}->{version}) .
                            $q->td($q->a({href => '../db/param.out'},
                                    'Settings')) .
                            $q->td($q->a({href => '../db/plan0.out'},
                                    'Query Plans')) .
                            $q->td($q->a({href => '../db/'},
                                    'Raw Data'))
                    )
            )
    );
    $h .= $q->p($q->b('Comment: ') . $self->{xml}->{comment});
    $h .= $q->p($q->b('Command line: ') . $self->{xml}->{cmdline});
    $h .= $q->h2('Profiles');

    my $table_data = '';
    my $has_separate_db_system = 0;

    $links = '';
    if (-f "$self->{datadir}/readprofile_ticks.txt") {
        $links .= $q->td($q->a({href => '../readprofile_ticks.txt'},
                'Readprofile'));
    }
    if (-f "$self->{datadir}/db/readprofile_ticks.txt") {
        $links .= $q->td($q->a({href => '../db/readprofile_ticks.txt'},
                'Readprofile'));
        $has_separate_db_system = 1;
    }
    $table_data .= $q->Tr($links);

    $links = '';
    if (-f "$self->{datadir}/oprofile.txt") {
        $links .= $q->td($q->a({href => '../oprofile.txt'}, 'Oprofile'));
    }
    if (-f "$self->{datadir}/db/oprofile.txt") {
        $links .= $q->td($q->a({href => '../db/oprofile.txt'}, 'Oprofile'));
        $has_separate_db_system = 1;
    }
    $table_data .= $q->Tr($links);

    $links = '';
    if (-f "$self->{datadir}/callgraph.txt") {
        $links .= $q->td($q->a({href => '../callgraph.txt'},
                'Oprofile Callgraph'));
    }
    if (-f "$self->{datadir}/db/callgraph.txt") {
        $links .= $q->td($q->a({href => '../db/callgraph.txt'},
                'Oprofile Callgraph'));
        $has_separate_db_system = 1;
    }
    $table_data .= $q->Tr($links);

    $links = '';
    if (-f "$self->{datadir}/oprofile/assembly.txt") {
        $links .= $q->td($q->a({href => '../oprofile/assembly.txt'},
                'Oprofile Annotated Assembly'));
    }
    if (-f "$self->{datadir}/db/oprofile/assembly.txt") {
        $links .= $q->td($q->a({href => '../db/oprofile/assembly.txt'},
                'Oprofile Annotated Assembly'));
        $has_separate_db_system = 1;
    }
    $table_data .= $q->Tr($links);
    my $table_header = '';
    if ($has_separate_db_system == 1) {
        $table_header = $q->Tr($q->th('Driver System') .
                $q->th('Database System'));
    } else {
        $table_header = $q->Tr($q->th('Single System'));
    }
    $h .= $q->p($q->table($table_header . $table_data));

    $h .= $q->h2('System Statistics');
    #
    # sar links
    #
    my $sar1 = Test::Presenter::Sar->new(
            $self->{xml}->{system}->{driver}->{sar});
    $sar1->outdir("$self->{outdir}/sar");
    $sar1->plot();
    my $driver = $sar1->to_html("sar");
    my $db = '';
    my $col_header = '';
    my $sar2;
    if ($self->{xml}->{system}->{db}->{sar}) {
        $sar2 = Test::Presenter::Sar->new($self->{xml}->{system}->{db}->{sar});
        $sar2->outdir("$self->{outdir}/db/sar");
        $sar2->plot();
        $sar2->header(0);
        $db = $sar2->to_html("db/sar");
        $col_header = $q->th('Driver System') . $q->th('Database System');
    } else {
        $col_header = $q->th('Single System');
    }
    $h .= $q->p(
            $q->table(
                    $q->caption('sar') .
                    $q->Tr($col_header) .
                    $q->Tr($q->td({valign => 'top'}, $driver) .
                            $q->td({valign => 'top'}, $db))));
    #
    # vmstat links
    #
    my $vmstat1 = Test::Presenter::Vmstat->new(
            $self->{xml}->{system}->{driver}->{vmstat});
    $vmstat1->outdir("$self->{outdir}/vmstat");
    $vmstat1->plot();
    $driver = $vmstat1->to_html("vmstat");
    $db = '';
    my $vmstat2;
    if ($self->{xml}->{system}->{db}->{vmstat}) {
        $vmstat2 = Test::Presenter::Vmstat->new(
                $self->{xml}->{system}->{db}->{vmstat});
        $vmstat2->outdir("$self->{outdir}/db/vmstat");
        $vmstat2->plot();
        $vmstat2->header(0);
        $db = $vmstat2->to_html("db/vmstat");
        $col_header = $q->th('Driver System') . $q->th('Database System');
    } else {
        $col_header = $q->th('Single System');
    }
    $h .= $q->p(
            $q->table(
                    $q->caption('vmstat') .
                    $q->Tr($col_header) .
                    $q->Tr($q->td({valign => 'top'}, $driver) .
                            $q->td({valign => 'top'}, $db))));
    #
    # iostat links
    #
    my $iostat1 = Test::Presenter::Iostat->new(
            $self->{xml}->{system}->{driver}->{iostat});
    $iostat1->outdir("$self->{outdir}/iostat");
    $db = '';
    my $iostat2;
    if ($self->{xml}->{system}->{db}->{iostat}) {
        $iostat1->plot();
        $iostat2 = Test::Presenter::Iostat->new(
                $self->{xml}->{system}->{db}->{iostat});
        $iostat2->header(0);
        if ($self->{tablespace}) {
            $self->plot_tablespaces($iostat2);
            $db = $q->table($self->html_tablespaces($iostat2));
            #
            # Do this so the tables line up with the captions from the
            # tablespaces.
            #
            $iostat1->caption('driver');
        } else {
            $iostat2->outdir("$self->{outdir}/db/iostat");
            $iostat2->plot();
            $db = $iostat2->to_html("db/iostat");
        }
        $driver = $iostat1->to_html("iostat");
        $col_header = $q->th('Driver System') . $q->th('Database System');
    } else {
        if ($self->{tablespace}) {
            $iostat1->caption('all');
            $iostat1->outdir("$self->{outdir}/iostat");
            $iostat1->plot();
            $driver = $iostat1->to_html("iostat");
            $iostat1->header(0);
            $self->plot_tablespaces($iostat1);
            $db = $self->html_tablespaces($iostat1);
        } else {
            $iostat1->plot();
            $driver = $iostat1->to_html("iostat");
            $col_header = $q->th('Single System');
        }
    }
    $h .= $q->p(
            $q->table(
                    $q->caption('iostat') .
                    $q->Tr($col_header) .
                    $q->Tr($q->td({valign => 'top'}, $driver) .
                            $q->td({valign => 'top'}, $db))));

    $h .= $q->end_html;
    return $h;
}

sub html_tablespaces {
    my $self = shift;
    my $iostat = shift;

    my $q = new CGI;
    my $h = '';
    foreach my $tablespace (sort keys %{$self->{tablespace}}) {
        $iostat->caption($tablespace);
        $h .= $q->td($iostat->to_html("db/iostat/$tablespace"));
    }
    return $h;
}

sub process_mix {
    my $self = shift;

    my $q = new CGI;

    my $current_time;
    my %current_transaction_count;
    my $previous_time;
    my %rollback_count;
    my $total_transaction_count = 0;
    my %transaction_response_time;

    my @delivery_response_time = ();
    my @new_order_response_time = ();
    my @order_status_response_time = ();
    my @payement_response_time = ();
    my @stock_level_response_time = ();

    #
    # Zero out the data.
    #
    $current_transaction_count{'d'} = 0;
    $current_transaction_count{'n'} = 0;
    $current_transaction_count{'o'} = 0;
    $current_transaction_count{'p'} = 0;
    $current_transaction_count{'s'} = 0;

    push @{$self->{xml}->{rt}->{data}},
       {elapsed_time => 0, d => 0, n => 0, o => 0, p=> 0, s=> 0};
    #
    # Because of the way the math works out, and because we want to have 0's for
    # the first datapoint, this needs to start at the first $sample_length,
    # which is in minutes.
    #
    my $elapsed_time = 1;
    my $sample_length = 60;
    for my $i (@{$self->{xml}->{mix}->{data}}) {
        $previous_time = $i->{ctime} unless ($previous_time);
        $current_time = $i->{ctime};
        my $response_time = $i->{response_time};
        if ($current_time >= ($previous_time + $sample_length)) {
            push @{$self->{xml}->{rt}->{data}},
                    {elapsed_time => $elapsed_time,
                    d => $current_transaction_count{'d'},
                    n => $current_transaction_count{'n'},
                    o => $current_transaction_count{'o'},
                    p => $current_transaction_count{'p'},
                    s => $current_transaction_count{'s'}};
            ++$elapsed_time;
            $previous_time = $current_time;
            #
            # Reset counters for the next sample interval.
            #
            $current_transaction_count{'d'} = 0;
            $current_transaction_count{'n'} = 0;
            $current_transaction_count{'o'} = 0;
            $current_transaction_count{'p'} = 0;
            $current_transaction_count{'s'} = 0;
        }
        #
        # Determine response time distributions for each transaction
        # type.  Also determine response time for a transaction when
        # it occurs during the run.  Calculate response times for
        # each transaction.
        #
        my $time;
        $time = sprintf("%.2f", $response_time);
        my $x_time = ($i->{ctime} - $self->{xml}->{start_time}) / 60;
        ++$self->{xml}->{'dist_' . $i->{transaction}}->{$time};
        push @{$self->{xml}->{'rt_' . $i->{transaction}}},
                {elapsed_time => $x_time, response_time => $response_time};
        ++$current_transaction_count{$i->{transaction}};
    }
}

=head3 image_check()

Returns an HTML href a file exists.

=cut
sub image_check {
    my $self = shift;
    my $filename = shift;
    my $link = shift;

    my $q = new CGI;

    $filename =~ /.*\.(.*)/;
    my $format = $1;

    my $h = '';
    if (-f "$self->{outdir}/$filename") {
        $h .= $q->a({href => $filename}, $q->img({src => $filename,
                height => 96, width => 128}));
    }
    return $h;
}

sub outdir {
    my $self = shift;
    if (@_) {
        $self->{outdir} = shift;
        $self->{datadir} = "$self->{outdir}/..";
    }
    return $self->{outdir};
}

1;
__END__

=head1 AUTHOR

Mark Wong <markwkm@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006-2008 Mark Wong & Open Source Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Presenter>

=end

