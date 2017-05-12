# Copyright (c) 1999-2000 João Pedro Gonçalves <joaop@sl.pt>.
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package GPS::NMEA;

use GPS::Base ();
use GPS::Serial ();
use GPS::NMEA::Handler ();

use strict;
use Carp;
use vars qw($VERSION @ISA);

require Exporter;

@ISA = qw(GPS::Base GPS::Serial GPS::NMEA::Handler);

$VERSION = 1.12;

use FileHandle;

sub new {
    my $class = shift;
    my %param = @_;
    $param{'Protocol'} ||= 'NMEA';

    my $self = $class->SUPER::common_new(%param);
    bless $self, $class;

    $self;
}

sub parse {
    my $self = shift;
    my $line = $self->_readline; #from GPS::Serial
    while () {
	my $short_cmd = $self->parse_line($line);
	return $short_cmd if defined $short_cmd;
    }
}

sub parse_line {
    my($self, $line) = @_;
    my ($csum,$cmd,$short_cmd);

    #remove trailing chars
    chomp($line);$line =~ s/\r//g;

    #Test checksum
    if ($line =~  s/\*(\w\w)$//) {
	$csum = $1;
	#XXX del? return $self->parse(@_) unless $csum eq $self->checksum($line);
	return undef unless $csum eq $self->checksum($line);
    }

    $cmd = (split ',',$line)[0];
    ($short_cmd = $cmd) =~ s/^\$//;

    print "COMMAND: $short_cmd ($line)\n" if $self->verbose;
    if ($self->can($short_cmd)) {
	$self->$short_cmd($line);
    } elsif ($self->verbose) {
	print "Can't handle $short_cmd\n";
    } 
    $short_cmd;
}


sub get_position {
    #($latsign,$lat,$lonsign,$lon)
    my $self = shift;

    until ($self->parse eq 'GPRMC') {
	1;
    }
    ;				#Recommended minimum specific
    my $d = $self->{NMEADATA};
    return ($d->{lat_NS},
	    $self->parse_ddmm_coords($d->{lat_ddmm}),
	    $d->{lon_EW},
	    $self->parse_ddmm_coords($d->{lon_ddmm}));
}

sub get_altitude {
    my $self = shift;
    until ($self->parse eq 'PGRMZ') {
	1;
    }
    ;				#Altitude
    my $d = $self->{NMEADATA};
    return ($d->{alt}/0.3048);	#Metric
}

sub parse_ddmm_coords {
    my $self = shift;
    $_ = shift;
    my $deg;
    my ($dm,$sec) = split(/\./);

    if (length($dm) == 4) {	#Lat (ddmm)
	$deg = substr($dm,0,2,'');
    } elsif (length($dm) == 5) { #Lon (dddmm)
	$deg = substr($dm,0,3,'');

    } else {
	carp "Invalid coords\n";
    }

    $deg = sprintf("%d",$deg);
    return "$deg.$dm$sec";
}



sub nmea_data_dump {
    #dumps data received
    my $self = shift;
    my $d = $self->{NMEADATA};
    print map {"$_ => $$d{$_}\n"} sort keys %{$self->{NMEADATA}};
}

# Calculate the checksum
#
sub checksum {
    my ($self,$line) = @_;
    my $csum = 0;
    $csum ^= unpack("C",(substr($line,$_,1))) for(1..length($line)-1);

    print "Checksum: $csum\n" if $self->verbose;
    return (sprintf("%2.2X",$csum));
}



1;
__END__

=head1 NAME

GPS::NMEA - Perl interface to GPS equipment using the NMEA Protocol

=head1 SYNOPSIS

  use GPS::NMEA;
  $gps = new GPS::NMEA(  'Port'      => '/dev/ttyS0',
	  		 'Baud'      => 9600,
                );


=head1 DESCRIPTION

GPS::NMEA allows the connection and use of of a GPS receiver in perl scripts.

Note that latitudes and longitudes are in DMM format.

=over

=head1 GETTING STARTED


=head1 KNOWN LIMITATIONS


=head1 BUGS


=head1 EXAMPLES

Get the position periodically:

    #!/usr/bin/perl
    use GPS::NMEA;
    
    my $gps = GPS::NMEA->new(Port => '/dev/cuaa0', # or COM5: or /dev/ttyS0
    			     Baud => 4800);
    while(1) {
        my($ns,$lat,$ew,$lon) = $gps->get_position;
        print "($ns,$lat,$ew,$lon)\n";
    }

Get the internal NMEA dump:

    #!/usr/bin/perl
    use GPS::NMEA;
    use Data::Dumper;
    
    my $gps = GPS::NMEA->new(Port => '/dev/cuaa0', # or COM5: or /dev/ttyS0
    			     Baud => 4800);
    while(1) {
        $gps->parse;
    
	# Dump internal NMEA data:
        $gps->nmea_data_dump;
    
        # Alternative to look at the internal NMEA data:
        require Data::Dumper;
        print Data::Dumper->new([$gps->{NMEADATA}],[])->Indent(1)->Useqq(1)->Dump;
    }
    __END__

=head1 AUTHOR

Joao Pedro B Gonçalves , joaop@iscsp.utl.pt

=head1 SEE ALSO

=cut
