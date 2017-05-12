#!/usr/bin/perl

use strict;
use SVG::TT::Graph::Bar;

my (@x_column, @read_performance, @write_performance);

my @headers;
my %y_columns;

while (<>) {
    my $line = $_;
    $line =~ s/^\s+//;

    if (@headers < 1) {
        # First line is headers
        @headers = split /\s+/, $line;
        shift @headers;  # Get rid of the x column's header
        next;
    }

    my ($kernel, @data) = split /\s+/, $line;

    push @x_column, $kernel;

    foreach my $h (@headers) {
        push @{$y_columns{$h}}, shift @data;
    }
}

foreach my $h (@headers) {
    next unless defined $y_columns{$h};

    my $graph = SVG::TT::Graph::Bar->new({
        'height'            => '600',
        'width'             => '800',
        'graph_title'       => "Iozone historical $h performance",
        'show_graph_title'  => 1,

        'fields'            => \@x_column,
        'show_data_values'  => 0,
        'rotate_x_labels'   => 1,
        'scale_integers'    => 1,
        'scale_divisions'   => 10000,
        'max_scale_value'   => 100000,

        'x_title'           => "CITI_NFS4_ALL Linux patch",
        'show_x_title'      => 1,

        'y_title'           => 'kb/sec',
        'show_y_title'      => 1,
    });

    $graph->add_data({
        'data'     => $y_columns{$h},
        'title'    => '$h performance',
    });

    open (FILE, ">hist-$h-iozone.svg")
        or die "Could not open hist-$h-iozone.svg:  $!\n";
    print FILE $graph->burn();
    close (FILE);

}
