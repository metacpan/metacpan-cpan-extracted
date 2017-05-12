#!/usr/local/bin/perl
use Tk;
use Tk::ExecuteCommand;
use subs qw/ init main read_acs sys /;
use strict;
use warnings;

# Globals.

my $ec;                                 # ExecuteCommand widget
my @gauges;			        # list of AC NGauge widgets
my $interval;                           # interval between SNMP scans, seconds
my $mw;				        # MainWindow
my $snmp_liebert_temperature_actual;    # temperature, actual reading
my $snmp_liebert_temperature_tolerance; # temperature, desired tolerance
my $snmp_liebert_temperature_setting;   # temperature, desired setting
my $snmp_root;                          # snmpget/snmpset dirname
my $temp_tolerance_factor;	        # tolerance value * factor = degrees

init;
main;

sub init {

    $mw = MainWindow->new;
    $ec = $mw->ExecuteCommand;

    $interval = 2;

    $snmp_root = '/usr/bin';
    $snmp_liebert_temperature_setting   = '.1.3.6.1.4.1.476.1.42.3.4.1.2.1.0';
    $snmp_liebert_temperature_tolerance = '.1.3.6.1.4.1.476.1.42.3.4.1.2.2.0';
    $snmp_liebert_temperature_actual    = '.1.3.6.1.4.1.476.1.42.3.4.1.2.3.1.3.1';

    $gauges[0] = {-ac => 'some-ip-1'};
    $gauges[1] = {-ac => 'some-ip-2'};

} # end init

sub main {

    read_acs;
    MainLoop;

} # end main

sub read_acs {

    my( $stat, @temperature, @humidity );

    foreach my $g ( @gauges ) {
	my $ac_ip = $g->{ -ac } . '.some.domain.name';
	
	( $stat, @temperature ) = sys "$snmp_root/snmpget $ac_ip communityname  $snmp_liebert_temperature_setting $snmp_liebert_temperature_tolerance $snmp_liebert_temperature_actual";
	die "Cannot get temperature data for AC '$ac_ip': $stat." if $stat or $#temperature != 2;
	print "stat=$stat, data=@temperature.\n";

    } # forend all air conditioners

    $mw->after( $interval * 1000 => \&read_acs );

} # end read_acs

sub sys {

    # Execute a command asynchronously and return its status and output.

    my $cmd = shift;
    
    $ec->configure( -command => $cmd );
    my $t = $ec->Subwidget( 'text' ); # ROText widget
    $t->delete( '1.0' => 'end' );
    $ec->execute_command;
    return ($ec->get_status)[0], split /\n/, $t->get( '1.0' => 'end -1 chars' );

} # end sys
