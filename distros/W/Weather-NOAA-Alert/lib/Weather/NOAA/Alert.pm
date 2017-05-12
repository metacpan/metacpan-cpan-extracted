package Weather::NOAA::Alert;

use strict;
use warnings;

use LWP::Simple;
use XML::Twig;
use Data::Dumper;
#use Carp;

#use Exporter;
#our @ISA = qw(Exporter);
#@EXPORT = qw//;
#@EXPORT_OK = qw//;

=head1 NAME

Weather::NOAA::Alert - Polling and parsing of NOAA CAP 1.1 Alerts

=head1 VERSION

Version 0.90

=cut

our $VERSION = '0.90';

=head1 SYNOPSIS
 
    my $alert = Weather::NOAA::Alert->new(['TXZ104', 'TXC082', 'TXZ097']);
    my $events = $alert->get_events();
    my ($errorCount, $eventCount, $addCount, $deleteCount) = $alert->poll_events();
 
=head1 DESCRIPTION

Weather::NOAA::Alert will retrieve and parse the NOAA National Weather Service 
ATOM and CAP 1.1 feeds for the specified forecast zones.  It is designed to 
cache previously polled CAP items.  The overall process is to get the 
requested ATOM feed, get any CAP entries that are not in the cache, and store 
the alerts.

You can find the zone list and more information about NOAA watches, warnings,
and advisories at the following sites:

=over 4

=item * Zone List: L<http://alerts.weather.gov/>

=item * Zone Maps: L<http://www.weather.gov/mirs/public/prods/maps/pfzones_list.htm>

=back
 
=head1 EXAMPLE
 
    use Weather::NOAA::Alert;
    use Data::Dumper;
 
    my $SLEEP_SECS = 60;   #Poll every 1 minute
 
    #my $alert = Weather::NOAA::Alert->new(['US']);
    my $alert = Weather::NOAA::Alert->new(['TXC085', 'TXZ097']);
    $alert->printLog(1);
    $alert->errorLog(1);

    my $events = $alert->get_events();
 
    while (1) {
         my ($errorCount, $eventCount, $addCount, $deleteCount) 
                 = $alert->poll_events();
       
         print Dumper( $events) . "\n";
       
         print "Tracking $eventCount " . ($eventCount ==1 ? "event" : "events");
         print "   $addCount added, $deleteCount deleted";
         print ", $errorCount " . ($errorCount ==1 ? "error" : "errors");
         print "\n";
         
         print "Sleeping $SLEEP_SECS seconds\n-----------------\n\n";
         sleep($SLEEP_SECS);
     }



=head1 METHODS

=head2 B<new> - Create a new Weather::NOAA::Alert object

    $alert = Weather::NOAA:Alert->new(@zones);
    $alert = Weather::NOAA:Alert->new();

An array reference may be provided with the list of NOAA forecast zones 
that should be polled. If the list is not supplied then you must call 
C<$object-E<gt>zones(@zones)> to set the zone list prior to calling 
C<$object-E<gt>poll_events()>.

=cut

sub new {
    my $class = shift;
    my $self = {};
    
    $self->{events} = {};
    $self->{formatTime} = 0;
    $self->{formatAsterisk} = 0;
    $self->{printLog} = 0;
    $self->{printActions} = 0;
    $self->{errorLog} = 0;
    $self->{diagDump} = 0;
    $self->{diagFile} = undef;
    $self->{atomURLZone} = "http://alerts.weather.gov/cap/wwaatmget.php?x=";
    $self->{atomURLUS} = "http://alerts.weather.gov/cap/us.atom";

#http://alerts.weather.gov/cap/us.atom
#http://alerts.weather.gov/cap/wwaatmget.php?x=TXZ104
#http://alerts.weather.gov/cap/wwacapget.php?x=CO20110424120100WinterStormWarning20110425120000CO.GJTWSWGJT.790bacf3c14f2dc0e2d5149cf668f95c
    
    bless( $self, $class);
    
    my $zoneList = shift;
    $self->zones($zoneList) if defined $zoneList;
    
    return $self;
}

=head2 B<zones> - Set the monitored zone list
    
    $object->zones([zone1, zone2, ...]);
    @zones = $object->zones();

Setting the zone list will overwrite the existing list with the 
supplied list. If called with no arguments, returns a reference 
to the current zone array.  To return data for all zones use "US".

=cut

sub zones { $_[0]->{zones}=$_[1] if defined $_[1]; return $_[0]->{zones}; }

=head2 B<get_events> - get a reference to the alert object events hash

    %events = $object->get_events();

This is the primary output of the Weather::NOAA::Alert module.  The data 
structure is the result of parsing the NOAA CAP 1.1 objects retrieved for 
the specified zones.  The events hash is indexed first by zone, then by 
the CAP ID.  

Remembers past events in a data structure hash consisting of:
 C<{zone}-E<gt>{CAP id}-E<gt>{'delete'}>
 C<                -E<gt>{'actionTime'}>
 C<                -E<gt>{'event'}>
 C<                -E<gt>{'certainty'}>
 C<                -E<gt>{'senderName'}>
 C<                -E<gt>{'urgency'}>
 C<                -E<gt>{'instruction'}>
 C<                -E<gt>{'description'}>
 C<                -E<gt>{'category'}>
 C<                -E<gt>{'severity'}>
 C<                -E<gt>{'effective'}>
 C<                -E<gt>{'headline'}>
 C<                -E<gt>{'expires'}>

Note that the hash keys are dynamically created from the <info> section of the 
event.  If NOAA adds, renames, or removes an XML parameter it will also
change in the structure.  In addition, nothing is currently parsed from the 
event header.  There are XML parameters in the header that might be 
interesting to collect but I didn't have a use for any of that data.  Future 
module revisions might include more of the NOAA data.

=cut

sub get_events { return $_[0]->{events}; }

=head1 SETTINGS

=head2 B<formatTime> - Add colons to strings that look like time stamps

    $object->formatTime( [1 | 0] );
    $curr_setting = $object->formatTime();

When called without parameters will return the current setting.

=cut

sub formatTime { $_[0]->{formatTime}=$_[1] if defined $_[1]; return $_[0]->{formatTime}; }

=head2 B<formatAsterisk> - Strip asterisks from description and information tags

    $object->formatAsterisk( [1 | 0] );
    $curr_setting = $object->formatAsterisk();

When called without parameters will return the current setting.

=cut

sub formatAsterisk { $_[0]->{formatAsterisk}=$_[1] if defined $_[1]; return $_[0]->{formatAsterisk}; }

=head2 B<printLog> - Print basic status information while retrieving cap entities

    $object->printLog( [1 | 0] );
    $curr_setting = $object->printLog();

When called without parameters will return the current setting.

=cut

sub printLog { $_[0]->{printLog}=$_[1] if defined $_[1]; return $_[0]->{printLog}; }

=head2 B<printActions> - Print the cap ID for every entry added or deleted

    $object->printActions( [1 | 0] );
    $curr_setting = $object->printActions();

When called without parameters will return the current setting.

=cut

sub printActions { $_[0]->{printActions}=$_[1] if defined $_[1]; return $_[0]->{printActions}; }

=head2 B<errorLog> - Print error descriptions

    $object->errorLog( [1 | 0] );
    $curr_setting = $object->errorLog();

When called without parameters will return the current setting.

=cut

sub errorLog { $_[0]->{errorLog}=$_[1] if defined $_[1]; return $_[0]->{errorLog}; }

=head2 B<diagDump> - Save all atom content to file

    $object->diagDump( [1 | 0] );
    $curr_setting = $object->diagDump();

Dumps all atom files received to the file diagnostics.txt in the
current directory.  When called without parameters will return 
the current setting.

=cut

sub diagDump { $_[0]->{diagDump}=$_[1] if defined $_[1]; return $_[0]->{diagDump}; }

=head2 B<atomURLZone> - Sets the Atom URL for zones

    $object->atomURLZone( $url );
    $curr_setting = $object->atomURLZone();

When called without parameters will return the current setting.  The 
default setting is: 

C<http://alerts.weather.gov/cap/wwaatmget.php?x=>

=cut

sub atomURLZone { $_[0]->{atomURLZone}=$_[1] if defined $_[1]; return $_[0]->{atomURLZone}; }

=head2 B<atomURLUS> - Sets the Atom URL when specifying zone "US"
    
    $object->atomURLUS( $url );
    $curr_setting = $object->atomURLUS();

When called without parameters will return the current setting.  The 
default setting is: 

C<http://alerts.weather.gov/cap/us.atom>

=cut

sub atomURLUS { $_[0]->{atomURLUS}=$_[1] if defined $_[1]; return $_[0]->{atomURLUS}; }

=head2 B<VERSION> - Returns the current module version

    my $version = Weather::NOAA::Alert->VERSION;

=cut

sub VERSION { return $VERSION; }

=head2 B<poll_events> - Poll NWS Public Alerts

    my ($errorCount, $eventCount, $addCount, $deleteCount)
            = $object->poll_events();

Polls the National Weather Service Public Alerts and updates the events hash 
for each event.  Returns an array of counts:

=over 4

=item * $errorCount - The number of errors encountered while pulling the Atom files

=item * $eventCount - The number of actively tracked events

=item * $addCount - The number of events added on this poll

=item * $deleteCount - The number of events deleted on this poll

=back

=cut

sub poll_events {
    my ($self) = @_;
    my ($errorCount, $eventCount, $addCount, $deleteCount) = (0, 0, 0, 0);

    if( !defined( $self->{diagFile}) and $self->{diagDump}) {
        open($self->{diagFile}, ">>diagnostics.txt");
    }
    
    foreach my $zone (@{$_[0]->{zones}}) {
        print "Pulling ATOM feed for zone $zone\n" if($self->{printLog});
        my $atomTwig= new XML::Twig(
            TwigRoots => {'entry' => 1},
            TwigHandlers => {'entry' =>  \&atomInfoHandler},
            pretty_print => 'indented',
        );
        
        my $atomURL;
        if( $zone ne 'US') {
            $atomURL = $self->{atomURLZone} . $zone;
        } else {
            $atomURL = $self->{atomURLUS};
        }
        my $atomContent;
        my $firstCAP = 1;
        if ($atomContent = get($atomURL)) {
            if( defined $self->{diagFile} and $self->{diagDump}) {
                print( {$self->{diagFile}} "Time: " . scalar(localtime()));
                print( {$self->{diagFile}} "\natomURL:: $atomURL\n");
                print( {$self->{diagFile}} Dumper( \$atomContent) . "\n");
            }

            if ($atomTwig->safe_parse($atomContent)) {
                
                #Set the delete flag for all events in this zone
                foreach my $capId (keys( %{$_[0]->{events}->{$zone}}) ) {
                    $_[0]->{events}->{$zone}{$capId}{'delete'} = 1;
                }
                
                my @atomItems = $atomTwig->root->children;
                foreach my $atomItem (@atomItems) {
                    my $capId = $atomItem->first_child('id')->text;

                    if( $capId eq $atomURL) {
                        #<id>http://alerts.weather.gov/cap/wwaatmget.php?x=TXZ104</id>
                        #XXX-Fragile code.  How do we unambiguously determine 
                        #that this entry is a "null" entry?  IMO, there should 
                        #not be an "<entry>" at all...  That would tell us!
                        print "There are no active watches, warnings or advisories for zone $zone\n" if($self->{printLog});
                        next;
                    } elsif( $capId =~ /^http:\/\/alerts\.weather\.gov\/cap\/\w{2}\.atom/) {
                        #<id>http://alerts.weather.gov/cap/ct.atom</id>
                        #ignore; these occur when parsing the entire US zone.
                        #XXX-Fragile code.  How should one unambiguously 
                        #determine that this entry is not a real CAP event?
                        next;
                    }
                    
                    if( !exists($_[0]->{events}->{$zone}{$capId})) {
                        if( $firstCAP) {
                            print "Pulling new CAP entries: " if($self->{printLog} and not $self->{printActions});
                            $firstCAP = 0;
                        }
                        print "." if($self->{printLog} and not $self->{printActions});
                        
                        if( $_[0]->retrieveCAP($zone, $capId)) {
                            #XXX- Fragile code!  why does NOAA make me match on 
                            #some random string for expired events??
                            if( $_[0]->{events}->{$zone}{$capId}{'description'} =~ 
                                    /alert has expired/ ) {
                                delete($_[0]->{events}->{$zone}{$capId});
                                print "Exp: $capId\n" if($self->{printActions});
                            } else {
                                $eventCount++;
                                $addCount++;
                                print "Add: $capId\n" if($self->{printActions});
                            }
                        } else {
                            $errorCount++;
                        }
                    } else {
                        #Still exists so reset the delete flag
                        $_[0]->{events}->{$zone}{$capId}{'delete'} = 0;
                        $eventCount++;
                    }
                }
                
                #Delete events that were not reset
                foreach my $capId (keys( %{$_[0]->{events}->{$zone}}) ) {
                    if( $_[0]->{events}->{$zone}{$capId}{'delete'}) {
                        $deleteCount++;
                        delete($_[0]->{events}->{$zone}{$capId});
                        print "Del: $capId\n" if($self->{printActions});
                    }
                }

                print "No new events" if( $firstCAP and $self->{printLog});
                print "\n" if($self->{printLog});
                
            } else {
                print "Error parsing ATOM file for zone $zone :: $0\n" if($self->{errorLog});
                print $atomContent . "\n" if($self->{errorLog});
                $errorCount++;
            } #if ($twig->safe_parse($atomContent))
        } else {
            print "Failed to retrieve ATOM file for zone $zone\n" if($self->{errorLog});
            $errorCount++;
        } #if ($atomContent = get($atomURL))
    } #foreach my $zone (@zones)
    
    if( defined( $self->{diagFile}) and $self->{diagDump}) {
        close( $self->{diagFile});
        $self->{diagFile} = undef;
    }
    
    return( $errorCount, $eventCount, $addCount, $deleteCount);
}

sub retrieveCAP {
    my ($self, $zone, $capId) = @_;
    
    my $capTwig= new XML::Twig(
        TwigRoots => {'info' => 1},
#        TwigHandlers => {'info' =>  \&capInfoHandler},
        TwigHandlers => {'info' => sub { capInfoHandler( $self->{formatTime}, $self->{formatAsterisk}, @_) } },
        pretty_print => 'indented',
    );
    
    my $capContent;
    if ($capContent = get($capId)) {
    
        if( defined( $self->{diagFile}) and $self->{diagDump}) {
            print( {$self->{diagFile}} "capId:: $capId\n");
            print( {$self->{diagFile}} Dumper( \$capContent) . "\n");
        }
        
        if ($capTwig->safe_parse($capContent)) {
            
            #Parse only the first <info> enclosure
            #Loop through it appending items to the event hash
            foreach my $child ($capTwig->root->first_child->children) {
                #ignore nested items: eventCode, parameter, area; they're too hard :^)
                if($child->tag ne 'eventCode' and $child->tag ne 'parameter' and $child->tag ne 'area') {
                    $self->{events}->{$zone}{$capId}{$child->tag} = $child->text;
                }
            }
            $self->{events}->{$zone}{$capId}{'delete'} = 0;
            
        } else {
            print "Error parsing CAP file for event $capId :: $0\n" if($self->{errorLog});
            print $capContent . "\n" if($self->{errorLog});
            return 0;
        }
    } else {
        print "Failed to retrieve CAP file for event $capId\n" if($self->{errorLog});
        return 0;
    }
    
    return 1;  #No errors encountered
}



sub atomInfoHandler {
    my ($twig, $atomInfo) = @_;
    atomFormatTags($atomInfo);
}

sub capInfoHandler {
    my ($twig, $formatTime, $formatAsterisk, $capInfo) = @_;
    capFormatTags($formatTime, $formatAsterisk, $capInfo);
}

sub atomFormatTags {
    my ($atomInfo) = @_;
    
#    my @children = $atomInfo->children;
#    foreach my $child (@children) {
#        if ($child->tag eq '') {
#            my $childText = $child->text;
#            $childText =~ s/^\n//;
#            $childText =~ s/\n$//;
#            $child->set_text($childText);
            
#            #Insert new tags into the document
#            my $elt= new XML::Twig::Elt( 'parsedHeadline', $parsedHeadline);
#            $elt->paste( 'last_child', $capInfo);
#        }
#    }
}

sub capFormatTags {
    my ($formatTime, $formatAsterisk, $capInfo) = @_;
    
    #Format some of the fields.  Need to remove newlines from every field 
    #except the description and instruction; they need other adjustments.
    my @children = $capInfo->children;
    foreach my $child (@children) {
        my $childText = $child->text;
        if ($child->tag ne 'description' and $child->tag ne 'instruction') {
            #Adjust the formatting a little.  Why would a CAP file 
            #need to contain newline formatting?
            $childText =~ s/^\n//;
            $childText =~ s/\n/  /g;
            $childText =~ s/^\s+//; #remove leading spaces
            $childText =~ s/\s+$//; #remove trailing spaces
        } else {
            if( $formatTime) {
#            if( 1 ) {
                #Try to add colons to all the time fields.  This allows
                #the MS SAPI engine to correctly pronounce the time
                $childText =~ s/(\d{1,2}?)(\d{2})\s{1}(AM|PM)\s{1}[A-Z]{3}/$1:$2 $3/g;
            }
            if( $formatAsterisk) {
#            if( 1 ) {
                #Remove any "*" because it sounds real funny when SAPI 
                #pronounces "asterisk" in the middle of the speech stream
                $childText =~ s/\*/  /g;
            }
        }
        $child->set_text($childText);
    }
}

=head1 NOAA CAP CHALLENGES

The following items represent fragile parts of the code caused by ambiguous
data in the National Weather Service CAP feeds.  These items should be 
addressed by NWS by publishing a document that clearly states the behavior 
for each of these conditions or by generally adding more XML enclosures 
especially replacing the long list of counties that can occur.  

=over 4

=item * B<Expired Alerts>

Expired alerts contain a valid C<E<lt>eventE<gt>E<lt>/eventE<gt>> section 
with C<E<lt>descriptionE<gt>alert has expiredE<lt>/descriptionE<gt>>.  
There seems to be little else in the document that can be used to 
determine that the event is basically empty and expired.  One option 
might be to key on a null C<E<lt>expiresE<gt>E<lt>/expiresE<gt>> section 
but nothing is guaranteed since this behavior is not documented by the 
national weather service as far as I can tell.

=item * B<Empty CAP Documents>

If there are no notifications for a county or zone, the CAP document 
will contain a valid C<E<lt>eventE<gt>E<lt>/eventE<gt>> section where 
the C<E<lt>idE<gt>E<lt>/idE<gt>> is the same as the CAP URL (i.e. points 
to its self).  Again there is little else in the document that can be 
used to unambiguously determine that there are no events for that zone 
or county.  

=item * B<Long Lists of Counties>

Events can contain a long list of counties.  For anyone trying 
to perform text to speech or even SMS delivery of the events 
the text can be too long.  Ideally the county list would be in 
other XML enclosures so that XSL files could still display pages 
correctly, but other uses would not need to consider the, potentially
long list of counties.

=back

=head1 TODO

=over 4

=item * B<Implement point detection based on latitude / longitude>

Events contain a C<E<lt>polygonE<gt>E<lt>/polygonE<gt>> that could be 
used to determine if a specific latitude / longitude is in the event 
area.  This would greatly reduce the number of alerts for a specific 
point in a county since the NWS has recently started issuing and 
expiring events for specific areas that are not bound by county.  
Tracking at the county level can trigger several events over a short 
period as a storm progresses through the county.

=back

=head1 SEE ALSO

=over 4

=item * L<http://alerts.weather.gov/> - Primary NOAA National Weather Service
page for Public Alerts.  Has a full list of all county and forecast zone IDs.

=item * L<http://alerts.weather.gov/cap/product_list.txt> - List of possible 
data that is populated in the <event> field

=back

=head1 AUTHOR

Michael Stovenour, C<< <michael at stovenour.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-weather-noaa-alert at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-NOAA-Alert>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Weather::NOAA::Alert

    
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-NOAA-Alert>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Weather-NOAA-Alert>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Weather-NOAA-Alert>

=item * Search CPAN

L<http://search.cpan.org/dist/Weather-NOAA-Alert/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Stovenour.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Weather::NOAA::Alert
