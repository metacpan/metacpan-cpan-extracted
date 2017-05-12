package Test::Presenter::Sar;

=head1 NAME

Test::Presenter::Sar - Perl module to plot data from sar.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use CGI;
use CGI::Pretty;
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
    my $h8 = '';
    my $h9 = '';
    my $h10 = '';
    my $h11 = '';
    my $h12 = '';
    my $h13 = '';
    my $h14 = '';
    my $h15 = '';
    my $h16 = '';
    if ($self->{header} == 1) {
        $h1 = $q->td('Processor Utilization per CPU');
        $h2 = $q->td('Context Switches');
        $h3 = $q->td('Unused Directory Cache Entries');
        $h4 = $q->td('Allocated Disk Quota Entries');
        $h5 = $q->td('File Handles');
        $h6 = $q->td('Inode Handles');
        $h7 = $q->td('Inode %');
        $h8 = $q->td('Individual Interrupt Counts per Processor');
        $h9 = $q->td('Aggregate Interrupt Counts');
        $h10 = $q->td('Memory');
        $h11 = $q->td('Memory Usage');
        $h12 = $q->td('Paging');
        $h13 = $q->td('Processes Created');
        $h14 = $q->td('RT Signals');
        $h15 = $q->td('Super Block Handlers');
        $h16 = $q->td('Swapping');
    }

    return $q->table(
            $q->Tr(
                    $h1 .
                    $q->td($self->image_link("$dir/sar-cpu.$self->{format}"))) .
            $q->Tr(
                    $h2 .
                    $q->td($self->image_link(
                            "$dir/sar-cswch_s.$self->{format}"))) .
            $q->Tr(
                    $h3 .
                    $q->td($self->image_link(
                            "$dir/sar-dentunusd.$self->{format}"))) .
            $q->Tr(
                    $h4 .
                    $q->td($self->image_link(
                            "$dir/sar-dquot-sz.$self->{format}"))) .
            $q->Tr(
                    $h5 .
                    $q->td($self->image_link(
                            "$dir/sar-file-sz.$self->{format}"))) .
            $q->Tr(
                    $h6 .
                    $q->td($self->image_link(
                            "$dir/sar-inode-sz.$self->{format}"))) .
            $q->Tr(
                    $h7 .
                    $q->td($self->image_link(
                            "$dir/sar-inode-p.$self->{format}"))) .
            $q->Tr(
                    $h8 .
                    $q->td($self->image_link(
                            "$dir/sar-intr.$self->{format}"))) .
            $q->Tr(
                    $h9 .
                    $q->td($self->image_link(
                            "$dir/sar-intr_s.$self->{format}"))) .
            $q->Tr(
                    $h10 .
                    $q->td($self->image_link(
                            "$dir/sar-memory.$self->{format}"))) .
            $q->Tr(
                    $h11 .
                    $q->td($self->image_link(
                            "$dir/sar-memory-usage.$self->{format}"))) .
            $q->Tr(
                    $h12 .
                    $q->td($self->image_link(
                            "$dir/sar-paging.$self->{format}"))) .
            $q->Tr(
                    $h13 .
                    $q->td($self->image_link(
                            "$dir/sar-proc_s.$self->{format}"))) .
            $q->Tr(
                    $h14 .
                    $q->td($self->image_link(
                            "$dir/sar-rtsig-sz.$self->{format}"))) .
            $q->Tr(
                    $h15 .
                    $q->td($self->image_link(
                            "$dir/sar-super-sz.$self->{format}"))) .
            $q->Tr(
                    $h16 .
                    $q->td($self->image_link(
                            "$dir/sar-swapping.$self->{format}")))
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

Creates a new Test::Parser::Sar instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Presenter::Sar $self = fields::new($class);
    $self->{xml} = shift;
	#
	# Building an XML hash in memory may not be exactly the same as reading it
	# back from a file.  Compensating...
	#
    $self->{xml} = $self->{xml}->{sar} if ($self->{xml}->{sar});
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
    # X- and Y-axis data.
    #
    my @x;
    my @y;

    my $h;
    my %dsopts = ();

    #
    # Process creation activity
    #
    my %gopts_proc_s = (
            'title' => 'Processes Created',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Processes Created / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-proc_s.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    if (ref($self->{xml}->{proc_s}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{proc_s}->{data}}) {
          push @x, $i->{time};
          push @y, $i->{proc_s};
      }
    }
    gnuplot(\%gopts_proc_s, [\%dsopts, \@x, \@y]);
    #
    # System swtching activity
    #
    my %gopts_cswch_s = (
            'title' => 'Context Switches',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Context Switches / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-cswch_s.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    if (ref($self->{xml}->{cswch_s}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{cswch_s}->{data}}) {
          push @x, $i->{time};
          push @y, $i->{cswch_s};
      }
    }
    gnuplot(\%gopts_cswch_s, [\%dsopts, \@x, \@y]);
    #
    # Process utilization
    #
    my %gopts_cpu = (
            'title' => 'Processor Utilization',
            'yrange' => '[0:100]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Percentage',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-cpu.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'type' => 'columns',
    );
    my $cpu = ();
    if (ref($self->{xml}->{cpu}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{cpu}->{data}}) {
          #
          # It's silly to save time for each cpu but it's representative of the
          # raw data and it's simple to implement this way.
          #
          push @{$cpu->{$i->{cpu}}->{time}}, $i->{time};
          push @{$cpu->{$i->{cpu}}->{user}}, $i->{user};
          push @{$cpu->{$i->{cpu}}->{idle}}, $i->{idle};
          push @{$cpu->{$i->{cpu}}->{iowait}}, $i->{iowait};
          push @{$cpu->{$i->{cpu}}->{nice}}, $i->{nice};
          push @{$cpu->{$i->{cpu}}->{system}}, $i->{system};
      }
    }
    #
    # Use y as an array of datasets as opposed to y-axis values.
    #
    @y = ();
    for my $i (sort keys %$cpu) {
        for my $j (sort keys %{$cpu->{$i}}) {
            #
            # Don't need to plot time vs. time.
            #
            next if ($j eq 'time');
            $h = ();
            for my $kk (keys %dsopts) {
                $h->{$kk} = $dsopts{$kk};
            }
            $h->{title} = "cpu $i $j";
            push @y, [\%{$h}, \@{$cpu->{$i}->{time}}, \@{$cpu->{$i}->{$j}}];
        }
    }
    gnuplot(\%gopts_cpu, @y);
    #
    # Inode and file tables.
    #
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    my %gopts_dentunusd = (
            'title' => 'Unused Directory Cache Entries',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Number of Entries',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-dentunusd.$self->{format}"
    );
    @x = ();
    @y = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @x, $i->{time};
          push @y, $i->{dentunusd};
      }
    }
    gnuplot(\%gopts_dentunusd, [\%dsopts, \@x, \@y]);

    my %gopts_file_sz = (
            'title' => 'File Handles',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Number of File Handles',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-file-sz.$self->{format}"
    );
    @y = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @y, $i->{'file-sz'};
      }
    }
    gnuplot(\%gopts_file_sz, [\%dsopts, \@x, \@y]);

    my %gopts_inode_sz = (
            'title' => 'Inode Handlers',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Number of Inode Handlers',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-inode-sz.$self->{format}"
    );
    @y = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @y, $i->{'inode-sz'};
      }
    }
    gnuplot(\%gopts_inode_sz, [\%dsopts, \@x, \@y]);

    my %gopts_super_sz = (
            'title' => 'Super Block Handlers',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Number of Super Block Handlers',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-super-sz.$self->{format}"
    );
    @y = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @y, $i->{'super-sz'};
      }
    }
    gnuplot(\%gopts_super_sz, [\%dsopts, \@x, \@y]);

    my %gopts_dquot_sz = (
            'title' => 'Disk Quota Entries',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Number of Disk Quota Entries',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-dquot-sz.$self->{format}"
    );
    @y = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @y, $i->{'dquot-sz'};
      }
    }
    gnuplot(\%gopts_dquot_sz, [\%dsopts, \@x, \@y]);

    my %gopts_rtsig_sz = (
            'title' => 'RT Signals',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Number of Queued RT Signals',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-rtsig-sz.$self->{format}"
    );
    @y = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @y, $i->{'rtsig-sz'};
      }
    }
    gnuplot(\%gopts_rtsig_sz, [\%dsopts, \@x, \@y]);

    my %gopts_p = (
            'title' => 'Inode Percengtages',
            'yrange' => '[0:100]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Percentrage',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-inode-p.$self->{format}"
    );
    my $h1;
    my $h2;
    my $h3;
    for my $kk (keys %dsopts) {
        $h1->{$kk} = $dsopts{$kk};
        $h2->{$kk} = $dsopts{$kk};
        $h3->{$kk} = $dsopts{$kk};
    }
    $h1->{title} = '%super-sz';
    $h2->{title} = '%dquot-sz';
    $h3->{title} = '%rtsig-sz';
    my @y1 = ();
    my @y2 = ();
    my @y3 = ();
    if (ref($self->{xml}->{inode}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{inode}->{data}}) {
          push @y1, $i->{'psuper-sz'};
          push @y2, $i->{'pdquot-sz'};
          push @y3, $i->{'prtsig-sz'};
      }
    }
    gnuplot(\%gopts_p,
            [\%{$h1}, \@x, \@y1],
            [\%{$h2}, \@x, \@y2],
            [\%{$h3}, \@x, \@y3]);
    #
    # Interrupts/s
    #
    my %gopts_intr_s = (
            'title' => 'Interrupts',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Interrupts / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-intr_s.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    if (ref($self->{xml}->{intr_s}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{intr_s}->{data}}) {
          push @x, $i->{time};
          push @y, $i->{intr_s};
      }
    }
    gnuplot(\%gopts_intr_s, [\%dsopts, \@x, \@y]);
    #
    # Interrupts
    #
    my %gopts_intr = (
            'title' => 'Interrupts',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Interrupts / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-intr.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'type' => 'columns',
    );
    my $intr = ();
    if (ref($self->{xml}->{intr_s}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{intr_s}->{data}}) {
          for my $j (sort keys %$i) {
              next if ($j eq 'cpu');
              push @{$intr->{$i->{cpu}}->{$j}}, $i->{$j};
          }
      }
    }
    #
    # Use y as an array of datasets as opposed to y-axis values.
    #
    @y = ();
    for my $i (sort keys %$intr) {
        for my $j (sort keys %{$intr->{$i}}) {
            #
            # Don't need to plot time vs. time.
            #
            next if ($j eq 'time');
            $h = ();
            for my $kk (keys %dsopts) {
                $h->{$kk} = $dsopts{$kk};
            }
            $h->{title} = "cpu $i : intr $j";
            push @y, [\%{$h}, \@{$intr->{$i}->{time}}, \@{$intr->{$i}->{$j}}];
        }
    }
    gnuplot(\%gopts_intr, @y);
    #
    # Memory statistics
    #
    my %gopts_memory = (
            'title' => 'Memory Statistics',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Pages / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-memory.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    my $memory = ();
    if (ref($self->{xml}->{memory}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{memory}->{data}}) {
          for my $k (sort keys %{$i}) {
              if ($k eq 'time') {
                  push @x, $i->{time};
              } else {
                  push @{$memory->{$k}}, $i->{$k};
              }
          }
      }
    }
    for my $i (keys %$memory) {
        $h = ();
        for my $kk (keys %dsopts) {
            $h->{$kk} = $dsopts{$kk};
        }
        $h->{title} = "$i";
        push @y, [\%{$h}, \@x, \@{$memory->{$i}}];
    }
    gnuplot(\%gopts_memory, @y);
    #
    # Memory and swap space utilization.
    #
    my %gopts_kbmem = (
            'title' => 'Memory Usage',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Kilobytes',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-memory-usage.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    my $memory_usage = ();
    if (ref($self->{xml}->{memory_usage}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{memory_usage}->{data}}) {
          for my $k (sort keys %{$i}) {
              if ($k eq 'time') {
                  push @x, $i->{time};
              } else {
                  push @{$memory_usage->{$k}}, $i->{$k};
              }
          }
      }
    }
    for my $i (keys %$memory_usage) {
        #
        # We only want to chart data that start with 'kb' because those numbers
        # are in kilobytes.  The others are percentages.
        #
        next unless $i =~ /^kb/;
        $h = ();
        for my $kk (keys %dsopts) {
            $h->{$kk} = $dsopts{$kk};
        }
        $h->{title} = "$i";
        push @y, [\%{$h}, \@x, \@{$memory_usage->{$i}}];
    }
    gnuplot(\%gopts_kbmem, @y);

    $gopts_kbmem{'y-axis label'} = 'Percentage';
    $gopts_kbmem{'output file'} =
            "$self->{outdir}/sar-memory-usage-p.$self->{format}";
    @y = ();
    for my $i (sort keys %$memory_usage) {
        #
        # We only want to chart data that don't start with 'kb' because those
        # numbers are in percentages.
        #
        next if $i =~ /^kb/;
        $h = ();
        for my $kk (keys %dsopts) {
            $h->{$kk} = $dsopts{$kk};
        }
        $h->{title} = "$i";
        push @y, [\%{$h}, \@x, \@{$memory_usage->{$i}}];
    }
    gnuplot(\%gopts_kbmem, @y);
    #
    # Paging statistics
    #
    my %gopts_paging = (
            'title' => 'Paging Statistics',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Pages / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-paging.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    my $paging = ();
    if (ref($self->{xml}->{paging}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{paging}->{data}}) {
          for my $k (sort keys %{$i}) {
              if ($k eq 'time') {
                  push @x, $i->{time};
              } else {
                  push @{$paging->{$k}}, $i->{$k};
              }
          }
      }
    }
    for my $i (keys %$paging) {
        $h = ();
        for my $kk (keys %dsopts) {
            $h->{$kk} = $dsopts{$kk};
        }
        $h->{title} = "$i";
        push @y, [\%{$h}, \@x, \@{$paging->{$i}}];
    }
    gnuplot(\%gopts_paging, @y);
    #
    # TODO
    # Chart network data.
    #
    # TODO
    # Chart queue data.
    #
    # Swapping statistics
    #
    my %gopts_swapping = (
            'title' => 'Swapping Statistics',
            'yrange' => '[0:]',
            'x-axis label' => 'Time',
            'y-axis label' => 'Pages / Second',
            'xdata' => 'time',
            'extra_opts' => 'set grid xtics ytics',
            'timefmt' => '%H:%M:%S',
            'output type' => $self->{format},
            'output file' => "$self->{outdir}/sar-swapping.$self->{format}"
    );
    %dsopts = (
            'style' => 'lines',
            'title' => 'proc/s',
            'type' => 'columns',
    );
    @x = ();
    @y = ();
    my $swapping = ();
    if (ref($self->{xml}->{swapping}->{data}) eq 'ARRAY') {
      for my $i (@{$self->{xml}->{swapping}->{data}}) {
          for my $k (sort keys %{$i}) {
              if ($k eq 'time') {
                  push @x, $i->{time};
              } else {
                  push @{$swapping->{$k}}, $i->{$k};
              }
          }
      }
    }
    for my $i (keys %$swapping) {
        $h = ();
        for my $kk (keys %dsopts) {
            $h->{$kk} = $dsopts{$kk};
        }
        $h->{title} = "$i";
        push @y, [\%{$h}, \@x, \@{$swapping->{$i}}];
    }
    gnuplot(\%gopts_swapping, @y);
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

=end

