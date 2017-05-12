use strict;
use warnings;
use 5.012;
use autodie;

package Text::Cadenceparser;
{
  $Text::Cadenceparser::VERSION = '1.12';
}

use Carp qw/croak carp/;
use Data::Dumper;

use constant DEBUG => $ENV{TEXT_CADENCEPARSER_DEBUG};
use constant DEBUG1 =>
  $ENV{TEXT_CADENCEPARSER_DEBUG1};    # more verbose debugging info


sub new {
    my ( $pkg, %p ) = @_;

    my $self = bless {
        _msg => {},    # Internal message hash, will store the report results
        _files_parsed => 0,    # Number of files parsed
        %p
    }, $pkg;

    if ( defined $self->{folder} ) {

        # When folder is defined, then we need to produce a synthesis report synopsis
        $self->{_files_parsed} = $self->_read_logfiles();    # Gather the data
    } else {

        # Gather file info for displaying area/power

        # First check the input parameters
        # Key is required
        if (
            !defined $self->{key}
            || (   $self->{key} ne 'area'
                && $self->{key} ne 'active'
                && $self->{key} ne 'leakage' )
          )
        {
            croak
"'key' is a required input parameter and should be 'area', 'active' or 'leakage'";
        }

        # Threshold not, defaults to 1 if it is not defined
        $self->{threshold} = $self->{threshold} || 1;

        # Sanity check on input files based on the sort key
        if ( $self->{key} eq 'area' && ( !defined $self->{area_rpt} ) ) {
            croak
"Please specify an area report file if you want to sort according to area";
        }

        if (   ( $self->{key} eq 'active' || $self->{key} eq 'leakage' )
            && ( !defined $self->{power_rpt} ) )
        {
            croak
"Please specify a power report file if you want to sort according to power numbers";
        }

        # Read the reports
        $self->{_files_parsed} = $self->_read_reports();

        # And sort the results
        $self->_sort_data();
    }

    return $self;

}


sub files_parsed { shift->{_files_parsed} }

sub count {
    my ( $self, $type ) = @_;
    my $count = keys %{ $self->{_msg}->{$type} };
    return $count;
}


sub overview {
    my ( $self, $type ) = @_;

    # Report slack
    if ( $self->{_slack}->{_negative} ) {
        print "ERROR: ";
    }

    foreach my $clock ( keys %{ $self->{_slack} } ) {
        next if ( $clock eq '_negative' );    # Skip housekeeping variable
        my $slack = $self->{_slack}->{$clock}->{slack};
        my $violators = $self->{_slack}->{$clock}->{violators} || 'no';
        say "Clock '$clock' slack is $slack ps. (# $violators nets);";
    }

    say "-------------";

    # Report info/warning/errors
    my @types = ( 'info', 'warning', 'error' );

    foreach my $type (@types) {
        my $count = keys %{ $self->{_msg}->{$type} };
        say "$count '$type' messages found";
    }

    say "-------------";

}

sub get {
    my ( $self, $type ) = @_;

    return $self->{_msg}->{$type} if ( $type ~~ [qw(info warning error)] );
    return $self->{_data}->{root}->{$type}->{total}
      if ( $type ~~ [qw(area active leakage)] );
    return $self->{$type};    # Enable self-checking of parameters in tests
}

sub list {
    my ( $self, $type ) = @_;

    my $messages = $self->get($type);

    say "* Detected $type messages:" if ( keys %{$messages} );

    foreach my $key ( keys %{$messages} ) {
        $self->_nice_print( $key, $messages->{$key} );
    }
}

sub slack {
    my ( $self, $clock ) = @_;

    return $self->{_slack}->{$clock}->{slack};

}

sub report {
    my ( $self, %p ) = @_;

    my $data = $self->{_data};

    # First report the totals
    say "Total area   : " . $self->get('area') . " um2"
      if ( $self->get('area') );
    say "Total active : " . $self->get('active') . " mW"
      if ( $self->get('active') );
    say "Total leakage: " . $self->get('leakage') . " mW"
      if ( $self->get('leakage') );

    say "%  : " . $self->_format_str("Name") . "\tArea\tActive\tLeakage ";
    say "     " . $self->_format_str("") . "\t(um2)\t(mW)\t(mW)";
    say "----------------------------------------------------------------";

    foreach my $procent ( sort { $b <=> $a } keys %{$data->{detail}} ) {
        foreach my $item ( sort keys %{$data->{detail}->{$procent}} ) {
            my $leaf = $data->{detail}->{$procent}->{$item};
            my $area   = $leaf->{area}    || '--';
            my $active = $leaf->{active}  || '--';
            my $leak   = $leaf->{leakage} || '--';

            say $self->_format_int($procent) . " : "
              . $self->_format_str( $leaf->{name} )
              . "\t$area\t$active\t$leak";
        }
    }

    # Output formatting in case the value is zero (file not read)
    my $stash_area    = $data->{stash}->{area}    || '--';
    my $stash_active  = $data->{stash}->{active}  || '--';
    my $stash_leakage = $data->{stash}->{leakage} || '--';

    say $self->_format_int( $data->{stash}->{percent} ) . " : "
      . $self->_format_str('<other units>')
      . "\t$stash_area\t$stash_active\t$stash_leakage";

}

sub get_final {
    my ( $self, $key) = @_;

    return $self->{_final}->{$key};

}

# Private function to display a single message to STDOUT
sub _nice_print {
    my ( $self, $key, $message ) = @_;

    my $count = $message->{count};
    my $msg   = $message->{message};

    printf "%s\t%4i  %s\n", $key, $count, $msg;

}

# Internal function to read the logfiles from the source folder and place the
# messages into the data hash
sub _read_logfiles {

    my ( $self, %p ) = @_;

    # Glob all relevant logfiles (=gather their names)
    my $foldername = $self->{folder};

    if ( !-e $foldername ) {
        croak "Result folder '$foldername' does not exist";
    }

    my @files = glob( $foldername . "/*.summary" );

    print "Going to parse files from folder '$foldername': \n" . Dumper(@files)
      if DEBUG1;

    # Go over the files one by one and extract info
    foreach my $file (@files) {
        $self->_gather_entries($file);
    }

    print "Found: \n" . Dumper( $self->{_msg} ) if DEBUG;

    my @timing_logs = glob( $foldername . "/report_qor_map_*" );

    # Go over the files one by one and extract slack info
    foreach my $file (@timing_logs) {
        $self->_gather_slack($file);
        push @files, $file;
    }

    my $final_file = $foldername . "/final.rpt";

    if (-e $foldername . "/final.rpt") {
        $self->_gather_final($final_file);
        push @files, $final_file;
    }

    return scalar @files;

}

# Internal function to read the power/area reports
sub _read_reports {
    my ( $self, %p ) = @_;

    my @files;

    push @files, $self->_parse_area()  if ( defined $self->{area_rpt} );
    push @files, $self->_parse_power() if ( defined $self->{power_rpt} );

    return @files;
}

# Parse the area log report, expecting Encounter RTL compiler file
sub _parse_area {
    my ( $self, %p ) = @_;

    my $filename = $self->{area_rpt};

    open my $fh, "<", $filename
      or die "Could not open $filename: $!";

    say "Parsing area report $filename";

    my $line;

    # Skip until we enter the 'data' zone
    while (<$fh>) {
        $line = $_;
        if ( $line =~ /\-{5}/ ) {
            last;
        }
    }

    # Now parse :-)
    my $regexp = '(\w+)\s+\w+\s+\d+\s+(\d+)';

    while (<$fh>) {
        $line = $_;
        if ( $line =~ /^$regexp/ ) {

            #say "root: $1 \t$2";
            $self->{_data}->{root}->{name} = $1;
            $self->{_data}->{root}->{area}->{total} = $2;
            $self->{_data}->{root}->{area}->{sum_leaves} = 0;
        }
        if ( $line =~ /^\s\s$regexp/ ) {
            my $partial_area = $2;
            $self->{_data}->{leaf}->{$1}->{area} = $partial_area;
            $self->{_data}->{root}->{area}->{sum_leaves} += $partial_area;
        }
    }

    close $fh;

    return $filename;

}

# Parse the power log report, expecting Encouter output file
sub _parse_power {
    my ( $self, %p ) = @_;

    my $filename = $self->{power_rpt};

    open my $fh, "<", $filename
      or die "Could not open $filename: $!";

    say "Parsing power report $filename";

    my $line;

    my $file_type = 'normal';

    # Skip until we enter the 'data' zone
    while (<$fh>) {
        $line = $_;

	# Detect if we're reading a file in normal output mode or in verbose mode
        $file_type = 'verbose' if (/Leakage\s+Internal\s+Net/);

        if ( $line =~ /\-{5}/ ) {
            last;
        }
    }

    # Now parse :-)
    # Regexp for normal mode parsing
    my $regexp = '(\w+)\s+\w+\s+\d+\s+([0-9]*\.?[0-9]+)\s+([0-9]*\.?[0-9]+)';

    # In case the file is verbose mode output then we need another regexp!
    $regexp = '(\w+)\s+\w+\s+\d+\s+([0-9]*\.?[0-9]+)\s+[0-9]*\.?[0-9]+\s+[0-9]*\.?[0-9]+\s+([0-9]*\.?[0-9]+)' if ($file_type eq 'verbose');

    while (<$fh>) {
        $line = $_;
        if ( $line =~ /^$regexp/ ) {

# TODO check for same root name here as a test to see if area and power reports match.
#say "root: $1 \t$2";
            $self->{_data}->{root}->{name}    = $1;
            $self->{_data}->{root}->{leakage}->{total} = $2;
            $self->{_data}->{root}->{active}->{total}  = $3;
            $self->{_data}->{root}->{active}->{sum_leaves} = 0;

        }

        if ( $line =~ /^\s\s$regexp/ ) {
            $self->{_data}->{leaf}->{$1}->{leakage} = $2;
            $self->{_data}->{leaf}->{$1}->{active}  = $3;
            $self->{_data}->{root}->{leakage}->{sum_leaves} += $2;
            $self->{_data}->{root}->{active}->{sum_leaves} += $3;
        }
    }

    close $fh;

    croak "Power input report '$filename' was empty, please check it." if (!defined $self->{_data}->{root}->{active}->{total});

    return $filename;

}

# This function gathers the entries from a single logfile and
# puts them in the $msg hash
sub _gather_entries {
    my ( $self, $fname ) = @_;

    print "Gathering messages in file '$fname'\n" if DEBUG;

    open my $fh, '<', $fname
      or croak "Could not open file '$fname' for reading: $!";

    my $type;
    my $code;

  SKIP_HEADER: while (<$fh>) {
      last if (/-----/);
    }

  PARSE_ENTRIES: while ( my $line = <$fh> ) {

        # Typical line we're looking for looks like this:
        # '  2 Warning ENC-6   Problems detected during configuration file'
        if ( $line =~ /^\s*(\d+)\s(\w+)\s([-\w]+)\s+(.+\S)\s+/ ) {

            # When we encounter such line, make a new entry in the message hash
            my $count = $1;
            $type = lc($2);
            $code = $3;
            my $message = $4;
            print "$count -- $type -- $code -- $message\n" if DEBUG1;
            $self->{_msg}->{$type}->{$code}->{message} = $message;
            $self->{_msg}->{$type}->{$code}->{count}   = $count;
            next;
        }

        if ( $line =~ /\s*(\S.+\S)\s+/ ) {
            croak "Parsing error: found text before info line in '$fname'"
              if ( !defined $type );

            # Append other lines to the last seen message
            $self->{_msg}->{$type}->{$code}->{message} .= " $1";
        }

    }

    close $fh;
}

# This function gathers the slack entries from a single logfile and
# puts them in the $msg hash
sub _gather_slack {
    my ( $self, $fname ) = @_;

    print "Gathering messages in file '$fname'\n" if DEBUG;

    open my $fh, '<', $fname
      or croak "Could not open file '$fname' for reading: $!";

  SKIP_HEADER: while (<$fh>) {
        last if (/Slack/);
    }

    # Skip next line
    my $line = <$fh>;

    # Next one is the one we need
    $line = <$fh>;

    #  PARSE_ENTRIES: while ( $line = <$fh> ) {
    if ( $line =~ /\w+\s+(\w+)\s+(-?\d+.?\d*)\s+(\d*)\s/ ) {
        my $group    = $1;
        my $slack    = $2;
        my $nr_paths = $3;

        $self->{_slack}->{$group}->{slack}     = $slack;
        $self->{_slack}->{$group}->{violators} = $nr_paths;

        if ( $slack < 0 ) {
            $self->{_slack}->{_negative} = 1;
        }
    } else {
        carp "Warning: could not extract slack information from logfiles";
    }

    #  	}

    close $fh;

}

# Extract the information from the final.rpt file
sub _gather_final {
    my ( $self, $fname ) = @_;

    print "Gathering messages in file '$fname'\n" if DEBUG;

    open my $fh, '<', $fname
      or croak "Could not open file '$fname' for reading: $!";

    my $match_col;

    my $line;

    # We want to know in what column the total ('final') data is present.
    # We need to autodetect this because it differes depending on the flow type that was run
    DETECT_COLUMN: while ($line = <$fh>) {
        if ($line =~ /Metric/) {
            my @columns = split /\s+/, $line;
            # Use an index hash to find what the index is of the column we're looking for
            my %indhash;
            @indhash{@columns} = (0 .. $#columns);

            $match_col = $indhash{'final'};

            last;
        }
    }

    # Data begins until next empty line
    FETCH_DATA : while ($line = <$fh>) {
        if ($line =~ /====/) {
            # Skip separator lines
            next;
        } elsif ($line eq "\n") {
            # Stop processing on empty line beacuse we need to switch the handling of the data from here on (other format)
            last;
        } else {
            # Data -> process it
            # First the metric (everything before the :)
            my @data = split /:/, $line;
            my $metric = $data[0];

            # Remove leading spaces in the metric;
            $metric =~ s/^\s+//;

            # Then the values
            my @columns = split /\s+/, $data[1];

            my $value  = $columns[$match_col];

            $self->{_final}->{$metric} = $value;
        }
    }

    # TODO Check if we need to strip the untis from the metric and put them on another place in the hash.

    # skip 3 lines
    #$line = <$fh>;
    #$line = <$fh>;
    #$line = <$fh>;

    # TODO Fetch the totals and store them too.
    #PARSE_TOTALS: while ($line = <$fh>) {
    #    if ($line =~ /^([^:]):\s+(\.+)/) {
    #        $self->{_final}->{$1} = $2;
    #    }
    #}

    close $fh;
}

# Nicely print a string
sub _format_str {
    my ( $self, $val ) = @_;
    my $len = $self->{_presentation}->{namelength};
    return sprintf( "%-" . $len . "s", $val );
}

# nicely print an int
sub _format_int {
    my ( $self, $val ) = @_;
    $val = $val || 0; # Catch cases where the val is not initialized
    return sprintf( "%2i", $val );
}

# Sort the data according to the passed key
sub _sort_data {

    my ( $self, %p ) = @_;

    my $key       = $self->{key};
    my $threshold = $self->{threshold};

    my $total         = $self->get($key);
    my $threshold_abs = $total * $threshold / 100;

    my $unit = $self->{key} eq 'area' ? 'um2' : 'mW';

    say "Sorting on '$key'";

    $self->{_presentation}->{namelength} = 0;

    # Insert an entry for the toplevel so that it get reported if required
    my ($top_area, $top_active, $top_leakage);
    $top_area    = $self->{_data}->{root}->{area}->{total}    - $self->{_data}->{root}->{area}->{sum_leaves}    if (defined $self->{_data}->{root}->{area});
    $top_active  = $self->{_data}->{root}->{active}->{total}  - $self->{_data}->{root}->{active}->{sum_leaves}  if (defined $self->{_data}->{root}->{active});
    $top_leakage = $self->{_data}->{root}->{leakage}->{total} - $self->{_data}->{root}->{leakage}->{sum_leaves} if (defined $self->{_data}->{root}->{leakage});

    # Ensure the right format is used
    $top_area    = sprintf("%d", $top_area)       if (defined $top_area);
    $top_active  = sprintf("%1.3f", $top_active)  if (defined $top_active);
    $top_leakage = sprintf("%1.3f", $top_leakage) if (defined $top_leakage);

    $self->{_data}->{leaf}->{'toplevel'}->{area} = $top_area;
    $self->{_data}->{leaf}->{'toplevel'}->{active} = $top_active;
    $self->{_data}->{leaf}->{'toplevel'}->{leakage} = $top_leakage;

    foreach my $entry ( keys %{$self->{_data}->{leaf}} ) {
        my $value      = $self->{_data}->{leaf}->{$entry}->{$key};
        my $percentage = $value / $total * 100;

        if ( $percentage >= $threshold ) {

            # Store in the 'to be printed with details' hash
            $percentage = int($percentage);
            $self->{_data}->{leaf}->{$entry}->{name} = $entry;
            $self->{_data}->{detail}->{$percentage}->{$entry} = $self->{_data}->{leaf}->{$entry};

            # Update the length of the name for printing later
            my $namelength = length($entry);
            $self->{_presentation}->{namelength} = $namelength
              if ( $self->{_presentation}->{namelength} < $namelength );
        } else {
            $self->{_data}->{stash}->{percent} += $percentage;
            $self->{_data}->{stash}->{area} +=
              $self->{_data}->{leaf}->{$entry}->{area} || 0;
            $self->{_data}->{stash}->{active} +=
              $self->{_data}->{leaf}->{$entry}->{active} || 0;
            $self->{_data}->{stash}->{leakage} +=
              $self->{_data}->{leaf}->{$entry}->{leakage} || 0;
        }
    }

}
1;

# ABSTRACT: Perl module to parse Cadence synthesis tool logfiles

__END__

=pod

=head1 NAME

Text::Cadenceparser - Perl module to parse Cadence synthesis tool logfiles

=head1 VERSION

version 1.12

=head1 SYNOPSIS

my $parser = Text::Cadenceparser->new(folder => './REPORTS');

my $nr_warnings = $parser->count('warnings');

my $warnings    = $parser->get('warnings');

$parser->overview();    # Prints a global report of the parsing results

$parser->list('error'); # Prints the errors to STDOUT

=head1 DESCRIPTION

Module to parse and filter Cadence synthesis tool reports. The idea is to present the user with a short
and comprehensible overview of the synthesis results.

The module supports two ways of working: either you pass the 'folder' parameter, in which case all
files in that folder will be searched for basic synthesis status reporting.

The other way of working is that you pass an area and/or power report file as parameter. The module
then supports generating a compact overview of the results sorted based on a C<key> and a C<threshold>.

As an example, consider a design that has been simulated for power results. Pass the are and power
report files as parameter, and select as C<key> 'active' and C<threshold> '5'. The report will
list all first-level design units that contribute to the active power consumption and that
have a power consumption of more that 5% of the total power. The units that contribute less
than 5% of the power will be merged into a single block and their resulting power consumption is also
listed.

For the power, area and leakage of the toplevel design (meaning the total figure minus the numbers
reported for the subunits) an entry 'toplevel' is added to the report.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new Text::Cadenceparser object. Supported parameters are listed below

=over

=item folder

The folder where to gather the logfiles. If this option is passed, the module will search
through the folder and generate a short and comprehensive overview of the results of the last
synthesis run. If you pass this parameter, other parameters will ignored.

=item area_rpt

Pass an area report file that will be used to gather area input. Not to be used in combination
with the 'folder' parameter.

=item power_rpt

Pass a power report file that will be used to gather power input. Not to be used in combination
with the 'folder' parameter.

=item key

Key to sort the area/power results. Possible options are

=over

=item active

=item leakage

=item area

=back

=item threshold

The percentage-wise threshold of C<key> that the design units need to be above in order to be
listed in the result table.

=back

=head2 C<files_parsed()>

This method reports the number of files that were parsed when creating the object.

=head2 C<count($type)>

This method returns the counted number of C<$type> that were parsed.

C<$type> can be either 'info', 'warning' or 'error'.

=head2 C<overview()>

This method returns an overview of all parsed messages.

=head2 C<get($type)>

Returns a hash containing the messages of type C<$type>.

C<$type> can be either 'info', 'warning' or 'error'.

=head2 C<list($type)>

List the messages of type C<$type> to STDOUT.

C<$type> can be either 'info', 'warning' or 'error'.

=head2 C<slack($clock)>

Report the slack of the synthesis run for a specific clock net

=head2 C<report()>

Reports the reports/logs that are read

=head2 C<get_final($key)>

Report the valus of a C<$key> that was extracted from the final.rpt report. Returns the value or C<undef> in case the value does not exist.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
