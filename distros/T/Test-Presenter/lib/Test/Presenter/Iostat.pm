package Test::Presenter::Iostat;

=head1 NAME

Test::Presenter::Iostat - Perl module to plot data from vmstat

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use CGI;
use CGI::Pretty;
use XML::Simple;
use Chart::Graph::Gnuplot qw(gnuplot);

use fields qw(
              caption
              format
              header
              outdir
              time_units
              xml
);

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '0.5';

sub caption {
    my $self = shift;
    if (@_) {
        $self->{caption} = shift;
    }
    return $self->{caption};
}

sub format {
    my $self = shift;
    if (@_) {
        $self->{format} = shift;
    }
    return $self->{format};
}

sub header {
    my $self = shift;
    if (@_) {
        $self->{header} = shift;
    }
    return $self->{header};
}

sub to_html {
    my $self = shift;
    my $dir = shift;
    $dir = '.' unless ($dir);

    my $h1 = '';
    my $h2 = '';
    my $h3 = '';
    my $h4 = '';
    my $h5 = '';
    my $h6 = '';
    my $h8 = '';
    my $h9 = '';

    my $q = new CGI;

    if ($self->{header} == 1) {
        $h1 = $q->td('Average Queue Length');
        $h2 = $q->td('Average Request Size');
        $h3 = $q->td('Average Request Time');
        $h4 = $q->td('Read/Write Megabytes');
        $h5 = $q->td('Read/Write Requests Merged');
        $h6 = $q->td('Read/Write Requests');
        $h8 = $q->td('Average Service Time');
        $h9 = $q->td('Disk Utilization');
    }

    return $q->table(
            $q->caption($self->{caption}) .
            $q->Tr(
                    $h1 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-avgqu.$self->{format}"))
            ) .
            $q->Tr(
                    $h2 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-avgrq.$self->{format}"))
            ) .
            $q->Tr(
                    $h3 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-await.$self->{format}"))
            ) .
            $q->Tr(
                    $h4 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-kb.$self->{format}"))
            ) .
            $q->Tr(
                    $h5 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-rqm.$self->{format}"))
            ) .
            $q->Tr(
                    $h6 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-rw.$self->{format}"))
            ) .
            $q->Tr(
                    $h8 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-svctm.$self->{format}"))
            ) .
            $q->Tr(
                    $h9 .
                    $q->td({align => 'center'},
                            $self->image_link(
                                    "$dir/iostat-util.$self->{format}"))
            )
    );
}

sub image_link {
    my $self = shift;
    my $filename = shift;

    my $q = new CGI;
    return $q->a({href => $filename}, $q->img({src => $filename,
        height => 96, width => 128}));
}

=head2 new()

Creates a new Test::Presenter::Iostat instance.
Also calls the Test::Presenter base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Presenter::Iostat $self = fields::new($class);
    $self->{xml} = shift;
	#
	# Building an XML hash in memory may not be exactly the same as reading it
	# back from a file.  Compensating...
	#
    $self->{xml} = $self->{xml}->{iostat} if ($self->{xml}->{iostat});
    $self->{caption} = '';
    $self->{format} = 'png';
    $self->{header} = 1;
    $self->{outdir} = '.';
    $self->{time_units} = 'Minutes';

    return $self;
}

sub outdir {
    my $self = shift;
    if (@_) {
        $self->{outdir} = shift;
    }
    return $self->{outdir};
}

=head3 plot()

Plot the data using Gnuplot.

=cut
sub plot {
    my $self = shift;
    system "mkdir -p $self->{outdir}";
    #
    # List of devices to plot, if specified, else plot all devices.
    #
    my @devices = @_;
    #
    # Independent data, which we plot on the x-axis.
    #
    my @x = ();
    my @ds_rqm = ();
    my @ds_rw = ();
    my @ds_sec = ();
    my @ds_kb = ();
    my @ds_avgrq = ();
    my @ds_avgqu = ();
    my @ds_await = ();
    my @ds_svctm = ();
    my @ds_util = ();

    #
    # Read/Write requests merged per second.
    #
    my %gopts_rqm = (
            'title' => 'Read/Write Requests Merged',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '# of Merges / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-rqm.$self->{format}"
    );
    my %dsopts_temp_rqm = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Read/Write requests per second.
    #
    my %gopts_rw = (
            'title' => 'Read/Write Requests',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Requests / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-rw.$self->{format}"
    );
    my %dsopts_temp_rw = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Read/Write sectors per second.
    #
    my %gopts_sec = (
            'title' => 'Read/Write Sectors',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Sectors / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-sec.$self->{format}"
    );
    my %dsopts_temp_sec = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Read/Write megabytes per second.
    #
    my %gopts_kb = (
            'title' => 'Read/Write Megabytes',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Megabytes / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-kb.$self->{format}"
    );
    my %dsopts_temp_kb = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Average request size.
    #
    my %gopts_avgrq = (
            'title' => 'Average Request Size',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Sectors',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-avgrq.$self->{format}"
    );
    my %dsopts_temp_avgrq = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Average queue length
    #
    my %gopts_avgqu = (
            'title' => 'Average Queue Length',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '#',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-avgqu.$self->{format}"
    );
    my %dsopts_temp_avgqu = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Averate request time
    #
    my %gopts_await = (
            'title' => 'Average Request Time',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Milliseconds',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-await.$self->{format}"
    );
    my %dsopts_temp_await = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Averate service time
    #
    my %gopts_svctm = (
            'title' => 'Average Service Time',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Milliseconds',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-svctm.$self->{format}"
    );
    my %dsopts_temp_svctm = (
            'style' => 'lines',
            'type' => 'columns'
    );
    #
    # Utilization
    #
    my %gopts_util = (
            'title' => '% Utilization',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Percentage',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => "$self->{format}",
            'output file' => "$self->{outdir}/iostat-util.$self->{format}"
    );
    my %dsopts_temp_util = (
            'style' => 'lines',
            'type' => 'columns'
    );

    #
    # Transform the data from the hash into another hash of arrays.
    # There has to be a better way to transform this data.  XQuery???
    #
    my @a = @{$self->{xml}->{data}};
    my $dev = ();
    for (my $i = 0; $i < scalar @a; $i++) {
        for my $k (keys %{$a[$i]}) {
            next if ($k eq 'device');
            push @{$dev->{$a[$i]->{device}}->{$k}}, $a[$i]->{$k};
        }
    }
    #
    # Build the data set arrays to be plotted.
    #
    my $h;
    #
    # Created data sets for all devices or use the list of devices passed to
    # the function.
    #
    unless (@devices) {
        for my $k (sort keys %$dev) {
            push @devices, $k;
        }
    }
    for my $k (@devices) {
        #
        # Skip to the next device if we don't have a reference for it.
        #
        unless ($dev->{$k}) {
            print "Device '$k' does not exist.\n";
            next;
        }
        #
        # Build the x-axis values once.
        #
        push @x, @{$dev->{$k}->{elapsed_time}} if (scalar @x == 0);
        #
        # r/w requested merged per second
        #
        $h = ();
        $h->{title} = "$k rrqm";
        for my $kk (keys %dsopts_temp_rqm) {
            $h->{$kk} = $dsopts_temp_rqm{$kk};
        }
        push @ds_rqm, [\%{$h}, \@x, \@{$dev->{$k}->{rrqm}}];

        $h = ();
        $h->{title} = "$k wrqm";
        for my $kk (keys %dsopts_temp_rqm) {
            $h->{$kk} = $dsopts_temp_rqm{$kk};
        }
        push @ds_rqm, [\%{$h}, \@x, \@{$dev->{$k}->{wrqm}}];
        #
        # r/w per second
        #
        $h = ();
        $h->{title} = "$k r/s";
        for my $kk (keys %dsopts_temp_rw) {
            $h->{$kk} = $dsopts_temp_rw{$kk};
        }
        push @ds_rw, [\%{$h}, \@x, \@{$dev->{$k}->{r}}];

        $h = ();
        $h->{title} = "$k w/s";
        for my $kk (keys %dsopts_temp_rw) {
            $h->{$kk} = $dsopts_temp_rw{$kk};
        }
        push @ds_rw, [\%{$h}, \@x, \@{$dev->{$k}->{w}}];
        #
        # r/w kilobytes per second
        #
        $h = ();
        $h->{title} = "$k rmb";
        for my $kk (keys %dsopts_temp_kb) {
            $h->{$kk} = $dsopts_temp_kb{$kk};
        }
        push @ds_kb, [\%{$h}, \@x, \@{$dev->{$k}->{rmb}}];

        $h = ();
        $h->{title} = "$k wmb";
        for my $kk (keys %dsopts_temp_kb) {
            $h->{$kk} = $dsopts_temp_kb{$kk};
        }
        push @ds_kb, [\%{$h}, \@x, \@{$dev->{$k}->{wmb}}];
        #
        # avgrq-sz
        #
        $h = ();
        $h->{title} = $k;
        for my $kk (keys %dsopts_temp_avgrq) {
            $h->{$kk} = $dsopts_temp_avgrq{$kk};
        }
        push @ds_avgrq, [\%{$h}, \@x, \@{$dev->{$k}->{avgrq}}];
        #
        # avgqu-sz
        #
        $h = ();
        $h->{title} = $k;
        for my $kk (keys %dsopts_temp_avgqu) {
            $h->{$kk} = $dsopts_temp_avgqu{$kk};
        }
        push @ds_avgqu, [\%{$h}, \@x, \@{$dev->{$k}->{avgqu}}];
        #
        # await
        #
        $h = ();
        $h->{title} = $k;
        for my $kk (keys %dsopts_temp_await) {
            $h->{$kk} = $dsopts_temp_await{$kk};
        }
        push @ds_await, [\%{$h}, \@x, \@{$dev->{$k}->{await}}];
        #
        # svctm
        #
        $h = ();
        $h->{title} = $k;
        for my $kk (keys %dsopts_temp_svctm) {
            $h->{$kk} = $dsopts_temp_svctm{$kk};
        }
        push @ds_svctm, [\%{$h}, \@x, \@{$dev->{$k}->{svctm}}];
        #
        # util
        #
        $h = ();
        $h->{title} = $k;
        for my $kk (keys %dsopts_temp_util) {
            $h->{$kk} = $dsopts_temp_util{$kk};
        }
        push @ds_util, [\%{$h}, \@x, \@{$dev->{$k}->{util}}];
    } 

    #
    # Generate charts.
    #
    gnuplot(\%gopts_rqm, @ds_rqm);
    gnuplot(\%gopts_rw, @ds_rw);
    gnuplot(\%gopts_kb, @ds_kb);
    gnuplot(\%gopts_avgrq, @ds_avgrq);
    gnuplot(\%gopts_avgqu, @ds_avgqu);
    gnuplot(\%gopts_await, @ds_await);
    gnuplot(\%gopts_svctm, @ds_svctm);
    gnuplot(\%gopts_util, @ds_util);
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

