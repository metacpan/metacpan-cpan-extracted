package Test::Parser::Dbt5;

=head1 NAME

Test::Parser::Dbt5 - Perl module to parse output files from a DBT-5 test run.

=head1 SYNOPSIS

 use Test::Parser::Dbt5;

 my $parser = new Test::Parser::Dbt5;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms DBT-5 output into a hash that can be used to generate
XML.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use POSIX qw(ceil floor);
use Test::Parser;
use Test::Parser::Iostat;
use Test::Parser::Oprofile;
use Test::Parser::PgOptions;
use Test::Parser::Readprofile;
use Test::Parser::Sar;
use Test::Parser::Sysctl;
use Test::Parser::Vmstat;
use XML::Simple;

@Test::Parser::Dbt5::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              sample_length
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Dbt5 instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Dbt5 $self = fields::new($class);
    $self->SUPER::new();

    $self->name('dbt5');
    $self->type('standards');

    $self->{data} = {};
    $self->{sample_length} = 60; # Seconds.

    return $self;
}

=head3 data()

Returns a hash representation of the dbt5 data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {dbt5 => $self->{data}};
}

sub duration {
    my $self = shift;
    return $self->{data}->{duration};
}

sub errors {
    my $self = shift;
    return $self->{data}->{errors};
}

sub metric {
    my $self = shift;
    return $self->{data}->{metric};
}

=head3

Override of Test::Parser's default parse() routine to make it able
to parse dbt5 output.  Support only reading from a file until a better
parsing algorithm comes along.

=cut
sub parse {
    #
    # TODO
    # Make this handle GLOBS and stuff like the parent class.
    #
    my $self = shift;
    my $input = shift or return undef;
    return undef unless (-d $input);
    my $filename;
    #
    # Put everything into a report directory under the specified DBT-5 output
    # directory.
    #
    $self->{outdir} = $input;
    my $report_dir = "$input/report";
    system "mkdir -p $report_dir";
    #
    # Get general test information.
    #
    $filename = "$input/readme.txt";
    if (-f $filename) {
        $self->parse_readme($filename);
    }
    #
    # Get the mix data.
    #
    $filename = "$input/driver/mix.log";
    if (-f $filename) {
        $self->parse_mix($filename);
    }
    #
    # Get database data.  First determine what database was used.
    #
    $filename = "$input/db/readme.txt";
    if (-f $filename) {
        $self->parse_db($filename);
    }
    #
    # Get oprofile data.
    #
    my $oprofile = "$input/oprofile.txt";
    if (-f $oprofile) {
        my $oprofile = new Test::Parser::Oprofile;
        $oprofile->parse($oprofile);
        my $d = $oprofile->data();
        for my $k (keys %$d) {
            $self->{data}->{$k} = $d->{$k};
        }
    }
    #
    # Get readprofile data.
    #
    my $readprofile = "$input/readprofile.txt";
    if (-f $readprofile) {
        my $readprofile = new Test::Parser::Readprofile;
        $readprofile->parse($readprofile);
        my $d = $readprofile->data();
        for my $k (keys %$d) {
            $self->{data}->{$k} = $d->{$k};
        }
    }
    #
    # Get sysctl data.
    #
    my $sysctl = "$input/proc.out";
    if (-f $sysctl) {
        my $sysctl = new Test::Parser::Sysctl;
        $sysctl->parse($sysctl);
        my $d = $sysctl->data();
        for my $k (keys %$d) {
            $self->{data}->{os}->{$k} = [$d->{$k}];
        }
    }
    #
    # Put all the sar plots under a sar directory.
    #
    $self->parse_sar("$input/sar.out", "$report_dir/sar", 'driver');
    $self->parse_sar("$input/db/sar.out", "$report_dir/db/sar", 'db');
    #
    # Put all the vmstat plots under a vmstat directory.
    #
    $self->parse_vmstat("$input/vmstat.out", "$report_dir/vmstat",
            'driver');
    $self->parse_vmstat("$input/db/vmstat.out", "$report_dir/db/vmstat",
            'db');
    #
    # Put all the iostat plots under a iostat directory.
    #
    $self->parse_iostat("$input/iostatx.out", "$report_dir/iostat",
            'driver');
    $self->parse_iostat("$input/db/iostatx.out", "$report_dir/db/iostat",
            'db');

    return 1;
}

sub parse_db {
    my $self = shift;
    my $filename = shift;

    open(FILE, "< $filename");
    my $line = <FILE>;
    close(FILE);
    #
    # Check to see if the parameter output file exists.
    #
    $filename = $self->{outdir} . "/db/param.out";
    if (-f $filename) {
        my $db;
        if ($line =~ /PostgreSQL/) {
            $db = new Test::Parser::PgOptions;
        } else {
            print "unknown database type: $line\n";
            exit 1;
	}
        $db->parse($filename);
        my $d = $db->data();
        for my $k (keys %$d) {
            $self->{data}->{db}->{$k} = $d->{$k};
        }
    }
}

sub parse_mix {
    my $self = shift;
    my $filename = shift;
    my $current_time;
    my $previous_time;
    my $elapsed_time = 1;
    my $total_transaction_count = 0;
    my %transaction_count;
    my %error_count;
    my %rollback_count;
    my %transaction_response_time;

    my @trade_order_response_time = ();
    my @trade_result_response_time = ();
    my @trade_lookup_response_time = ();
    my @trade_update_response_time = ();
    my @trade_status_response_time = ();
    my @customer_position_response_time = ();
    my @broker_volume_response_time = ();
    my @security_detail_response_time = ();
    my @market_feed_response_time = ();
    my @market_watch_response_time = ();
    my @data_maintenance_response_time = ();
    #
    # Zero out the data.
    #
    $rollback_count{ '0' } = 0;
    $rollback_count{ '1' } = 0;
    $rollback_count{ '2' } = 0;
    $rollback_count{ '3' } = 0;
    $rollback_count{ '4' } = 0;
    $rollback_count{ '5' } = 0;
    $rollback_count{ '6' } = 0;
    $rollback_count{ '7' } = 0;
    $rollback_count{ '8' } = 0;
    $rollback_count{ '9' } = 0;
    $rollback_count{ '10' } = 0;
    #
    # Transaction counts for the steady state portion of the test.
    #
    $transaction_count{ '0' } = 0;
    $transaction_count{ '1' } = 0;
    $transaction_count{ '2' } = 0;
    $transaction_count{ '3' } = 0;
    $transaction_count{ '4' } = 0;
    $transaction_count{ '5' } = 0;
    $transaction_count{ '6' } = 0;
    $transaction_count{ '7' } = 0;
    $transaction_count{ '8' } = 0;
    $transaction_count{ '9' } = 0;
    $transaction_count{ '10' } = 0;

    $self->{data}->{errors} = 0;
    $self->{data}->{steady_state_start_time} = undef;
    $self->{data}->{start_time} = undef;

    open(FILE, "< $filename");
    while (defined(my $line = <FILE>)) {
        chomp $line;
        my @word = split /,/, $line;

        if (scalar(@word) == 4) {
            $current_time = $word[0];
            my $transaction = $word[1];
            my $response_time = $word[2];
            my $tid = $word[3];

            #
            # Transform mix.log into XML data.
            #
            push @{$self->{data}->{mix}->{data}},
                    {ctime => $current_time, transaction => $transaction,
                    response_time => $response_time, thread_id => $tid};

            unless ($self->{data}->{start_time}) {
                $self->{data}->{start_time} = $previous_time = $current_time;
            }
            #
            # Count transactions per second based on transaction type only
            # during the steady state phase.
            #
            if ($self->{data}->{steady_state_start_time}) {
                if ($transaction eq '0') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @trade_order_response_time, $response_time;
                } elsif ($transaction eq '1') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @trade_result_response_time, $response_time;
                } elsif ($transaction eq '2') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @trade_lookup_response_time, $response_time;
                } elsif ($transaction eq '3') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @trade_update_response_time, $response_time;
                } elsif ($transaction eq '4') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @trade_status_response_time, $response_time;
                } elsif ($transaction eq '5') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @customer_position_response_time, $response_time;
                } elsif ($transaction eq '6') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @broker_volume_response_time, $response_time;
                } elsif ($transaction eq '7') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @security_detail_response_time, $response_time;
                } elsif ($transaction eq '8') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @market_feed_response_time, $response_time;
                } elsif ($transaction eq '9') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @market_watch_response_time, $response_time;
                } elsif ($transaction eq '10') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @data_maintenance_response_time, $response_time;
                } elsif ($transaction eq '0R') {
                    ++$rollback_count{'0'};
                } elsif ($transaction eq '1R') {
                    ++$rollback_count{'1'};
                } elsif ($transaction eq '2R') {
                    ++$rollback_count{'2'};
                } elsif ($transaction eq '3R') {
                    ++$rollback_count{'3'};
                } elsif ($transaction eq '4R') {
                    ++$rollback_count{'4'};
                } elsif ($transaction eq '5R') {
                    ++$rollback_count{'5'};
                } elsif ($transaction eq '6R') {
                    ++$rollback_count{'6'};
                } elsif ($transaction eq '7R') {
                    ++$rollback_count{'7'};
                } elsif ($transaction eq '8R') {
                    ++$rollback_count{'8'};
                } elsif ($transaction eq '9R') {
                    ++$rollback_count{'9'};
                } elsif ($transaction eq '10R') {
                    ++$rollback_count{'10'};
                } elsif ($transaction eq 'E') {
                    ++$self->{data}->{errors};
                    ++$error_count{$transaction};
                } else {
                    print "error with mix.log format\n";
                    exit(1);
                }
                if ($transaction ne '10' and $transaction ne '10R' and
                        $transaction ne 'E') {
                    ++$total_transaction_count;
                }
            }
        } elsif (scalar(@word) == 2) {
            #
            # Look for that 'START' marker to determine the end of the rampup
            # time and to calculate the average throughput from that point to
            # the end of the test.
            #
            $self->{data}->{steady_state_start_time} = $word[0];
        }
    }
    close(FILE);
    #
    # Calculated the number of Trade Result transactions per second.
    #
    $self->{data}->{metric} = $transaction_count{'1'} /
            ($current_time - $self->{data}->{steady_state_start_time});
    $self->{data}->{duration} =
            ($current_time - $self->{data}->{steady_state_start_time}) / 60.0;
    $self->{data}->{rampup} = $self->{data}->{steady_state_start_time} -
            $self->{data}->{start_time};
    #
    # Other transaction statistics.
    #
    my %transaction;
    $transaction{'0'} = "Trade Order";
    $transaction{'1'} = "Trade Result";
    $transaction{'2'} = "Trade Lookup";
    $transaction{'3'} = "Trade Update";
    $transaction{'4'} = "Trade Status";
    $transaction{'5'} = "Customer Position";
    $transaction{'6'} = "Broker Volume";
    $transaction{'7'} = "Security Detail";
    $transaction{'8'} = "Market Feed";
    $transaction{'9'} = "Market Watch";
    $transaction{'10'} = "Data Maintenance";
    #
    # Resort numerically, default is by ascii..
    #
    @trade_order_response_time = sort { $a <=> $b } @trade_order_response_time;
    @trade_result_response_time =
            sort { $a <=> $b } @trade_result_response_time;
    @trade_lookup_response_time =
            sort { $a <=> $b } @trade_lookup_response_time;
    @trade_update_response_time =
            sort { $a <=> $b } @trade_update_response_time;
    @trade_status_response_time =
            sort { $a <=> $b } @trade_status_response_time;
    @customer_position_response_time =
            sort { $a <=> $b } @customer_position_response_time;
    @broker_volume_response_time =
            sort { $a <=> $b } @broker_volume_response_time;
    @security_detail_response_time =
            sort { $a <=> $b } @security_detail_response_time;
    @market_feed_response_time = sort { $a <=> $b } @market_feed_response_time;
    @market_watch_response_time =
            sort { $a <=> $b } @market_watch_response_time;
    @data_maintenance_response_time =
            sort { $a <=> $b } @data_maintenance_response_time;
    #
    # Get the index for the 90th percentile response time index for each
    # transaction.
    #
    my $trade_order90index = $transaction_count{'0'} * 0.90;
    my $trade_result90index = $transaction_count{'1'} * 0.90;
    my $trade_lookup90index = $transaction_count{'2'} * 0.90;
    my $trade_update90index = $transaction_count{'3'} * 0.90;
    my $trade_status90index = $transaction_count{'4'} * 0.90;
    my $customer_position90index = $transaction_count{'5'} * 0.90;
    my $broker_volume90index = $transaction_count{'6'} * 0.90;
    my $security_detail90index = $transaction_count{'7'} * 0.90;
    my $market_feed90index = $transaction_count{'8'} * 0.90;
    my $market_watch90index = $transaction_count{'9'} * 0.90;
    my $data_maintenance90index = $transaction_count{'10'} * 0.90;

    my %response90th;

    #
    # 90th percentile calculations.
    #
    $response90th{'0'} = $self->get_90th_per($trade_order90index,
            @trade_order_response_time);
    $response90th{'1'} = $self->get_90th_per($trade_result90index,
            @trade_result_response_time);
    $response90th{'2'} = $self->get_90th_per($trade_lookup90index,
            @trade_lookup_response_time);
    $response90th{'3'} = $self->get_90th_per($trade_update90index,
            @trade_update_response_time);
    $response90th{'4'} = $self->get_90th_per($trade_status90index,
            @trade_status_response_time);
    $response90th{'5'} = $self->get_90th_per($customer_position90index,
            @customer_position_response_time);
    $response90th{'6'} = $self->get_90th_per($broker_volume90index,
            @broker_volume_response_time);
    $response90th{'7'} = $self->get_90th_per($security_detail90index,
            @security_detail_response_time);
    $response90th{'8'} = $self->get_90th_per($market_feed90index,
            @market_feed_response_time);
    $response90th{'9'} = $self->get_90th_per($market_watch90index,
            @market_watch_response_time);
    $response90th{'10'} = $self->get_90th_per($data_maintenance90index,
            @data_maintenance_response_time);
    #
    # Summarize the transaction statistics into the hash structure for XML.
    #
    $self->{data}->{transactions}->{transaction} = [];
    foreach my $idx ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10') {
        # Yes, $mix is not valid for Data Maintenance ($idx == '10').
        my $mix = ($transaction_count{$idx} + $rollback_count{$idx}) /
                $total_transaction_count * 100.0;
        my $rt_avg = 0;
        if ($transaction_count{$idx} != 0) {
            $rt_avg = $transaction_response_time{$idx} /
                    $transaction_count{$idx};
        }
        my $txn_total = $transaction_count{$idx} + $rollback_count{$idx};
        my $rollback_per;
        if ($txn_total ne 0) {
            $rollback_per = $rollback_count{$idx} / $txn_total * 100.0;
        } else {
            $rollback_per = 0;
        }
        push @{$self->{data}->{transactions}->{transaction}},
                {mix => $mix,
                rt_avg => $rt_avg,
                rt_90th => $response90th{$idx},
                total => $txn_total,
                rollbacks => $rollback_count{$idx},
                rollback_per => $rollback_per,
                name => $transaction{$idx}};
    }
}

sub parse_readme {
    my $self = shift;
    my $filename = shift;

    open(FILE, "< $filename");
    my $line = <FILE>;
    chomp($line);
    $self->{data}->{date} = $line;

    $line = <FILE>;
    chomp($line);
    $self->{data}->{comment} = $line;

    $line = <FILE>;
    my @i = split / /, $line;
    $self->{data}->{os}{name} = $i[0];
    $self->{data}->{os}{version} = $i[2];

    $self->{data}->{cmdline} = <FILE>;
    chomp($self->{data}->{cmdline});

    $line = <FILE>;
    my @data = split /:/, $line;
    $data[1] =~ s/^\s+//;
    @data = split / /, $data[1];
    $self->{data}->{scale_factor} = $data[0];

    close(FILE);
}

sub parse_iostat {
    my $self = shift;
    my $file = shift;
    my $dir = shift;
    my $system = shift;

    if (-f $file) {
        system "mkdir -p $dir";
        my $iostat = new Test::Parser::Iostat;
        $iostat->outdir($dir);
        $iostat->parse($file);
        my $d = $iostat->data();
        for my $k (keys %$d) {
            $self->{data}->{system}->{$system}->{iostat}->{$k} = $d->{$k};
        }
    }
}

sub parse_sar {
    my $self = shift;
    my $file = shift;
    my $dir = shift;
    my $system = shift;

    my $sar = {};
    if (-f $file) {
        system "mkdir -p $dir";
        my $sar = new Test::Parser::Sar;
        $sar->outdir($dir);
        $sar->parse($file);
        my $d = $sar->data();
        for my $k (keys %$d) {
            $self->{data}->{system}->{$system}->{sar}->{$k} = $d->{$k};
        }
    }
}

sub parse_vmstat {
    my $self = shift;
    my $file = shift;
    my $dir = shift;
    my $system = shift;

    if (-f $file) {
        system "mkdir -p $dir";
        my $vmstat = new Test::Parser::Vmstat;
        $vmstat->outdir($dir);
        $vmstat->parse($file);
        my $d = $vmstat->data();
        for my $k (keys %$d) {
            $self->{data}->{system}->{$system}->{vmstat}->{$k} = $d->{$k};
        }
    }
}

=head3 to_xml()

Returns sar data transformed into XML.

=cut
sub to_xml {
    my $self = shift;
    return XMLout({%{$self->{data}}}, RootName => 'dbt5',
            OutputFile => "$self->{outdir}/result.xml");
}

sub rampup {
    my $self = shift;
    return $self->{data}->{rampup};
}

sub transactions {
    my $self = shift;
    return @{$self->{data}->{transactions}->{transaction}};
}

sub get_90th_per {
    my $self = shift;
    my $index = shift;
    my @data = @_;

    my $result;
    my $floor = floor($index);
    my $ceil = ceil($index);
    if ($floor == $ceil) {
        $result = $data[$index];
    } else {
        if ($data[$ceil]) {
            $result = ($data[$floor] + $data[$ceil]) / 2;
        } else {
            $result = $data[$floor];
        }
    }
    return $result;
}

1;
__END__

=head1 AUTHOR

Mark Wong <markwkm@gmail.com>
 
=head1 COPYRIGHT

Copyright (C) 2006-2008 Mark Wong & Open Source Development Labs, Inc.
All Rights Reserved.

Copyright (C) 2006 Rilson Nascimento
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

