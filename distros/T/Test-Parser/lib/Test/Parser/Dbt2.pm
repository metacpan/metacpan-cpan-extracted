package Test::Parser::Dbt2;

=head1 NAME

Test::Parser::Dbt2 - Perl module to parse output files from a DBT-2 test run.

=head1 SYNOPSIS

 use Test::Parser::Dbt2;

 my $parser = new Test::Parser::Dbt2;
 $parser->parse($text);

=head1 DESCRIPTION

This module transforms DBT-2 output into a hash that can be used to generate
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

@Test::Parser::Dbt2::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              data
              sample_length
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::Dbt2 instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::Dbt2 $self = fields::new($class);
    $self->SUPER::new();

    $self->name('dbt2');
    $self->type('standards');

    $self->{data} = {};
    $self->{sample_length} = 60; # Seconds.

    return $self;
}

=head3 data()

Returns a hash representation of the dbt2 data.

=cut
sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = @_;
    }
    return {dbt2 => $self->{data}};
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
to parse dbt2 output.  Support only reading from a file until a better
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
    # Put everything into a report directory under the specified DBT-2 output
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

    my @delivery_response_time = ();
    my @new_order_response_time = ();
    my @order_status_response_time = ();
    my @payement_response_time = ();
    my @stock_level_response_time = ();
    #
    # Zero out the data.
    #
    $rollback_count{ 'd' } = 0;
    $rollback_count{ 'n' } = 0;
    $rollback_count{ 'o' } = 0;
    $rollback_count{ 'p' } = 0;
    $rollback_count{ 's' } = 0;
    #
    # Transaction counts for the steady state portion of the test.
    #
    $transaction_count{ 'd' } = 0;
    $transaction_count{ 'n' } = 0;
    $transaction_count{ 'o' } = 0;
    $transaction_count{ 'p' } = 0;
    $transaction_count{ 's' } = 0;

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
                if ($transaction eq 'd') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @delivery_response_time, $response_time;
                } elsif ($transaction eq 'n') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @new_order_response_time, $response_time;
                } elsif ($transaction eq 'o') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @order_status_response_time, $response_time;
                } elsif ($transaction eq 'p') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @payement_response_time, $response_time;
                } elsif ($transaction eq 's') {
                    ++$transaction_count{$transaction};
                    $transaction_response_time{$transaction} += $response_time;
                    push @stock_level_response_time, $response_time;
                } elsif ($transaction eq 'D') {
                    ++$rollback_count{'d'};
                } elsif ($transaction eq 'N') {
                    ++$rollback_count{'n'};
                } elsif ($transaction eq 'O') {
                    ++$rollback_count{'o'};
                } elsif ($transaction eq 'P') {
                    ++$rollback_count{'p'};
                } elsif ($transaction eq 'S') {
                    ++$rollback_count{'s'};
                } elsif ($transaction eq 'E') {
                    ++$self->{data}->{errors};
                    ++$error_count{$transaction};
                } else {
                    print "error with mix.log format\n";
                    exit(1);
                }
                ++$total_transaction_count;
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
    # Calculated the number of New Order transactions per second.
    #
    my $tps = $transaction_count{'n'} /
            ($current_time - $self->{data}->{steady_state_start_time});
    $self->{data}->{metric} = $tps * 60.0;
    $self->{data}->{duration} =
            ($current_time - $self->{data}->{steady_state_start_time}) / 60.0;
    $self->{data}->{rampup} = $self->{data}->{steady_state_start_time} -
            $self->{data}->{start_time};
    #
    # Other transaction statistics.
    #
    my %transaction;
    $transaction{'d'} = "Delivery";
    $transaction{'n'} = "New Order";
    $transaction{'o'} = "Order Status";
    $transaction{'p'} = "Payment";
    $transaction{'s'} = "Stock Level";
    #
    # Resort numerically, default is by ascii..
    #
    @delivery_response_time = sort { $a <=> $b } @delivery_response_time;
    @new_order_response_time = sort{ $a <=> $b }  @new_order_response_time;
    @order_status_response_time =
        sort { $a <=> $b } @order_status_response_time;
    @payement_response_time = sort { $a <=> $b } @payement_response_time;
    @stock_level_response_time = sort { $a <=> $b } @stock_level_response_time;
    #
    # Get the index for the 90th percentile response time index for each
    # transaction.
    #
    my $delivery90index = $transaction_count{'d'} * 0.90;
    my $new_order90index = $transaction_count{'n'} * 0.90;
    my $order_status90index = $transaction_count{'o'} * 0.90;
    my $payment90index = $transaction_count{'p'} * 0.90;
    my $stock_level90index = $transaction_count{'s'} * 0.90;

    my %response90th;

    #
    # 90th percentile for Delivery transactions.
    #
    $response90th{'d'} = $self->get_90th_per($delivery90index,
            @delivery_response_time);
    $response90th{'n'} = $self->get_90th_per($new_order90index,
            @new_order_response_time);
    $response90th{'o'} = $self->get_90th_per($order_status90index,
            @order_status_response_time);
    $response90th{'p'} = $self->get_90th_per($payment90index,
            @payement_response_time);
    $response90th{'s'} = $self->get_90th_per($stock_level90index,
            @stock_level_response_time);
    #
    # Summarize the transaction statistics into the hash structure for XML.
    #
    $self->{data}->{transactions}->{transaction} = [];
    foreach my $idx ('d', 'n', 'o', 'p', 's') {
        my $mix = ($transaction_count{$idx} + $rollback_count{$idx}) /
                $total_transaction_count * 100.0;
        my $rt_avg = 0;
        if ($transaction_count{$idx} != 0) {
            $rt_avg = $transaction_response_time{$idx} /
                    $transaction_count{$idx};
        }
        my $txn_total = $transaction_count{$idx} + $rollback_count{$idx};
        my $rollback_per = $rollback_count{$idx} / $txn_total * 100.0;
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
    return XMLout({%{$self->{data}}}, RootName => 'dbt2',
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
 
September 2006
- response time sort to use numeric sort not ascii
- 90th percentile sort to use numeric sort
Richard Kennedy EnterpriseDB

=head1 COPYRIGHT

Copyright (C) 2006-2008 Mark Wong & Open Source Development Labs, Inc.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

