use strict;

#use lib '../Weather-NOAA-Alert/lib';
use Weather::NOAA::Alert;

use Win32::OLE;
use Win32::Sound;
use Win32::API;

use Data::Dumper;

our $VERSION = '2.10';

#V2.00 - Major rewrite to accomodate CAP 1.1 format.  Moved CAP parsing to 
# the Weather-NOAA-Alert module
#V2.10 - Add tracking for the same CAP event in multiple Zones.  The same 
# alert can show up in multiple zones when polling for ajacent zones.  For 
# example, polling for both Dallas and Collin counties in Texas might produce
# the same CAP tornado watch event.  Code will now only schedule actions for 
# the first instance.


#XXX-Add an audio test mode where the first message is always generated 
#regardless of the settings for that event type.  If there are no events then
#the generate the statement "There are no active watches or warnings".


#Actions need to be stored in an array to guarantee order
#Actions are stored in @actionQueue
#type, message
#type -> play(wav file), tts(text to speech), xAP
#message -> text to be spoken or displayed

#Actions are generated based on settings in @eventActions
#refreshSeconds, speakWithOtherEvents, playAlert

#Action Priority
#There is a need to provide various actions priority over others.  
#So an action might be play alert.wav, perform TTS on alert message, 
#then perform TTS on a special weather statement that happened to be
#issued in the same polling period, finally perform TTS on the forecast.
#That example could be as many as 4 priority queues; intro sound, 
#immediate action warnings, future action watches, informational notices.

#It looks like the cap:urgency field will work well for this.  It is hard
#to tell for sure, though, because NOAA does not provide a cross reference
#between the urgency category and the alerts.  For example from simply
#looking over the current data it appears that flood warnings are 
#"Expected" while severe thunderstorm warnings are "Immediate".  I might
#write a data coorelator that pulls the data a couple times a day and
#builds a table of values for each even type.

#Why not just build as many queues as we have urgency information??

#The code builds a queue for each urgency type encountered.  There is a 
#hard coded array of urgency types that define the order that they are 
#processed for actions.  Finally if any urgency type shows up that is not 
#in the hardcoded array, that urgency type is placed in the lowest priority
#queue called "unknown" (that is the urgency for a Short Term Forecast)


#Main loop control variables
my $SLEEP_SECS = 120;   #Poll every 2 minutes
my @zones = (
'TXZ104',    #Collin County Zone
'TXC085',    #Collin County
#'OKZ029',   #Norman, OK (Cleveland County)
#'OKZ028',   #East of Norman, OK (McClain County)
#'COZ013',    #Flattops, CO
#'TXZ119',    #Dallas County Zone
#'TXC113',    #Dallas County
#'TXZ002',    #Sherman
#'TXZ103',    #Denton
#'TXZ006',    #Hartley
#'TXZ096',    #Redriver
#'OHZ055',    #Franklin
#'NHZ012',    #Nashua, NH
);

#Global action control variables
our $REPEAT_SECS = 3600;   #Repeat alerts every hour
our @ALERT_WAV = ('','sounds/alertintro.wav', 'sounds/tornado.wav');
our %eventActions = eventActions();

#Global data structures
our %actionQueues;

#Global Voice Objects
our $waveOutGetVolume = new Win32::API (
    'winmm', 'waveOutGetVolume', ['N','P'], 'N');
our $waveOutSetVolume = new Win32::API (
    'winmm', 'waveOutSetVolume', ['N','N'], 'N');
our $voice = Init_Voice();


#Create a NOAA Alert Object, configure it, and get a reference to the events hash
our $alert = Weather::NOAA::Alert->new(\@zones);
$alert->printLog(1);
$alert->printActions(1);
$alert->errorLog(1);
#$alert->diagDump(1);
our $events = $alert->get_events();


#Processing Loop
$| = 1;  #Turn off STDOUT buffering
while (1) {
    my ($errorCount, $eventCount, $addCount, $deleteCount) 
            = $alert->poll_events();
    if( $errorCount) {
        Play($voice, "sounds/Windows XP Balloon.wav");
        print "$errorCount errors encountered!\n";
    }
    
    #XXX-OK, now we have a current list of alerts from NOAA
    #Need to loop through adding actions to the actionQueue
    #What actions to add?
    #TTS actions are easy because they are the same as before
    
    #Display actions?  What to display?  What device is the 
    #target of this display action?  For a web based device 
    #displaying all of the text is appropriate.  For an SMS 
    #or OSD device only a very short headline is appropriate 
    #(e.g. TORNADO ALERT - Take cover immediately!!)
    #Maybe this should be under the control of MH.  Then the 
    #action here is to throw an xAP EMS Alert object that MH
    #can grab and update displays as appropriate.  Also, 
    #displays that support that xAP schema can make their own
    #display decisions.
    
    #XXX-Need to define an xAP EMS Alert schema.  That's gonna hurt...
    
    #Only concentrate on generating wav and TTS events for
    #this proof of concept code.
    
    generateActions();
    
    executeActions();
    
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

sub TTSLocal {
    my ($action, $alertSounded) = @_;
    
    #if playAlertWav then play the wav file
    #speak the TTS text
    
    if( $action->{'playAlertWav'}) {
        #for higher level alerts (e.g. tornado), play no matter what
        if ( $action->{'playAlertWav'} > 1) {
            print "Playing -> " . $ALERT_WAV[$action->{'playAlertWav'}] . "\n";
            Play($voice, $ALERT_WAV[$action->{'playAlertWav'}]);
        } elsif ( not $alertSounded) {
            #Only play the announcement alert once
            print "Playing -> " . $ALERT_WAV[1] . "\n";
            Play($voice, $ALERT_WAV[1]);
        }
        $alertSounded = 1;
    }
    
    #Speak the event text
    print "Speaking -> " . $action->{'event'} . "\n" . $action->{'text'} . "\n";
    Talk($voice, $action->{'text'});
    
    return( $alertSounded);
}



sub executeActions {
    
    #Loop through the action queue processing first 'Extreme'; then 
    #'Severe'; then any other value
    
    #Loop over the 'Extreme' actionQueue entries
    #   Use shift to pull the first array item and remove it from the array
    #   Process the action item
    #Loop over the 'Severe' actionQueue entries
    #   Use shift to pull the first array item and remove it from the array
    #   Process the action item
    #Loop over all the remaining actionQueue entries
    #   Use shift to pull the first array item and remove it from the array
    #   Process the action item
    
    my $others = 0;  #sets to true for the first action
    my $alertSounded = 0;
    my $action;
    if( defined( $actionQueues{'Extreme'} )) {
        while( defined( $action = pop( @{$actionQueues{'Extreme'}} ))) {
            $others = 1 if( $others or !$action->{'includeWOthers'});
            if( $others) {
                if( $action->{'type'} eq 'TTS') {
                        $alertSounded = TTSLocal($action, $alertSounded);
                } else {
                    print "unsupported action type:" . $action->{'type'} . "\n";
                }
            }
        }
    }
    if( defined( $actionQueues{'Severe'} )) {
        while( defined( $action = pop( @{$actionQueues{'Severe'}} ))) {
            $others = 1 if( $others or !$action->{'includeWOthers'});
            if( $others) {
                if( $action->{'type'} eq 'TTS') {
                        $alertSounded = TTSLocal($action, $alertSounded);
                } else {
                    print "unsupported action type:" . $action->{'type'} . "\n";
                }
            }
        }
    }
    foreach my $severity (keys(%actionQueues)) {
        while( defined( $action = pop( @{$actionQueues{$severity}} ))) {
            $others = 1 if( $others or !$action->{'includeWOthers'});
            if( $others) {
                if( $action->{'type'} eq 'TTS') {
                        $alertSounded = TTSLocal($action, $alertSounded);
                } else {
                    print "unsupported action type:" . $action->{'type'} . "\n";
                }
            }
        }
    }
}


sub generateActions {
    
    #Loop over all zones
    #   Loop through the events hash for this zone
    #       Get repeat, speak w/others, and alert wav index from %eventActions
    #       Next if repeat interval is 0
    #       Next if already reported and < repeat interval
    #       Append to a queue based on the cap:severity
    #       Store the actionTime in %events for repeats
    #
    
    my %capIdSeen;
    foreach my $zone (keys(%{$events})) {
        foreach my $capId (keys( %{$events->{$zone}}) ) {
            
            #Get the event actions for this event type
            my ($eventRepeat, $includeWOthers, $playAlertWav);
            my $event = $events->{$zone}{$capId}{'event'};
            if($event eq '') {
                #Event might be blank!!  It's happened.
                print "Event is blank: $capId\n";
                next;
            }
            
            if(exists($eventActions{$event})) {
#eventName => [refreshSeconds, speakWithOtherEvents, playAlert, eventType]
                $eventRepeat = $eventActions{$event}[0];
                $includeWOthers = $eventActions{$event}[1];
                $playAlertWav = $eventActions{$event}[2];
            } else {
                #some suitable defaults if a new product springs to life
                #Speek the text but don't play an alert tone
                $eventRepeat = $REPEAT_SECS;
                $includeWOthers = 0;
                $playAlertWav = 0;
            }
            
            #Repeat interval of 0 means take no action, unless includeWOthers
            if( !$eventRepeat and !$includeWOthers) {
                print "Skipping -> $event\n";
                next;
            }
            
            #Check to see if the repeat interval has expired for previously
            # spoken events
            if( exists($events->{$zone}{$capId}{'actionTime'}) and 
                    ($events->{$zone}{$capId}{'actionTime'} + 
                    $eventRepeat > time)) {
                $capIdSeen{$capId} = 1;
                print "Waiting to repeat -> $event\n";
                next;
            } else {
                print "Repeating event -> $event\n";
            }
            
            #Add actions to the correct action queue
            # actionQueues{'Extreme'}->[0]->{'type'}='TTS'
            #                             ->{'includeWOthers'}=0
            #                             ->{'playAlertWav'}=2
            #                             ->{'text'}='text to speak'
            
            #                        ->[1]->{'type'}='xAPAlert'
            #                             ->{'includeWOthers'}=0
            #                             ->{'playAlertWav'}=2
            #                             ->{'capId'}=$capId
            
            #actionQueues{'unknown'}->[0]->{'type'}='TTS'
            #                            ->{'includeWOthers'}=1
            #                            ->{'playAlertWav'}=0
            #                            ->{'text'}='text to speak'
            
            #May need to add some colums to %eventActions so that different
            #  action rules can apply to TTS vs. xAPAlert
            #For now xAPAlert is not implemented
            
            my $text = $events->{$zone}{$capId}{'description'} . "\n" . 
                    $events->{$zone}{$capId}{'instruction'} . "\n";
            
            #Severity might be blank!!
            my $severity = $events->{$zone}{$capId}{'severity'};
            $severity = 'Unknown' if( $severity eq '');
            
            #Don't queue the action if this CAP id has already been
            #processed in a different zone. (e.g. same watch in two counties)
            if( !exists($capIdSeen{$capId})) {
                $capIdSeen{$capId} = 1;
                print "Queuing  -> $event\n";
                push( @{$actionQueues{$severity}},
                        {   'type' => 'TTS',
                            'includeWOthers' => $includeWOthers,
                            'playAlertWav' => $playAlertWav,
                            'event' => $event,
                            'text' => $text,
                        }
                    );
                $events->{$zone}{$capId}{'actionTime'} = time;
            } else {
                print "Skip dup -> $event\n";
            }

        } #foreach my $capId
    } #foreach my $zone
    
#    print Dumper(\%actionQueues) . "\n";
}



sub Init_Voice {
    my $voice = Win32::OLE->new("Sapi.SpVoice") or die("TTS failed");
    $voice->{Voice} = $voice->GetVoices->Item(1);
    return $voice;
}

sub Talk {
    my ($voice, $text) = @_;
    my @volumeOrig = wavVolume();
    
    wavVolume(100);
    $voice->Speak("$text",  1);
    $voice->WaitUntilDone(-1);
    wavVolume($volumeOrig[0],$volumeOrig[1]);
    return;
}

sub Play {
    my ($voice, $file) = @_;
    my @volumeOrig = wavVolume();
    
    wavVolume(15);
    Win32::Sound::Play($file);
    wavVolume($volumeOrig[0],$volumeOrig[1]);
}

sub wavVolume {
    use constant MAX_VOLUME =>  65535;
    my $ptr = pack 'L', 0;
    my $result = $waveOutGetVolume-> Call (-1, $ptr);
    my ($left, $right) = map { unpack 'S', $_ } $ptr =~ /../g;
    
    my ($to_left, $to_right);
    if (scalar @_ == 1) {
        $to_left = $to_right = shift;
    } elsif (scalar @_ == 2) {
        $to_left = shift;
        $to_right = shift;
    }

    if (defined $to_left && defined $to_right 
            && $to_left =~ /^\d+$/ && $to_right =~ /^\d+$/) {
        $to_left  = MAX_VOLUME * ($to_left / 100);
        $to_left  = MAX_VOLUME if $to_left >  MAX_VOLUME;
        $to_right = MAX_VOLUME * ($to_right / 100);
        $to_right = MAX_VOLUME if $to_right >  MAX_VOLUME;
        
        $waveOutSetVolume-> Call (-1, (($to_left << 16) + $to_right));
        $left = $to_left;
        $right = $to_right;
    }

    $left = ($left +1) / MAX_VOLUME * 100;
    $right = ($right +1) / MAX_VOLUME * 100;
    return wantarray ? ($left, $right) : ($left + $right) / 2;
}


sub eventActions {
#eventName => [refreshSeconds, speakWithOtherEvents, playAlert]
    return (
'Flash Flood Statement' => [0,0,0],
'Severe Weather Statement' => [0,0,0],
'Severe Thunderstorm Watch' => [0,0,0],
'Flash Flood Watch' => [0,0,0],
'Hurricane Watch' => [0,0,0],
'Typhoon Watch' => [0,0,0],
'Hurricane Local Statement' => [0,0,0],
'Typhoon Local Statement' => [0,0,0],
'Snow and Blowing Snow Advisory' => [0,0,0],
'Freezing Rain Advisory' => [0,0,0],
'Freezing Drizzle Advisory' => [0,0,0],
'Snow Advisory' => [0,0,0],
'Sleet Advisory' => [0,0,0],
'Winter Weather Advisory' => [0,0,0],
'Lake Effect Snow Advisory' => [0,0,0],
'Wind Chill Advisory' => [0,0,0],
'Heat Advisory' => [0,0,0],
'Urban and Small Stream Flood Advisory' => [0,0,0],
'Small Stream Flood Advisory' => [0,0,0],
'Minor Flood Advisory' => [0,0,0],
'Flood Advisory' => [0,0,0],
'High Surf Advisory' => [0,0,0],
'Blowing Snow Advisory' => [0,0,0],
'Dense Smoke Advisory' => [0,0,0],
'Small Craft Advisory' => [0,0,0],
'Dense Fog Advisory' => [0,0,0],
'Marine Weather Statement' => [0,0,0],
'Lake Wind Advisory' => [0,0,0],
'Blowing Dust Advisory' => [0,0,0],
'Frost Advisory' => [0,0,0],
'Wind Advisory' => [0,0,0],
'Ashfall Advisory' => [0,0,0],
'Freezing Fog Advisory' => [0,0,0],
'Air Stagnation Advisory' => [0,0,0],
'Tsunami Watch' => [0,0,0],
'Coastal Flood Watch' => [0,0,0],
'Lakeshore Flood Watch' => [0,0,0],
'Blizzard Watch' => [0,0,0],
'Tropical Storm Watch' => [0,0,0],
'Inland Tropical Storm Watch' => [0,0,0],
'Inland Hurricane Watch' => [0,0,0],
'Winter Storm Watch' => [0,0,0],
'Flood Watch' => [0,0,0],
'Lake Effect Snow Watch' => [0,0,0],
'High Wind Watch' => [0,0,0],
'Excessive Heat Watch' => [0,0,0],
'Wind Chill Watch' => [0,0,0],
'Freeze Watch' => [0,0,0],
'Fire Weather Watch' => [0,0,0],
'Avalanche Watch' => [0,0,0],
'Flood Statement' => [0,0,0],
'Coastal Flood Statement' => [0,0,0],
'Lakeshore Flood Statement' => [0,0,0],
'Special Weather Statement' => [0,0,0],
'Hazardous Weather Outlook' => [0,0,0],
'Brisk Wind Advisory' => [0,0,0],
'Very High Fire Danger' => [0,0,0],
'High Fire Danger' => [0,0,0],
'Flood Warning' => [0,0,0],
'Tornado Watch' => [7200,0,0],
'Short Term Forecast' => [0,1,0],

'Tornado Warning' => [3600,0,2],
'Severe Thunderstorm Warning' => [3600,0,1],
'Flash Flood Warning' => [3600,0,0],
'Tsunami Warning' => [3600,0,0],
'Inland Hurricane Warning' => [3600,0,0],
'Hurricane Force Wind Warning' => [3600,0,1],
'Hurricane Warning' => [3600,0,0],
'Typhoon Warning' => [3600,0,0],
'Blizzard Warning' => [3600,0,0],
'Ice Storm Warning' => [3600,0,0],
'Tropical Storm Warning' => [3600,0,0],
'Heavy Snow Warning' => [3600,0,0],
'Winter Storm Warning' => [3600,0,0],
'Inland Tropical Storm Warning' => [3600,0,0],
'Dust Storm Warning' => [3600,0,0],
'Storm Warning' => [3600,0,1],
'Coastal Flood Warning' => [3600,0,0],
'Lakeshore Flood Warning' => [3600,0,0],
'High Surf Warning' => [3600,0,0],
'Heavy Sleet Warning' => [3600,0,0],
'High Wind Warning' => [3600,0,1],
'Lake Effect Snow Warning' => [3600,0,0],
'Excessive Heat Warning' => [3600,0,0],
#'Freeze Warning' => [3600,0,0],
'Freeze Warning' => [0,0,0],
'Wind Chill Warning' => [3600,0,0],
'Avalanche Warning' => [3600,0,0],
#'Red Flag Warning' => [3600,0,0],
'Red Flag Warning' => [0,0,0],
'Gale Warning' => [3600,0,0],
'Special Marine Warning' => [3600,0,0],
'Heavy Freezing Spray Warning' => [3600,0,0],
'Law Enforcement Warning' => [3600,0,1],
'911 Telephone Outage' => [3600,0,1],
'Hazardous Materials Warning' => [3600,0,2],
'Nuclear Power Plant Warning' => [3600,0,2],
'Radiological Hazard Warning' => [3600,0,2],
'Civil Emergency Message' => [3600,0,2],
'Evacuation - Immediate' => [3600,0,2],
'Earthquake Warning' => [3600,0,2],
'Local Area Emergency' => [3600,0,2],
'Civil Danger Warning' => [3600,0,2],
'Fire Warning' => [3600,0,1],
'Shelter In Place Warning' => [3600,0,2],
'Volcano Warning' => [3600,0,0],
'Extreme Fire Danger' => [3600,0,0],
'Child Abduction Emergency' => [3600,0,1],
'Air Quality Alert' => [0,0,0],
    );
}


sub eventActionsV2 {
#Events should be assigned to templates.  Templates would define similar 
#actions for every event using that template.  This will make it easier
#for a user to manipulate in a UI.   There would be two forms.  One where the
#user creates and modifies templates and one where the user assignes the 
#templates.

#Eventually move the eventActions structure to a hash of hashes
#  eventActions{'Event name'} => {
#       'eventType' => 'type name',
#       'Template' => 'template name',
#       }

#eventName => [refreshSeconds, speakWithOtherEvents, playAlert, eventType]
    return (
#Forecasts
'Hazardous Weather Outlook' => [0,0,0,'forecast'],
'Short Term Forecast' => [0,1,0,'forecast'],
#Advisories
'Snow and Blowing Snow Advisory' => [0,0,0,'advisory'],
'Freezing Rain Advisory' => [0,0,0,'advisory'],
'Freezing Drizzle Advisory' => [0,0,0,'advisory'],
'Snow Advisory' => [0,0,0,'advisory'],
'Sleet Advisory' => [0,0,0,'advisory'],
'Winter Weather Advisory' => [0,0,0,'advisory'],
'Lake Effect Snow Advisory' => [0,0,0,'advisory'],
'Wind Chill Advisory' => [0,0,0,'advisory'],
'Heat Advisory' => [0,0,0,'advisory'],
'Urban and Small Stream Flood Advisory' => [0,0,0,'advisory'],
'Small Stream Flood Advisory' => [0,0,0,'advisory'],
'Minor Flood Advisory' => [0,0,0,'advisory'],
'Flood Advisory' => [0,0,0,'advisory'],
'High Surf Advisory' => [0,0,0,'advisory'],
'Blowing Snow Advisory' => [0,0,0,'advisory'],
'Dense Smoke Advisory' => [0,0,0,'advisory'],
'Small Craft Advisory' => [0,0,0,'advisory'],
'Dense Fog Advisory' => [0,0,0,'advisory'],
'Lake Wind Advisory' => [0,0,0,'advisory'],
'Blowing Dust Advisory' => [0,0,0,'advisory'],
'Frost Advisory' => [0,0,0,'advisory'],
'Wind Advisory' => [0,0,0,'advisory'],
'Ashfall Advisory' => [0,0,0,'advisory'],
'Freezing Fog Advisory' => [0,0,0,'advisory'],
'Air Stagnation Advisory' => [0,0,0,'advisory'],
'Brisk Wind Advisory' => [0,0,0,'advisory'],
'High Fire Danger' => [0,0,0,'advisory'],
#Watches
'Severe Thunderstorm Watch' => [0,0,0,'watch'],
'Flash Flood Watch' => [0,0,0,'watch'],
'Hurricane Watch' => [0,0,0,'watch'],
'Typhoon Watch' => [0,0,0,'watch'],
'Tsunami Watch' => [0,0,0,'watch'],
'Coastal Flood Watch' => [0,0,0,'watch'],
'Lakeshore Flood Watch' => [0,0,0,'watch'],
'Blizzard Watch' => [0,0,0,'watch'],
'Tropical Storm Watch' => [0,0,0,'watch'],
'Inland Tropical Storm Watch' => [0,0,0,'watch'],
'Inland Hurricane Watch' => [0,0,0,'watch'],
'Winter Storm Watch' => [0,0,0,'watch'],
'Flood Watch' => [0,0,0,'watch'],
'Lake Effect Snow Watch' => [0,0,0,'watch'],
'High Wind Watch' => [0,0,0,'watch'],
'Excessive Heat Watch' => [0,0,0,'watch'],
'Wind Chill Watch' => [0,0,0,'watch'],
'Freeze Watch' => [0,0,0,'watch'],
'Fire Weather Watch' => [0,0,0,'watch'],
'Avalanche Watch' => [0,0,0,'watch'],
'Tornado Watch' => [7200,0,0,'watch'],
'Very High Fire Danger' => [0,0,0,'watch'],
#Statements
'Flash Flood Statement' => [0,0,0,'statement'],
'Severe Weather Statement' => [0,0,0,'statement'],
'Hurricane Local Statement' => [0,0,0,'statement'],
'Typhoon Local Statement' => [0,0,0,'statement'],
'Marine Weather Statement' => [0,0,0,'statement'],
'Flood Statement' => [0,0,0,'statement'],
'Coastal Flood Statement' => [0,0,0,'statement'],
'Lakeshore Flood Statement' => [0,0,0,'statement'],
'Special Weather Statement' => [0,0,0,'statement'],
'911 Telephone Outage' => [3600,0,1,'statement'],
#Warnings
'Flood Warning' => [0,0,0,'warning'],
'Tornado Warning' => [3600,0,2,'warning'],
'Severe Thunderstorm Warning' => [3600,0,1,'warning'],
'Flash Flood Warning' => [3600,0,0,'warning'],
'Tsunami Warning' => [3600,0,0,'warning'],
'Inland Hurricane Warning' => [3600,0,0,'warning'],
'Hurricane Force Wind Warning' => [3600,0,1,'warning'],
'Hurricane Warning' => [3600,0,0,'warning'],
'Typhoon Warning' => [3600,0,0,'warning'],
'Blizzard Warning' => [3600,0,0,'warning'],
'Ice Storm Warning' => [3600,0,0,'warning'],
'Tropical Storm Warning' => [3600,0,0,'warning'],
'Heavy Snow Warning' => [3600,0,0,'warning'],
'Winter Storm Warning' => [3600,0,0,'warning'],
'Inland Tropical Storm Warning' => [3600,0,0,'warning'],
'Dust Storm Warning' => [3600,0,0,'warning'],
'Storm Warning' => [3600,0,1,'warning'],
'Coastal Flood Warning' => [3600,0,0,'warning'],
'Lakeshore Flood Warning' => [3600,0,0,'warning'],
'High Surf Warning' => [3600,0,0,'warning'],
'Heavy Sleet Warning' => [3600,0,0,'warning'],
'High Wind Warning' => [3600,0,1,'warning'],
'Lake Effect Snow Warning' => [3600,0,0,'warning'],
'Excessive Heat Warning' => [3600,0,0,'warning'],
#'Freeze Warning' => [3600,0,0,'warning'],
'Freeze Warning' => [0,0,0,'warning'],
'Wind Chill Warning' => [3600,0,0,'warning'],
'Avalanche Warning' => [3600,0,0,'warning'],
'Red Flag Warning' => [3600,0,0,'warning'],
'Gale Warning' => [3600,0,0,'warning'],
'Special Marine Warning' => [3600,0,0,'warning'],
'Heavy Freezing Spray Warning' => [3600,0,0,'warning'],
'Law Enforcement Warning' => [3600,0,1,'warning'],
'Hazardous Materials Warning' => [3600,0,2,'warning'],
'Nuclear Power Plant Warning' => [3600,0,2,'warning'],
'Radiological Hazard Warning' => [3600,0,2,'warning'],
'Earthquake Warning' => [3600,0,2,'warning'],
'Civil Danger Warning' => [3600,0,2,'warning'],
'Fire Warning' => [3600,0,1,'warning'],
'Shelter In Place Warning' => [3600,0,2,'warning'],
'Volcano Warning' => [3600,0,0,'warning'],
'Civil Emergency Message' => [3600,0,2,'warning'],
'Evacuation - Immediate' => [3600,0,2,'warning'],
'Local Area Emergency' => [3600,0,2,'warning'],
'Child Abduction Emergency' => [3600,0,1,'warning'],
'Extreme Fire Danger' => [3600,0,0,'warning'],
'Air Quality Alert' => [0,0,0,'warning'],
    );
}
