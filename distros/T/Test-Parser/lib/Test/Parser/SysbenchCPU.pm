package Test::Parser::SysbenchCPU;

=head1 NAME

Test::Parser::SysbenchCPU - Perl module to parse output from Sysbench --test=cpu

=head1 SYNOPSIS

    use Test::Parser::SysbenchCPU;
    my $parser = new Test::Parser::SysbenchCPU;
    $parser->parse($text);
    
    $parser->to_xml();

Additional information is available from the subroutines listed below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to parse and neatly display information gained from the 
Sysbench CPU test.  This module will parse the output given by this command and
command similar to it:  `sysbench --test=cpu > cpu.output`  The cpu.output contains
the necessary information that SysbenchCPU is able to parse.

=head1 FUNCTIONS

See L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::SysbenchCPU::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';


=head2 new()

	Purpose: Create a new Test::Parser::SysbenchCPU instance
	Input: None
	Output: SysbenchCPU object

=cut
sub new {
    my $class = shift;
    my Test::Parser::SysbenchCPU $self = fields::new($class);
    $self->SUPER::new();

    $self->testname('sysbench');
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
	Output: SysbenchCPU data

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {sysbench => {data => $self->{data}}};
}


=head2 parse_line()

	Purpose: Parse Sysbench --test=cpu log files.  This method override's the default parse_line() of Test::Parser
	Input: String (one line of log file)
	Output: 1

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    my @labels = ();
    my @keys = ();
    my $size = 0;

    # Trim any leading and trailing whitespaces.
    $line =~ s/(^\s+|\s+$)//g;

    # Determine what info we have in the line...
    if ($line =~ /^Number .*?threads:(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'sum_threads';
        $size = 1;
    }

    elsif ($line =~ /^sysbench v(.+):/) {
        $self->testname('sysbench');
        $self->version($1);
    }

    elsif ($line =~ /^Maximum .*?test:(.+)/) {
        $keys[1] = $1;
        $labels[1] = 'sum_maxprime';
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
