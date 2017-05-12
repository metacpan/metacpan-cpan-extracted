package Test::Parser::iozone;

=head1 NAME

Test::Parser::iozone - Perl module to parse output from iozone.

=head1 SYNOPSIS

 use Test::Parser::iozone;

 my $parser = new Test::Parser::iozone;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms iozone output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;
use XML::Simple;
#use Chart::Graph::Gnuplot qw(gnuplot);

@Test::Parser::iozone::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              device
              data
              info
              rundate
              commandline
              _mode
              iteration
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

use constant IOZONE_HEADERS => 
    ( 'KB', 'reclen', 'write', 'rewrite', 'read', 
      'reread', 'random read', 'random write', 'bkwd read', 
      'record rewrite', 'stride read', 'fwrite', 'frewrite', 
      'fread', 'freread');

=head2 new()

Creates a new Test::Parser::iozone instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::iozone $self = fields::new($class);
    $self->SUPER::new();

    $self->testname('iozone');
    $self->type('stress');
    $self->description('FIXME');
    $self->summary('FIXME');
    $self->license('FIXME');
    $self->vendor('FIXME');
    $self->release('FIXME');
    $self->url('FIXME');
    $self->platform('FIXME');

    #
    # iozone data in an array and other supporting information.
    #
    $self->{data} = [];
    $self->{info} = '';
    $self->{rundate} = '';
    $self->{version} = '';
    $self->{commandline} = '';
    $self->{_mode} = '';
    $self->{iteration} = 0;

    #
    # Used for plotting.
    #
    $self->{format} = 'png';
    $self->{outdir} = '.';
    $self->{units} = 'Kbytes/sec';

    return $self;
}

=head3 data()

Returns a hash representation of the iozone data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }

    return $self->{test};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse iozone output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    # 
    # Initial info section
    # 
    if ( $line =~ m/^\t(.*)/ ) {
        if ($self->{_mode} eq 'data') {
            # Looks like maybe there's multiple iozone runs in this file
            # In any case, we're done with this one...
            $self->{_mode} = '';
            return Test::Parser::END_OF_RECORD;
        }
        $self->{_mode} = 'info';
        $self->{info} .= $line;

        if ($line =~ m/Version.*(\d+\.\d+)\b/) {
            $self->version($1);
        }

        if ($line =~ m/Command line used\:\s+(.*)$/) {
            $self->{commandline} = $1;
        }

        if ($line =~ m/Run began\:\s*(Mon|Tue|Wed|Thu|Fri|Sat|Sun)?\s*(.*)$/) {
            $self->{rundate} = $2;

            # Hack to make gnuplot read the data correctly...
            $self->{rundate} =~ s/\s+/:/g;            
        }
    }

    # data
    elsif ($line =~ /^(\s*)\d+/) {
        $self->{_mode} = 'data';
        
        my @h = IOZONE_HEADERS;

        while (@h) {
            if ($self->{iteration} eq 0 ) {
                $self->add_column(shift @h);
            }
            else {
                shift @h;
            }
        }        
        
        $self->{iteration} = 1;
        
        # Strip leading and trailing space
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ( $line =~ m/(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*/ ) {
#            warn ("$1 $2 $3 $4 $5 $6\n");
        
            $self->add_data($1, 1);
            $self->add_data($2, 2);
            $self->add_data($3, 3);
            $self->add_data($4, 4);
            $self->add_data($5, 5);
            $self->add_data($6, 6);
            
            $self->inc_datum();
        }
    }
    return 1;
}

=head3 plot_2d()

Plot the data using Gnuplot.

=cut


=head3 commented_out

FIXME: This will eventually be supported through the Test::Presenter method
 to_plot().  When this method has been written, most of this can be thrown out


sub plot_2d {
    my $self = shift;

    my %gopts;
    $gopts{'defaults'} = {
        'title' => 'iozone Performance',
#        'yrange' => '[0:]',
        'x-axis label' => 'Record size (kb)',
        'y-axis label' => 'File size (kb)',
#        'extra_opts' => 'set grid xtics ytics',
#        'output type' => "$self->{format}",
        'output file' => "$self->{outdir}/iozone-",
    };

    my %data_opts = ( 'title' => '',
                      'style' => 'lines',
                      'type'  => 'columns' ,
                      );

    # TODO:  We're just taking a snapshot at 32 byte record lengths
    #        We should either take this as an input, or provide a
    #        3D plotting capability
    my $reclen = 32;
    my @x_columns;
    my %y_columns;
    foreach my $d (@{$self->{data}}) {
        next unless ($d->{'reclen'} == $reclen);
        push @x_columns, $d->{'KB'};
        foreach my $key (keys %{$d}) {
            next unless (defined $d->{$key});
            push @{$y_columns{$key}}, $d->{$key};
        }
    }

    print "Number of X points (should be about 10-20):",
    scalar @x_columns, "\n";

    #
    # Generate charts.
    #
    foreach my $h (IOZONE_HEADERS) {
        # Skip x-columns
        next if ($h =~ /^kb$/i
                 or $h =~ /^reclen$/i);

        %{$gopts{$h}} = %{$gopts{'defaults'}};
        $gopts{$h}->{'title'} .= " - $h";
        $gopts{$h}->{'output file'} .=  "$h.$self->{format}";

        if (defined $y_columns{$h} ) {
            print "plotting $h\n";
            gnuplot( $gopts{$h}, [\%data_opts, \@x_columns, $y_columns{$h}] );
        }
    }
}
=cut

sub plot_3d {
    # TODO
}

# Retrieves a specific data point from the recordset
sub datum {
    my $self = shift;
    my $file_size = shift || return undef;
    my $reclen = shift || return undef;

    foreach my $d (@{$self->{data}}) {
        if ( $d->{'KB'} == $file_size &&
             $d->{'reclen'} == $reclen) {
            return $d;
        }
    }
    my %null_data;
    foreach my $h (IOZONE_HEADERS) {
        $null_data{$h} = 0;
    }
    return \%null_data;
}

sub _runs_to_data {
    my $runs = shift || return undef;
    my $file_sizes = shift || return undef;
    my $reclens = shift || return undef;
    my %data;

    print "Reading data from runs";

    if (@{$file_sizes} < 1) {
        warn "Error:  No file sizes specified\n";
        return undef;
    }
    if (@{$reclens} < 1) {
        warn "Error:  No record lengths specified\n";
        return undef;
    }
    
    foreach my $run (@{$runs}) {
        print '.';

# TODO:  Text X values not supported...?
#        my $x = $run->name() || $run->{rundate};
        my $x = $run->{rundate};

        foreach my $file_size (@{$file_sizes}) {
            my $key = undef;

            # If multiple file sizes, add to data title
            if (@{$file_sizes}>1) {
                $key = "$file_size kb files";
            }

            foreach my $reclen (@{$reclens}) {
                # If multiple reclens, join to data title
                if (@{$reclens}>1) {
                    if ($key) {
                        $key = join(', ', $key, "$reclen kb rec");
                    } else {
                        $key =  "$reclen kb rec";
                    }
                }

                # Add x,y to data sets
                my $d = $run->datum($file_size, $reclen);
                foreach my $h (IOZONE_HEADERS) {
                    if (defined $d->{$h}) {
                        push @{$data{$h}->{$file_size}->{$reclen}}, [$x, $d->{$h}];
                    }
                }
            }
        }
    }

    print "\n";

    return %data;
}


=head3 commented_out

FIXME: This will eventually be supported through the Test::Presenter method
 to_plot().  When this method has been written, most of this can be thrown out

# This is a static function for plotting multiple runs
# with a date or software version as the X-Axis
sub historical_plot {
    my $runs = shift || return undef;
    my $file_sizes = shift || return undef;
    my $reclens = shift || return undef;

    my $format = $runs->[0]->{format};
    my $outdir = $runs->[0]->{outdir};

    # Graph options
    my %gopts_defaults = 
        (
         'title' => 'Historical iozone Performance',
         'x-axis label' => 'Time',
         'y-axis label' => 'KB/sec',
         'yrange'       => '[0:]',
         'xdata'        => 'time',
         'timefmt'      => '%b:%d:%H:%M:%S:%Y',
         'format'       => ['y', '%.0f'],

         'output file'  => "$outdir/iozone-",
#         'extra_opts'   => 'set grid',
         );

    # Data-set default options
    my %data_opts = 
        ( 
          'title' => '',
          'style' => 'lines',
          'type'  => 'matrix',
           );

    if (@{$runs} < 1) {
        warn "No data to graph\n";
        return undef;
    }
    
    if (@{$file_sizes} == 1) {
        # Put file_size into title
        $gopts_defaults{'title'} = 
            join(" - ", $gopts_defaults{'title'}, "$file_sizes->[0] kb files");
    }

    if (@{$reclens} == 1) {
        # Put reclen into title
        $gopts_defaults{'title'} =
            join(" - ", $gopts_defaults{'title'}, "$reclens->[0] kb records");
    }

    # Transform the list of runs into data matrices indexed by column name
    my %data = _runs_to_data($runs, $file_sizes, $reclens);
    if (values %data < 1) {
        warn "Error:  Could not transform data\n";
        return undef;
    }

    # Create a plot for each of the iozone fields with data defined
    foreach my $h (IOZONE_HEADERS) {
        # Skip x-columns
        next if ($h =~ /^kb$/i
                 or $h =~ /^reclen$/i);

        my %gopts = %gopts_defaults;
        $gopts{'output file'} .=  "$h.$format";

        if ( $data{$h} ) {
            my @data_sets;
            foreach my $file_size (@{$file_sizes}) {
                foreach my $reclen (@{$reclens}) {
                    my %opts = %data_opts;
                    if (@{$file_sizes} > 1) {
                        $opts{'title'} .= " - $file_size kb files";
                    }
                    if (@{$reclens} > 1) {
                        $opts{'title'} .= " - $reclen kb records";
                    }
                    push @data_sets, [\%opts, $data{$h}->{$file_size}->{$reclen}];
                }
            }
            print "plotting $h\n";
            gnuplot(\%gopts, @data_sets );
        }
    }

}

# This is a static function to compare several runs
sub comparison_plot {
    my $runs = shift || return undef;
    my $names = shift || return undef;

    my $num_runs = @{$runs};
    my $num_names = @{$names};

    if ($num_runs != $num_names) {
        warn "$num_runs runs and $num_names provided.\n";
        warn "Error:  Must specify a name for each run\n";
        return undef;
    }

    if ($num_runs < 2) {
        warn "Error:  Need at least 2 runs to do comparison plot\n";
        return undef;
    }

    my $format = $runs->[0]->{format};
    my $outdir = $runs->[0]->{outdir};

    # Graph options
    my %gopts = 
        (
         'title'        => 'iozone Performance Comparison',
         'x-axis label' => 'Record size (kb)',
         'y-axis label' => 'File size (kb)',
         'output file'  => "$outdir/iozone-",
         );

    # Transform the list of runs into data matrixes indexed by column name
    my %data;
    my $reclen = 32;
    foreach my $run (@{$runs}) {
        my $name = shift @{$names};
        my %data_opts = (
                      'title' => $name,
                      'style' => 'lines',
                      'type'  => 'columns',
                      );

        # Extract the data out of hashes and put into columns
        my @x_column;
        my %y_columns;
        foreach my $d ($run->{data}) {
            next unless ($d->{'reclen'} == $reclen);
            push @x_column, $d->{'KB'};

            foreach my $key (keys %{$d}) {
                push @{$y_columns{$key}}, $d->{$key};
            }
        }

        # Put the columns
        foreach my $key (keys %y_columns) {
            push @{$data{$key}}, [\%data_opts, \@x_column, $y_columns{$key}];
        }
    }        

    # Create a plot for each of the iozone fields with data defined
    foreach my $h (IOZONE_HEADERS) {
        # Set the global options
        %{$gopts{$h}} = %{$gopts{'defaults'}};
        $gopts{$h}->{'title'} .= " - $h";
        $gopts{$h}->{'output file'} .=  "$h.$format";

        if (defined $gopts{$h} && defined $data{$h}) {
            print "plotting $h\n";
            gnuplot($gopts{$h}, @{$data{$h}});
        }
    }

}

=cut


sub summary_report {
    my $runs = shift;

    # TODO
    return '';
}


1;
__END__

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Bryce Harrington & Open Source Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

