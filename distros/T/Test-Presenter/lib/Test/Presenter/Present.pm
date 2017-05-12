=head1 NAME





Test::Presenter::Present - A submodule for Test::Presenter
    This module provides a methods for outputting test results with the
    gnuplot tool.  Other tools can be supported in the future, however.

=head1 SYNOPSIS

    $report->to_plot("output.png", "lines");


=head1 DESCRIPTION

Test::Presenter::Present is a helper module to give Test::Presenter the
    ability to output test results with the help of gnuplot.  This is
    supported through the use of the to_plot() method.

=head1 FUNCTIONS

=cut
use strict;
use warnings;
use Data::Dumper;
use IO::File;

use Chart::Graph::Gnuplot qw(&gnuplot);

=head2 to_plot()

    Purpose: Allow our perl object to be outputted with gnuplot
    Input: The item number, a filename to save the generated gnuplot,
    a style for the gnuplot ('lines', 'dots', .etc
    This is the default, an xyplot.  Later this will select the 
    correct type of plot.
    Output: file of type png.

=cut
sub to_plot {
    my $self = shift;
    my $report_obj = $self->{component}->{report};
    # check for type of plot and send to correct function
    if ( $report_obj->{type} eq 'xyplot' ){
        $self->to_xyplot(@_);
    } elsif ( $report_obj->{type} eq 'histogram' ) {
        $self->to_histogram(@_);
    }
}

sub to_xyplot {
    my $self = shift;
    my $report_obj = $self->{component}->{report};

    my $filename = shift || 'result_plot.png';
    my $style = shift || 'linespoints';

    my $i = "item0";

    $report_obj->{plot_title} =~ s/\n//g;
    my $xlabel = $self->create_label('x', $i);
    my $ylabel = $self->create_label('y', $i);

    # Construct the gnuplot options
    # The xlabel, ylabel and title should be in the top level of 
    #   the report object.
    my %gnu_opt_main = (
            'title' => $report_obj->{plot_title},
            'yrange' => '[0:]',
            'x-axis label' => $xlabel,
            'y-axis label' => $ylabel,
            'output type' => "png",
            'output file' => "$filename"
    );
    my @data_sets = ();
    foreach my $data ( sort {substr($a, 4) <=> substr($b, 4)} grep { /item/ } keys %{ $report_obj } ){
        my $my_key = $report_obj->{$data}->{key_title}->[0] || $data;
        my %data_hash = ( "title" => $my_key, 
                    "style" => $style,
                    "type" => "columns");
        my @set = ( \%data_hash,
                    \@{ $report_obj->{$data}->{xdata} },
                    \@{ $report_obj->{$data}->{ydata} },
                  ) ;
        push @data_sets, \@set
    }

    # Run the gnuplot command
    eval gnuplot(\%gnu_opt_main, @data_sets);
    if ($@){
        warn $@ . "\n";
        return 0;
    }
    return 1;
}

sub to_histogram {
    my $self = shift;
    my $report_obj = $self->{component}->{report};

    my $filename = shift || 'result_hist.png';
    my $style = shift || 'boxes fill solid';
    
    my $i = "item0";

    my $xlabel = $self->create_label('x', $i);
    my $ylabel = $self->create_label('y', $i);

    $report_obj->{plot_title} =~ s/\n//g;

     if ( $self->{_debug}>2 ) { warn "Constructing gnuplot call\n"; }
    # Construct the gnuplot command
    # The xlabel, ylabel and title should be in the top level of
    #   the report object.
    my @matrix;
    my $xtic = '[ ';
    my $counter = 0;
    my $maxx = 0;
    my $offset=0.25;
  
    my @numbers = ();
    foreach my $data ( sort {substr($a, 4) <=> substr($b, 4)} grep { /item/ } keys %{ $report_obj } ){
        ($counter) = $data =~ m/item(\d+)$/;
        if ( $self->{_debug}>4 ) { warn "Data Number:  " . $data . "\n"; }
        $counter += $offset;
        my $number_y_point = 0;
        my $y_location = $counter;
        foreach my $y_point (@{$report_obj->{$data}->{ydata}}){
            $matrix[ $number_y_point ] .= "\n";
            $matrix[ $number_y_point ] .= '       [ "' . $y_location . '","' . $y_point . '" ],';
            if ( $self->{_debug}>2 ) { warn "Ydata " . $number_y_point . " " . $y_point . "\n"; }
            if ( $style ne "linespoints"){
                $y_location = $y_location + 0.05;
            }
            $number_y_point += 1;
        }
        $xtic .= '[ "' . $report_obj->{$data}->{xdata}->[0] . '",' . $counter . ' ],';
        if ( $counter > $maxx ) { $maxx = $counter; }
    }
    $xtic .= ' ]';
    $maxx += $offset;

    my $code = 'gnuplot(
             {"title" => $report_obj->{plot_title},
              "x-axis label" => $xlabel,
              "y-axis label" => $ylabel,
              "output type" => "png",
              "output file" => $filename,
              "extra_opts" => "set xtics nomirror rotate\n set boxwidth 0.04 \n",
              "xrange" => "[0:' . $maxx . ']",
              "yrange" => "[0: ]",
              "xtics" => ' . $xtic . '
             },' . "\n";

    my (@my_key) = split ',', $report_obj->{item0}->{key_title};
    my $h = 0;
    foreach my $mat (@matrix){
        $code .= ' [ { "title" => "' . $my_key[$h] . '",
                 "style" => $style,
                 "type" => "matrix"}, 
               ';

        $code .= '[ ' . $mat . ' ]';

        $code .= "         \n],\n";
        $h += 1;
    }
    $code .= ");";

    # Run the gnuplot command
    eval $code;
    if ($@){
        warn $@ . "\n";
    }
    if ( $self->{_debug}>2 ) { warn $code . "\n"; }
    return 1;

}

sub create_label {
    my $self = shift;
    my $report_obj = $self->{component}->{report};
    my $which = shift;
    my $i = shift;
    if ( $which !~ m/^(x|y|z)$/ ){
        return undef;
    }
    my $label_tag = $which . 'label';
    my $unit_tag = $which . 'units';

    my $label = $report_obj->{$i}->{$label_tag};
    if ( ref($report_obj->{$i}->{$label_tag}) ) {
        $label = $report_obj->{$i}->{$label_tag}->[0];
    }
    if ( defined $report_obj->{$i}->{$unit_tag}){
        $label .= ' (' . $report_obj->{$i}->{$unit_tag}->[0]. ')';
    }
    return $label;
}

1;
