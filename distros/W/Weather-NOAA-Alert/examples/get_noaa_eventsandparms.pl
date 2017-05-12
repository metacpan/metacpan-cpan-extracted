use strict;

#use lib '../Weather-NOAA-Alert/lib';
use Weather::NOAA::Alert;

use POSIX qw(strftime);

use Data::Dumper;

our $VERSION = '2.01';

#Pulls the latest National Weather Service ATOM and CAP alerts for the 
#entire country preparing a cross reference of event types to parameters.
#Was inspired by the need to determine how NOAA assigns cap:urgency to 
#the event types.  NOAA doesn't provide a cross reference.
#http://alerts.weather.gov/cap/us.atom
#http://alerts.weather.gov/cap/wwacapget.php?x=CO20110424120100WinterStormWarning20110425120000CO.GJTWSWGJT.790bacf3c14f2dc0e2d5149cf668f95c

#Remembers past events in a data structure hash consisting of:
# {zone}->{CAP id}->{'delete'}
#                 ->{'actionTime'}
#                 ->{'event'}
#                 ->{'certainty'}
#                 ->{'senderName'}
#                 ->{'urgency'}
#                 ->{'instruction'}
#                 ->{'description'}
#                 ->{'category'}
#                 ->{'severity'}
#                 ->{'effective'}
#                 ->{'headline'}
#                 ->{'expires'}


#Generates parameter tracking for the following parameters:
#                 ->{'event'}
#                 ->{'certainty'}
#                 ->{'urgency'}
#                 ->{'category'}
#                 ->{'severity'}


#Data Structures:
#   Parameters by Event
#       $paramByEvent{'Tornado Warning'}->{'Urgency'}->{'Immediate'} = $date
#       List out the urgencies (or other param) seen for each event name
#       List out the events with more than one value for a parameter
#   Events by Parameter
#       $eventByParam{'Urgency'}->{'Immediate'}->{'Tornado Warning'} = $date
#       Can list the events assigned to each urgency or other parameter


#Output:
#   Dump of both structures in a fixed width table to files


#Urgency:
#   Immediate - Warning
#   Expected - Advisory, Warning, Statement
#   Future - Watch
#   Unknown - Forecast


#Main loop control variables
my $SLEEP_SECS = 1800;   #Poll every 30 minutes
my @zones = (
#'TXZ104',    #Collin County
#'TXC085',    #Collin County
'US',    #All US events
);

#Global data structures
our (%paramByEvent, %eventByParam);

#Initialize the paramByEvent and eventByParam structures from files
readParams();
#print Dumper(\%paramByEvent, \%eventByParam);

#Create a NOAA Alert Object, configure it, and get a reference to the events hash
our $alert = Weather::NOAA::Alert->new(\@zones);
$alert->printLog(1);
$alert->printActions(1);
$alert->errorLog(1);
our $events = $alert->get_events();


#Processing Loop
$| = 1;  #Turn off STDOUT buffering
while (1) {
    my ($errorCount, $eventCount, $addCount, $deleteCount) 
            = $alert->poll_events();
    if( $errorCount) {
        #Play($voice, "sounds/Windows XP Balloon.wav");
        print "$errorCount errors encountered!\n";
    }
    
    
    populateParams();
    
#    print Dumper(\%paramByEvent, \%eventByParam);
    
    writeParams();
    
    
    my $eventCount2 = 0;
    foreach my $zone (keys(%{$events})) {
        foreach my $event (keys(%{$events->{$zone}})) {
            $eventCount2++;
        }
    }
    if( $eventCount2 != $eventCount) {
        print "Error:: ATOM file events ($eventCount) do not match tracked events ($eventCount2)\n";
    }
    print "Tracking $eventCount2 " . ($eventCount2 == 1 ? "event" : "events");
    print "   $addCount added, $deleteCount deleted\n";
    print "Sleeping $SLEEP_SECS seconds at ";
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    printf( "%4d-%02d-%02d %02d:%02d:%02d\n-----------------\n\n",
            $year+1900,$mon+1,$mday,$hour,$min,$sec);
    sleep($SLEEP_SECS);
    
} #while (1)

sub readParams {
    my $header;
    my $path = 'paramByEvent.txt';
    if( open(PARAMBYEVENT, "< $path")) {
        #Skip over the header
        $header = <PARAMBYEVENT>;
        while( <PARAMBYEVENT>) {
            chomp;  #remove the line terminator
            my ($event,$param,$value,$date) = /^(.{30}) (.{20}) (.{20}) (.+)/;
            #remove trailing spaces
            $event =~ s/\s+$//;
            $param =~ s/\s+$//;
            $value =~ s/\s+$//;
            $paramByEvent{$event}{$param}{$value} = $date;
        }
        close(PARAMBYEVENT);
    }

    $path = 'eventByParam.txt';
    if( open(EVENTBYPARAM, "< $path")) {
        #Skip over the header
        $header = <EVENTBYPARAM>;
        while( <EVENTBYPARAM>) {
            chomp;  #remove the line terminator
            my ($param,$value,$event,$date) = /^(.{20}) (.{20}) (.{30}) (.+)/;
            #remove trailing spaces
            $event =~ s/\s+$//;
            $param =~ s/\s+$//;
            $value =~ s/\s+$//;
            $eventByParam{$param}{$value}{$event} = $date;
        }
        close(EVENTBYPARAM);
    }
}

sub writeParams {
    
    my $path = 'paramByEvent.txt';
    #Overwrites previous version
    open(PARAMBYEVENT, "> $path") or die "Couldn't open $path for writing: $!\n";
#Output Format for $paramByEvent{'Tornado Warning'}->{'Urgency'}->{'Immediate'}
#Event                         Parameter           Value               Date
#Tornado Warning               Urgency             Immediate           2009-04-09 18:29:34
    printf(PARAMBYEVENT "%-30s %-20s %-20s %s\n", 'Event','Parameter','Value','Date Last Seen');
    foreach my $event (sort(keys(%paramByEvent))) {
        foreach my $param (sort(keys( %{$paramByEvent{$event}})) ) {
            foreach my $value (sort(keys( %{$paramByEvent{$event}{$param}})) ) {
                printf(PARAMBYEVENT "%-30s %-20s %-20s %s\n",
                        $event, $param, $value, 
                        $paramByEvent{$event}{$param}{$value}
                        );
            }
        }
    }
    close(PARAMBYEVENT);

    $path = 'eventByParam.txt';
    open(EVENTBYPARAM, "> $path") or die "Couldn't open $path for writing: $!\n";
#Output Format for $eventByParam{'Urgency'}->{'Immediate'}->{'Tornado Warning'}
#Parameter           Value               Event                         Date
#Urgency             Immediate           Tornado Warning               2009-04-09 18:29:34
    printf(EVENTBYPARAM "%-20s %-20s %-30s %s\n", 'Parameter','Value','Event','Date Last Seen');
    foreach my $param (sort(keys(%eventByParam))) {
        foreach my $value (sort(keys( %{$eventByParam{$param}})) ) {
            foreach my $event (sort(keys( %{$eventByParam{$param}{$value}})) ) {
                printf(EVENTBYPARAM "%-20s %-20s %-30s %s\n",
                        $param, $value, $event, 
                        $eventByParam{$param}{$value}{$event}
                        );
            }
        }
    }
    close(EVENTBYPARAM);
}

sub populateParams {
    
    #Generate a date for first occurance  2009-04-09 18:10:32
    my $date = strftime("%Y-%m-%d %H:%M:%S", localtime());
    
    foreach my $zone (keys(%{$events})) {
        foreach my $capId (keys( %{$events->{$zone}}) ) {
            
            #$events{$zone}{$capId}{'certainty'}
            #$paramByEvent{'Tornado Warning'}->{'Urgency'}->{'Immediate'}
            #$eventByParam{'Urgency'}->{'Immediate'}->{'Tornado Warning'}
            
            my $event = $events->{$zone}{$capId}{'event'};
            if($event eq '') {
                #Event might be blank!!  It's happened.
                print "Event is blank: $capId\n";
                print Dumper($events->{$zone}{$capId}) . "\n";
                next;
            }
            
            my $certainty = $events->{$zone}{$capId}{'certainty'};
            my $urgency = $events->{$zone}{$capId}{'urgency'};
            my $category = $events->{$zone}{$capId}{'category'};
            my $severity = $events->{$zone}{$capId}{'severity'};
            
            $certainty = $certainty eq '' ? 'NULL' : $certainty;
            $urgency = $urgency eq '' ? 'NULL' : $urgency;
            $category = $category eq '' ? 'NULL' : $category;
            $severity = $severity eq '' ? 'NULL' : $severity;
            
            $paramByEvent{$event}{'certainty'}{$certainty} = $date;
            $paramByEvent{$event}{'urgency'}{$urgency} = $date;
            $paramByEvent{$event}{'category'}{$category} = $date;
            $paramByEvent{$event}{'severity'}{$severity} = $date;
            
            $eventByParam{'certainty'}{$certainty}{$event} = $date;
            $eventByParam{'urgency'}{$urgency}{$event} = $date;
            $eventByParam{'category'}{$category}{$event} = $date;
            $eventByParam{'severity'}{$severity}{$event} = $date;
        }
    }
}
