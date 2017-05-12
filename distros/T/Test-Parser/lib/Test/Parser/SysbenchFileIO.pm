package Test::Parser::SysbenchFileIO;

=head1 NAME

Test::Parser::SysbenchFileIO - Perl module to parse output from Sysbench --test=fileio

=head1 SYNOPSIS

    use Test::Parser::SysbenchFileIO;
    my $parser = new Test::Parser::SysbenchFileIO;
    $parser->parse($text);

    $parser->to_xml();

Additional information is available from the subroutines listed below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to parse and neatly display information gained from the 
Sysbench FileIO test.  This module will parse the output given by this command and
commands similar to it:  `sysbench --test=fileio > fileio.output`  The fileio.output contains
the necessary information that SysbenchFileIO is able to parse.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::SysbenchFileIO::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';


=head2 new()

	Purpose: Create a new Test::Parser::SysbenchFileIO instance
	Input: None
	Output: SysbenchFileIO object

=cut
sub new {
    my $class = shift;
    my Test::Parser::SysbenchFileIO $self = fields::new($class);
    $self->SUPER::new();

    $self->testname('sysbench');
    $self->type('unit');
    $self->description('A variety of tests');
    $self->summary('Lots of things');
    $self->license('FIXME');
    $self->vendor('FIXME');
    $self->release('FIXME');
    $self->url('FIXME');
    $self->platform('FIXME');

    $self->{data} = ();

    return $self;
}


=head2 data()

	Purpose: Return a hash representation of the Sysbench data
	Input: None
	Output: SysbenchFileIO data

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {sysbench => {data => $self->{data}}};
}


=head2 parse_line()

	Purpose: Parse Sysbench --test=fileio log files.  This method override's the default parse_line() of Test::Parser
	Input: String (one line of log file)
	Output: 1

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    my @labels = ();
    my @keys = ();
    my $size = 0;

    #
    # Trim any leading and trailing whitespaces.
    #
    $line =~ s/(^\s+|\s+$)//g;

    # Determine what info we have in the line...
    if ($line =~ /^Number .*?threads:(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'num_threads';
        $size = 1;
    }
    elsif ($line =~ /^sysbench v(.+):/) {
        $self->testname('sysbench');
        $self->version($1);
    }
    elsif ($line =~ /^Doing c(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'desc';
        $size = 1;
    }

    elsif ($line =~ /^Extra .*?flags:(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'file_open_flags';
        $size = 1;
    }

    # These are done together as there are 2 pieces of information on each line
    elsif ($line =~ /^(.+).*?files, (\d+)(\w+).*?each/) {
        $keys[1] = $1;
        $labels[1] = 'num_files';
        $keys[2] = $2;
        $labels[2] = 'file_size';
        $keys[3] = $3;
        $labels[3] = 'file_size_units';
        $size = 3;
    }

    elsif ($line =~ /^(\d+)(\w+).*?total file size/) {
        $keys[1] = $1;
        $labels[1] = 'total_file_size';
        $keys[2] = $2;
        $labels[2] = 'total_file_size_units';
        $size = 2;
    }

    elsif ($line =~ /^Block size (\d+)(\w+).*/) {
        $keys[1] = $1;
        $labels[1] = 'block_size';
        $keys[2] = $2;
        $labels[2] = 'block_size_units';
        $size = 2;
    }

    elsif ($line =~ /^Number .*?IO:(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'num_random_req';
        $size = 1;
    }

    elsif ($line =~ /^Read.*?test:(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'rw_ratio';
        $size = 1;
    }

    # These are done together as there are 2 pieces of information on each line
    elsif ($line =~ /^Periodic FSYNC(.+), calling fsync\(\) each (.+) requests/) {
        $keys[1] = $1;
        $labels[1] = 'fsync_status';
        $keys[2] = $2;
        $labels[2] = 'fsync_freq';
        $size = 2;
    }

    elsif ($line =~ /^Calling .*?test,(.+)./) {
        $keys[1] = $1;
        $labels[1] = 'fsync_end';
        $size = 1;
    }

    elsif ($line =~ /^Using (.+) mode/) {
        $keys[1] = $1;
        $labels[1] = 'io_mode';
        $size = 1;
    }

    elsif ($line =~ /^Doing (.+) test/) {
        $keys[1] = $1;
        $labels[1] = 'test_run';
        $size = 1;
    }

    elsif ($line =~ /(.+).*Requests/) {
        $keys[1] = $1;
        $labels[1] = 'op_req_rate';
        $size = 1;
    }

    elsif ($line =~ /^total .*?time:\s+([\.\d]+)(\w+)/) {
        $keys[1] = $1;
        $labels[1] = 'total_time';
        $keys[2] = $2;
        $labels[2] = 'total_time_units';
        $size = 2;
    }

    elsif ($line =~ /^total .*?events:\s+(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'total_events';
        $size = 1;
    }

    elsif ($line =~ /^total .*?execution:\s+(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'total_exec';
        $size = 1;
    }

    elsif ($line =~ /^min:\s+([\.\d]+)(\w+)/) {
        $keys[1] = $1;
        $labels[1] = 'pr_min';
        $keys[2] = $2;
        $labels[2] = 'pr_min_units';
        $size = 2;
    }

    elsif ($line =~ /^avg:\s+([\.\d]+)(\w+)/) {
        $keys[1] = $1;
        $labels[1] = 'pr_avg';
        $keys[2] = $2;
        $labels[2] = 'pr_avg_units';
        $size = 2;
    }

    elsif ($line =~ /^max:\s+([\.\d]+)(\w+)/) {
        $keys[1] = $1;
        $labels[1] = 'pr_max';
        $keys[2] = $2;
        $labels[2] = 'pr_max_units';
        $size = 2;
    }

    elsif ($line =~ /^approx. .*?tile:\s+([\.\d]+)(\w+)/) {
        $keys[1] = $1;
        $labels[1] = 'pr_95';
        $keys[2] = $2;
        $labels[2] = 'pr_95_units';
        $size = 2;
    }

    # These are done together as there are 2 pieces of information on each line
    elsif ($line =~ /^events .*?:(.+)\/(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'event_avg';
        $keys[2] = $2;
        $labels[2] = 'event_stddev';
        $size = 2;
    }

    # These are done together as there are 2 pieces of information on each line
    elsif ($line =~ /^execution .*?:(.+)\/(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'exec_avg';
        $keys[2] = $2;
        $labels[2] = 'exec_stddev';
        $size = 2;
    }

    # These are done together as there are 4 pieces of information on each line
    elsif ($line =~ /^Operations performed: (.+) Read, (.+) Write, (.+) Other = (.+) Total/) {
        $keys[1] = $1;
        $labels[1] = 'ops_reads';
        $keys[2] = $2;
        $labels[2] = 'ops_write';
        $keys[3] = $3;
        $labels[3] = 'ops_other';
        $keys[4] = $4;
        $labels[4] = 'ops_total';
        $size = 4;
    }

    # These are done together as there are 4 pieces of information on each line
    elsif ($line =~ /^Read ([\.\d]+)(\w+)\s+Written\s+([\.\d]+)(\w+).*\s+transferred\s+([\.\d]+)(\w+)\s+\(([\.\d]+)(\w+)/) {
        $keys[1] = $1;
        $labels[1] = 'op_read';
        $keys[2] = $2;
        $labels[2] = 'op_read_units';
        $keys[3] = $3;
        $labels[3] = 'op_written';
        $keys[4] = $4;
        $labels[4] = 'op_written_units';
        $keys[5] = $5;
        $labels[5] = 'op_trans_total';
        $keys[6] = $6;
        $labels[6] = 'op_trans_total_units';
        $keys[7] = $7;
        $labels[7] = 'op_trans_rate';
        $keys[8] = $8;
        $labels[8] = 'op_trans_rate_units';
        $size = 8;
    }
    
    my $do_units = 0;
    
    for (my $tekey = 0; $tekey <= $size; $tekey++)
    {
        if( $tekey+1 <= $size ) {
            my $check_me = $labels[$tekey+1];
            my $orig = $labels[$tekey];
            my $units = $orig;
            $units .= "_units";
            if( $check_me eq $units ) {
                $do_units = 1;
            }
        }
        if ( defined($labels[$tekey]) ) {
            $keys[$tekey] =~ s/(^\s+|\s+$)//g;
            my $col = 0;
            if ($do_units == 1) {
                $keys[$tekey+1] =~ s/(^\s+|\s+$)//g;
                $col = $self->add_column( $labels[$tekey], $keys[$tekey+1] );
                $self->add_data( $keys[$tekey], $col );
                
                $tekey++;
            }
            else {
                $col = $self->add_column( $labels[$tekey] );
                $self->add_data( $keys[$tekey], $col );
            }
            $do_units=0;
        }
    }
    return 1;
}


1;
__END__

=head1 AUTHOR

John Daiker <daikerjohn@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 John Daiker & Open Source Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end
