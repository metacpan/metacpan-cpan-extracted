package Test::Presenter::Vmstat;

=head1 NAME

Test::Presenter::Vmstat - Perl module to plot data from vmstat

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
              format
              header
              outdir
              time_units
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

    my $q = new CGI;
    my $h1 = '';
    my $h2 = '';
    my $h3 = '';
    my $h4 = '';
    my $h5 = '';
    my $h6 = '';
    my $h7 = '';
    if ($self->{header}) {
        $h1 = $q->td('Processor Utilization');
        $h2 = $q->td('Context Switches');
        $h3 = $q->td('Interrupts');
        $h4 = $q->td('I/O');
        $h5 = $q->td('Memory');
        $h6 = $q->td('Processes');
        $h7 = $q->td('Swapping');
    }
    return $q->table(
            $q->Tr(
                    $h1 .
                    $q->td($self->image_link(
                            "$dir/vmstat-cpu.$self->{format}"))) .
            $q->Tr(
                    $h2 .
                    $q->td($self->image_link(
                            "$dir/vmstat-cs.$self->{format}"))) .
            $q->Tr(
                    $h3 .
                    $q->td($self->image_link(
                            "$dir/vmstat-in.$self->{format}"))) .
            $q->Tr(
                    $h4 .
                    $q->td($self->image_link(
                            "$dir/vmstat-io.$self->{format}"))) .
            $q->Tr(
                    $h5 .
                    $q->td($self->image_link(
                            "$dir/vmstat-memory.$self->{format}"))) .
            $q->Tr(
                    $h6 .
                    $q->td($self->image_link(
                            "$dir/vmstat-procs.$self->{format}"))) .
            $q->Tr(
                    $h7 .
                    $q->td($self->image_link(
                            "$dir/vmstat-swap.$self->{format}")))
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

Creates a new Test::Presenter::Vmstat instance.
Also calls the Test::Presenter base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Presenter::Vmstat $self = fields::new($class);
    $self->{xml} = shift;
	#
	# Building an XML hash in memory may not be exactly the same as reading it
	# back from a file.  Compensating...
	#
    $self->{xml} = $self->{xml}->{vmstat} if ($self->{xml}->{vmstat});
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

    system 'mkdir -p ' . $self->{outdir};
    #
    # Independent data, which we plot on the x-axis.
    #
    my @x = ();

    #
    # Procs
    #
    my %gopts_procs = (
            'title' => 'Procs',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Count',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-procs.$self->{format}"
    );
    my @r = ();
    my @b = ();
    my %dsopts_r = (
            'style' => 'lines',
            'title' => 'waiting for run time',
            'type' => 'columns',
    );
    my %dsopts_b = (
            'style' => 'lines',
            'title' => 'in uninterruptible sleep',
            'type' => 'columns',
    );

    #
    # Memory
    #
    my %gopts_memory = (
            'title' => 'Memory',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Kilobytes',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-memory.$self->{format}"
    );
    my %dsopts_buff = (
            'style' => 'lines',
            'title' => 'Buffers',
            'type' => 'columns',
    );
    my %dsopts_cache = (
            'style' => 'lines',
            'title' => 'cache',
            'type' => 'columns',
    );
    my %dsopts_free = (
            'style' => 'lines',
            'title' => 'Free',
            'type' => 'columns',
    );
    my %dsopts_swpd = (
            'style' => 'lines',
            'title' => 'Swapped',
            'type' => 'columns',
    );
    my @buff = ();
    my @cache = ();
    my @free = ();
    my @swpd = ();

    #
    # Swap
    #
    my %gopts_swap = (
            'title' => 'Swap',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Kilobytes / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-swap.$self->{format}"
    );
    my %dsopts_si = (
            'style' => 'lines',
            'title' => 'in from disk',
            'type' => 'columns',
    );
    my %dsopts_so = (
            'style' => 'lines',
            'title' => 'out to disk',
            'type' => 'columns',
    );
    my @si = ();
    my @so = ();

    #
    # I/O
    #
    my %gopts_io = (
            'title' => 'I/O',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Blocks / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-io.$self->{format}"
    );
    my %dsopts_bi = (
            'style' => 'lines',
            'title' => 'received from device',
            'type' => 'columns',
    );
    my %dsopts_bo = (
            'style' => 'lines',
            'title' => 'sent to device',
            'type' => 'columns',
    );
    my @bi = ();
    my @bo = ();

    #
    # Interrupts
    #
    my %gopts_in = (
            'title' => 'Interrupts',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '# of Interrupts / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-in.$self->{format}"
    );
    my %dsopts_in = (
            'style' => 'lines',
            'title' => 'interrupts',
            'type' => 'columns',
    );
    my @in = ();

    #
    # Context Switches
    #
    my %gopts_cs = (
            'title' => 'Context Switches',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '# of Context Switches / Second',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-cs.$self->{format}"
    );
    my %dsopts_cs = (
            'style' => 'lines',
            'title' => 'context switches',
            'type' => 'columns',
    );
    my @cs = ();

    #
    # Processor Utilization
    #
    my %gopts_cpu = (
            'title' => 'Processor Utilization',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/vmstat-cpu.$self->{format}"
    );
    my %dsopts_id = (
            'style' => 'lines',
            'title' => 'idle',
            'type' => 'columns',
    );
    my %dsopts_sy = (
            'style' => 'lines',
            'title' => 'system',
            'type' => 'columns',
    );
    my %dsopts_total = (
            'style' => 'lines',
            'title' => 'total',
            'type' => 'columns',
    );
    my %dsopts_us = (
            'style' => 'lines',
            'title' => 'user',
            'type' => 'columns',
    );
    my %dsopts_wa = (
            'style' => 'lines',
            'title' => 'wait',
            'type' => 'columns',
    );
    my @id = ();
    my @sy = ();
    my @total = ();
    my @us = ();
    my @wa = ();

    #
    # Transform the data from the hash into plottable arrays for Gnuplot.
    #
    for my $a (@{$self->{xml}->{data}}) {
        push @x, $a->{elapsed_time};

        push @r, $a->{r};
        push @b, $a->{b};
  
        push @buff, $a->{buff};
        push @cache, $a->{cache};
        push @free, $a->{free};
        push @swpd, $a->{swpd};

        push @si, $a->{si};
        push @so, $a->{so};

        push @bi, $a->{bi};
        push @bo, $a->{bo};

        push @in, $a->{in};

        push @cs, $a->{cs};

        push @id, $a->{idle};
        push @sy, $a->{sy};
        push @us, $a->{us};
        push @wa, $a->{wa};
        push @total, $a->{sy} + $a->{us} + $a->{wa};
    }

    #
    # Generate charts.
    #
    gnuplot(\%gopts_procs,
        [\%dsopts_r, \@x, \@r],
        [\%dsopts_b, \@x, \@b]);
    gnuplot(\%gopts_memory,
        [\%dsopts_swpd, \@x, \@swpd],
        [\%dsopts_free, \@x, \@free],
        [\%dsopts_buff, \@x, \@buff],
        [\%dsopts_cache, \@x, \@cache]);
    gnuplot(\%gopts_swap,
        [\%dsopts_si, \@x, \@si],
        [\%dsopts_so, \@x, \@so]);
    gnuplot(\%gopts_io,
        [\%dsopts_bi, \@x, \@bi],
        [\%dsopts_bo, \@x, \@bo]);
    gnuplot(\%gopts_in,
        [\%dsopts_in, \@x, \@in]);
    gnuplot(\%gopts_cs,
        [\%dsopts_cs, \@x, \@cs]);
    gnuplot(\%gopts_cpu,
        [\%dsopts_total, \@x, \@total],
        [\%dsopts_us, \@x, \@us],
        [\%dsopts_sy, \@x, \@sy],
        [\%dsopts_id, \@x, \@id],
        [\%dsopts_wa, \@x, \@wa]);
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

