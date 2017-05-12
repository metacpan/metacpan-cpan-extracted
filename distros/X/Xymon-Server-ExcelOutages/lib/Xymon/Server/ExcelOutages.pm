package Xymon::Server::ExcelOutages;
use Xymon::Server::History;
use Xymon::DB::Schema;
use Data::Dumper;
use Spreadsheet::WriteExcel;
use Time::Business;

use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $workbook @sheet);
    $VERSION     = '0.03';
    @ISA         = qw(Exporter);
    
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

sub new
{
    my ($class, $parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);
	
	$self->{db} = Xymon::DB::Schema->connect( 
				$parameters->{DBCONNECT}, $parameters->{DBUSER}, $parameters->{DBPASSWD}, 
				{PrintError => 0}
			);
	
	
	foreach my $parm ( %$parameters ) {
		$self->{$parm} = $parameters->{$parm};
	}	
	
	
	$self->{EXCELFILE} = $parameters->{EXCELFILE} || '/home/hobbit/server/www/weeklyexcel.xls';
	
			
	unless ($self->{db}) {
    	die "Unable to connect to server $DBI::errstr";
	}
	
	#
	# Get Hosts to use in report.
	#
	$self->{hosts} = $self->{db}->resultset('host')->search(
			-and => [
			
				hobbit=>1,
				recordstatus=>'Complete',
			
				-or => [
					serviceclass => 'Production',
					assettype => 'Router',
				]		
			
			])->hashref_pk;
	
	my $servers=[];
	foreach my $host ( keys %{$self->{hosts}}) {
		push @$servers, $self->{hosts}->{$host}->{hostname};
	}
		
		
		
	$self->{history} = bless ({},ref ('Xymon::Server::History'));	
	
	#
	# use Xymon::Server::History to retrieve the events.
	#
	$self->{history} = Xymon::Server::History->new({
			SERVERS => $servers,
			TESTS => $parameters->{TESTS},
			HOME=>$parameters->{HOME},
			WORKDAYS  => $parameters->{WORKDAYS},
			STARTTIME => $parameters->{STARTTIME},
			ENDTIME   => $parameters->{ENDTIME},
			RANGESTART => $parameters->{RANGESTART},
			RANGEND => $parameters->{RANGEEND},
			MINSECS => $parameters->{MINSECS},
			
			
	});
	
		
    return $self;
}
#
#
#

sub create {
	
	my $self = shift;
	setup_sheet($self);
	$sheet[0]->autofilter( "A4:I4" );
	$sheet[1]->autofilter( "A4:I4" );
    $sheet[2]->autofilter( "A4:H4" );
    
    my $sheet0_row=4;
    my $sheet1_row=4;
	my $sheet2_row=4;
	#
	# Retrieve the outages
	#
	my $data = [
		['Hostname'],
		['Minutes']
	];
	my $outages = $self->{history}->outagelist();
	my $serverconn;
	foreach my $key (sort {$outages->{$a}->{starttime} <=> $outages->{$b}->{starttime}} keys %$outages) {
		
		
		
		if($outages->{$key}->{bussecs}>$self->{MINSECS} ) {
			
			write_row($self,{ sheet => 0,	outage => $outages->{$key},row=>$sheet0_row});
			$sheet0_row++;

			if($outages->{$key}->{test} eq 'conn' ) {
				write_row($self,{ sheet => 2,	outage => $outages->{$key},row=>$sheet2_row});
				$sheet2_row++;
				
				$serverconn->{$outages->{$key}->{server}} = $serverconn->{$outages->{$key}->{server}} + $outages->{$key}->{bussecs};
			}
		};
		
		write_row($self,{ sheet => 1,	outage => $outages->{$key},row=>$sheet1_row});
		$sheet1_row++;
	}
	
	#
	# Add business outages graph
	#
	
	
	my $business = new Time::Business {			
					STARTTIME=>"9:00",
					ENDTIME=>"17:00",
					WORKDAYS=>[1,2,3,4,5],};
					
	# Calculate business hours in duration of report
	my $bussecs = 	$business->duration($self->{RANGESTART}, $self->{RANGEEND});
	
	foreach my $key ( sort {$serverconn->{$b}<=>$serverconn->{$a} } keys %$serverconn ) {
		push @{$data->[0]}, $key;
		push @{$data->[1]}, ($serverconn->{$key}/$bussecs)*100;
	}
	
	my $chart= $workbook ->add_chart( type => 'column', embedded => 1 );
	
	my $rows = @{$data->[0]};
	
	$chart->add_series(
        name       => 'Uncontactable %Business Seconds',
        categories => '=Graph!$A$'. 2 . ':$A$'. $rows,
        values     => '=Graph!$B$'. 2 . ':$B$'. $rows,
    );
    
    $chart->set_y_axis(name=>'Business Hours %');
    $chart->set_title ( name => '% Business Hours Downtime' );
    
	my $ferrari = $workbook->set_custom_color(40, 216, 12, 12);
	$sheet[3]->write('A1',$data);
	#$sheet[3]->set_column('A:A', 535);
	$sheet[3]->insert_chart( 'A1', $chart,0,0,2.0,2.0 );
	
	
	$workbook->close();
	if(!defined $self->{HTTP} ) {
		`uuencode $self->{EXCELFILE} outages.xls | mail David.Peters\@industry.nsw.gov.au`;
	}
	
	
	
	return 1;
	
}

sub setup_sheet {
	
	my $self = shift;
	
	my $busdescr = "$self->{STARTTIME} - $self->{ENDTIME}";
	$busdescr =~ s/\:/\./g;
	
	$workbook = Spreadsheet::WriteExcel->new($self->{EXCELFILE});
	@sheet = ();
	$sheet[0] = $workbook->add_worksheet($busdescr);
	$sheet[1]= $workbook->add_worksheet("24 x 7");
	$sheet[2] = $workbook->add_worksheet("Outage Report");
	$sheet[3] = $workbook->add_worksheet("Graph");
	
	my $format = $workbook->add_format();
	my $mformat = $workbook->add_format();
	my $mformat_cheader = $workbook->add_format();
	my $format_cheader = $workbook->add_format();
	my $dformat = $workbook->add_format();
	$self->{format_row} = $workbook->add_format();
	$self->{date_format} = $workbook->add_format(num_format => 'ddd dd mmm yyyy hh:mm');
	$self->{date_format_date} = $workbook->add_format(num_format => 'dd/mm/yyyy');
	$self->{date_format_time} = $workbook->add_format(num_format => 'hh:mm');
	
	$format->set_bold();
	$format->set_size(15);
	$format->set_color('blue');
	$format->set_align('left');

	$format_cheader->set_bold();
	$format_cheader->set_size(11);
	$format_cheader->set_text_wrap(1);

	$mformat_cheader->set_bold();
	$mformat_cheader->set_size(11);
	$mformat_cheader->set_text_wrap(1);

	$mformat->set_size(10);
                                                                                  
	$sheet[0]->write(0, 1, "All Events $busdescr WorkDays", $format);
	$sheet[1]->write(0, 1, "All Events 24 x 7", $format);
	$sheet[2]->write(0, 1, "Actual Outages Report", $format);

	$dformat->set_bold();
	$dformat->set_size(13);
	$dformat->set_color('black');
	$dformat->set_align('left');
	
	
	$sheet[0]->write(1, 1, localtime( $self->{RANGESTART} ) . " - " . localtime($self->{RANGEEND}), $dformat);
	$sheet[1]->write(1, 1, localtime( $self->{RANGESTART} ) . " - " . localtime($self->{RANGEEND}), $dformat);

	my @header = ( "HostName", "Description", "Class", "Hobbit Test", "Start", "End",  "Work Time", "Hobbit Comment", "Service ", "Status " );
	my $header_ref = \@header;


   # Set the width of the first column in Sheet3

	for( my $i=0; $i<=1; $i++ ) {
		$sheet[$i]->set_column(0, 0, 16);  #hostname
		$sheet[$i]->set_column(1, 0, 45);  #desc
        $sheet[$i]->set_column(2, 0, 13);  #priority
        $sheet[$i]->set_column(3, 0, 12);  #test
		$sheet[$i]->set_column(4, 0, 22);  #start
		$sheet[$i]->set_column(5, 0, 22);  #end
        $sheet[$i]->set_column(6, 0, 12);  #duration	
      	$sheet[$i]->set_column(7, 0, 60);  #comment
        $sheet[$i]->set_column(8, 0, 20);  #service
        $sheet[$i]->set_column(9, 0, 10);  #status
		$sheet[$i]->write_row(3, 0, $header_ref, $format_cheader);
		$sheet[$i]->freeze_panes( 4, 1 );
#		$sheet[$i]->thaw_panes( 63.0, 19.89, 4, 1 );
	}

	# Set Sheet1 as the active worksheet
	$sheet[0]->activate();

	# The general syntax is write($row, $col, $token, $format)


	# Outage Report Tab

	my @outage_header = ( "Hostname", "Description", "Priority", "Outage Desc." , "Date", "Start Time", 
			"Business Time", "Service Affected" );

	my $outage_header_ref = \@outage_header;
	
	$sheet[2]->write_row(3, 0, $outage_header_ref, $format_cheader);
	$sheet[2]->set_column(0, 0, 20);
	$sheet[2]->set_column(1, 0, 30);
	$sheet[2]->set_column(2, 0, 18);
    $sheet[2]->set_column(3, 0, 27);
	$sheet[2]->set_column(4, 0, 27);
	$sheet[2]->set_column(5, 0, 10);
	$sheet[2]->set_column(6, 0, 8);
	$sheet[2]->set_column(7, 0, 30);
	$sheet[2]->set_row(3, 60);
	$sheet[2]->freeze_panes( 4, 0 );
	$sheet[2]->set_column( 5, 5, 0, $format, 1 );
	
	
}


sub write_row {

	
	my $self = shift;
	my $parm = shift;
	
	
	my $outage = $parm->{outage};
	
	
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($outage->{starttime});
	my $start = sprintf( "%i-%02.0i-%02iT%02i:%02i:%02i", $year+1900, $mon+1, $mday, $hour, $min, $sec );
	
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($outage->{endtime});
	my $end = sprintf( "%i-%02.0i-%02iT%02i:%02i:%02i", $year+1900, $mon+1, $mday, $hour, $min, $sec );
	 	
	 	
	$sheet[$parm->{sheet}]->write( $parm->{row}, 0, $outage->{server} );
	$sheet[$parm->{sheet}]->write( $parm->{row}, 1, $self->{hosts}->{$outage->{server}}->{description} );
    $sheet[$parm->{sheet}]->write( $parm->{row}, 2, $self->{hosts}->{$outage->{server}}->{serviceclass} );
	$sheet[$parm->{sheet}]->write( $parm->{row}, 3, $outage->{test} . " " . $outage->{comment} );
	$sheet[$parm->{sheet}]->write_date_time( $parm->{row}, 4, $start, $self->{date_format} );
	$sheet[$parm->{sheet}]->write_date_time( $parm->{row}, 5, $end, $self->{date_format} );
    $sheet[$parm->{sheet}]->write( $parm->{row}, 6, $outage->{busstring}, $self->{format_row} );
    $sheet[$parm->{sheet}]->write( $parm->{row}, 7, $outage->{reason});
	$sheet[$parm->{sheet}]->write( $parm->{row}, 8, $self->{hosts}->{$outage->{server}}->{applications} );


}


#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Xymon::Server::ExcelOutages - Produce an excel spreadsheet of outages

=head1 SYNOPSIS

  use Xymon::Server::ExcelOutages;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

