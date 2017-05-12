package Test::Presenter::Mpstat;

=head1 NAME

Test::Presenter::Mpstat - Perl module to plot data from mpstat

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
                            "$dir/mpstat-cpu.$self->{format}"))) .
            $q->Tr(
                    $h2 .
                    $q->td($self->image_link(
                            "$dir/mpstat-cs.$self->{format}"))) .
            $q->Tr(
                    $h3 .
                    $q->td($self->image_link(
                            "$dir/mpstat-in.$self->{format}"))) .
            $q->Tr(
                    $h4 .
                    $q->td($self->image_link(
                            "$dir/mpstat-io.$self->{format}"))) .
            $q->Tr(
                    $h5 .
                    $q->td($self->image_link(
                            "$dir/mpstat-memory.$self->{format}"))) .
            $q->Tr(
                    $h6 .
                    $q->td($self->image_link(
                            "$dir/mpstat-procs.$self->{format}"))) .
            $q->Tr(
                    $h7 .
                    $q->td($self->image_link(
                            "$dir/mpstat-swap.$self->{format}")))
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

Creates a new Test::Presenter::Mpstat instance.
Also calls the Test::Presenter base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Presenter::Mpstat $self = fields::new($class);
    $self->{xml} = shift;
	#
	# Building an XML hash in memory may not be exactly the same as reading it
	# back from a file.  Compensating...
	#
    $self->{xml} = $self->{xml}->{mpstat} if ($self->{xml}->{mpstat});
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
    # Processor Utilization
    #

    my %gopts_user = (
            'title' => 'Processor Utilization (%user)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-user.$self->{format}"
    );

    my %gopts_nice = (
            'title' => 'Processor Utilization (%nice)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-nice.$self->{format}"
    );

    my %gopts_sys = (
            'title' => 'Processor Utilization (%sys)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-sys.$self->{format}"
    );

    my %gopts_iowait = (
            'title' => 'Processor Utilization (%iowait)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-iowait.$self->{format}"
    );

    my %gopts_irq = (
            'title' => 'Processor Utilization (%irq)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-irq.$self->{format}"
    );

    my %gopts_soft = (
            'title' => 'Processor Utilization (%soft)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-soft.$self->{format}"
    );

    my %gopts_steal = (
            'title' => 'Processor Utilization (%steal)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-steal.$self->{format}"
    );

    my %gopts_idle = (
            'title' => 'Processor Utilization (%idle)',
            'yrange' => '[0:100]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => '% Utilized',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-idle.$self->{format}"
    );

    my %gopts_intrs = (
            'title' => 'Interrupts per Second',
            'yrange' => '[0:]',
            'x-axis label' => "Elapsed Time ($self->{time_units})",
            'y-axis label' => 'Interrupts',
            'extra_opts' => 'set grid xtics ytics',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/mpstat-intrs.$self->{format}"
    );

    #
    # Transform the data from the hash into plottable arrays for Gnuplot.
    # Reorganize data by cpu.
    #
    my %phash = ();
    for my $a (@{$self->{xml}->{data}}) {
        push @{$phash{$a->{cpu}}}, $a;
    }

    my @data_user = ();
    my @data_nice = ();
    my @data_sys = ();
    my @data_iowait = ();
    my @data_irq = ();
    my @data_soft = ();
    my @data_steal = ();
    my @data_idle = ();
    my @data_intrs = ();

    foreach my $key (sort keys %phash) {
        for my $a ($phash{$key}) {
            #
            # Independent data, which we plot on the x-axis.
            #
            my @x = ();

            my @y_user = ();
            my @y_nice = ();
            my @y_sys = ();
            my @y_iowait = ();
            my @y_irq = ();
            my @y_soft = ();
            my @y_steal = ();
            my @y_idle = ();
            my @y_intrs = ();

            my %dsopts = (
                    'style' => 'lines',
                    'title' => "cpu $key",
                    'type' => 'columns',
            );

            foreach my $b (@{$a}) {
                push @x, $b->{elapsed_time};
                push @y_user, $b->{user};
                push @y_nice, $b->{nice};
                push @y_sys, $b->{sys};
                push @y_iowait, $b->{iowait};
                push @y_irq, $b->{irq};
                push @y_soft, $b->{soft};
                push @y_steal, $b->{steal};
                push @y_idle, $b->{idle};
                push @y_intrs, $b->{intrs};
            }

            push @data_user, [\%dsopts, \@x, \@y_user];
            push @data_nice, [\%dsopts, \@x, \@y_nice];
            push @data_sys, [\%dsopts, \@x, \@y_sys];
            push @data_iowait, [\%dsopts, \@x, \@y_iowait];
            push @data_irq, [\%dsopts, \@x, \@y_irq];
            push @data_soft, [\%dsopts, \@x, \@y_soft];
            push @data_steal, [\%dsopts, \@x, \@y_steal];
            push @data_idle, [\%dsopts, \@x, \@y_idle];
            push @data_intrs, [\%dsopts, \@x, \@y_intrs];
        }
    }

    #
    # Generate charts.
    #
    gnuplot(\%gopts_user, @data_user);
    gnuplot(\%gopts_nice, @data_nice);
    gnuplot(\%gopts_sys, @data_sys);
    gnuplot(\%gopts_iowait, @data_iowait);
    gnuplot(\%gopts_irq, @data_irq);
    gnuplot(\%gopts_soft, @data_soft);
    gnuplot(\%gopts_steal, @data_steal);
    gnuplot(\%gopts_idle, @data_idle);
    gnuplot(\%gopts_intrs, @data_intrs);
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

