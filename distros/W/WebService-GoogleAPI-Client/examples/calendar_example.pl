#!/usr/bin/env perl

use WebService::GoogleAPI::Client;

use Data::Dumper qw (Dumper);
use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
use feature 'say';
use JSON;
use Carp;
use strict;
use warnings;

use DateTime;
use DateTime::TimeZone; ## perl -MDateTime::TimeZone -wE"say DateTime::TimeZone->new( name => 'local' )->name();"

use DateTime::Format::RFC3339;




=pod


                     
## SEE ALSO - https://github.com/APIs-guru/openapi-directory/blob/master/APIs/googleapis.com/

https://mybusiness.googleapis.com/$discovery/rest?version=v4

=head2 CALENDAR API ENDPOINTS


    calendar.acl.delete
    calendar.acl.get
    calendar.acl.insert
    calendar.acl.list
    calendar.acl.patch
    calendar.acl.update
    calendar.acl.watch
    calendar.calendarList.delete
    calendar.calendarList.get
    calendar.calendarList.insert
    calendar.calendarList.list
    calendar.calendarList.patch
    calendar.calendarList.update
    calendar.calendarList.watch
    calendar.calendars.clear
    calendar.calendars.delete
    calendar.calendars.get
    calendar.calendars.insert
    calendar.calendars.patch
    calendar.calendars.update
    calendar.channels.stop
    calendar.colors.get
    calendar.events.delete
    calendar.events.get
    calendar.events.import
    calendar.events.insert
    calendar.events.instances
    calendar.events.list
    calendar.events.move
    calendar.events.patch
    calendar.events.quickAdd
    calendar.events.update
    calendar.events.watch
    calendar.freebusy.query
    calendar.settings.get
    calendar.settings.list
    calendar.settings.watch


=head2 SCOPES


=head2 GOALS

  - demonstrates alternative approach to original Calendar author tests using Client::api_query() approach instead of meta classes

=cut

my $DEBUG = 1; ## 11 = loud
my $api = 'calendar';

      ##    BASIC CLIENT CONFIGURATION 

if ( -e './gapi.json')  { say "auth file exists" if $DEBUG>1 } else { croak('I only work if gapi.json is here'); }; ## prolly better to fail on setup ?
my $gapi_agent = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json =>'./gapi.json'  );
my $aref_token_emails = $gapi_agent->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0]; ## default to the first user
$gapi_agent->user( $user );

say "Running tests with default user email = $user\n";
say 'CHI Root cache folder: ' .  $gapi_agent->discovery->chi->root_dir() if $DEBUG>1; ## cached content temporary directory 




if ( 1== 0 ) ## extract discovery summary and show versions of $api - as at 14th October 
{
  ## DISCOVERY SPECIFICATION - mostly internal - user shouldn't need to use this
  #say "keys of api discovery hashref = " . join(',', sort keys ( %{WebService::GoogleAPI::Client::Discovery->new->discover_all() }) );
  my $discover_all = $gapi_agent->discover_all(  );
  
  # say Dumper $discover_all ; 
  ## SHOW ALL API Versions
  for my $api_struct ( @{ $discover_all->{items} } )
  {
    if ( $api_struct->{name} eq $api )
    #if ( 1==1 ) ## to show all apis
    {
      #my $key = "$api_struct ->{name}/$api_struct->{version}/rest";
      #print my $v1 = qq{$api_struct->{preferred} $api_struct->{name} $api_struct->{version} https://www.googleapis.com/discovery/v1/apis/$key \n};
      say my $v2 = qq{$api_struct->{preferred} $api_struct->{name} $api_struct->{version} $api_struct->{discoveryRestUrl}};
    }
    
    #WebService::GoogleAPI::Client::Discovery->new->get_rest({api});
  }
  exit;
}

if ( 1 == 1 )
{
  my $api_spec = $gapi_agent->get_api_discovery_for_api_id( $api );
  ## keys = auth, basePath, baseUrl, batchPath, description, discoveryVersion, documentationLink, etag, icons, id, kind, name, ownerDomain, ownerName, parameters, protocol, resources, revision, rootUrl, schemas, servicePath, title, version
  say join(', ', sort keys %{$api_spec} );
  foreach my $k (qw/schemas resources auth /) { $api_spec->{$k} = 'removed to simplify';  } ## SIMPLIFY OUTPUT
  say Dumper $api_spec;

  my $meths_by_id = $gapi_agent->methods_available_for_google_api_id( $api );
  foreach my $meth ( sort keys %{$meths_by_id} )
  {
    say "$meth"
  }
  
  ## DESCRIBE SPECIFICATION FOR AN API ENDPOINT
  #say Dumper $meths_by_id->{'calendar.events.list'};#exit;

  #my $r =  $gapi_agent->api_query( { api_endpoint_id => 'calendar.acl.list' ,options => { calendarId => 'primary', maxResults => 2 } } );
  
  #my $r =  $gapi_agent->api_query(  api_endpoint_id => 'calendar.settings.list'  );
  
  ## calendar.calendarList.list
  #my $r =  $gapi_agent->api_query( { api_endpoint_id => 'calendar.calendarList.list' ,options => {  calendarId => 'primary',  } });

  ## calendar.events.list
  #my $timeMin = DateTime->today->set_day(1)->subtract(days => 1)->set_day(1)->iso8601() . '+10:00';
  #say "timeMin = $timeMin";
  #my $r =  $gapi_agent->api_query(  api_endpoint_id => 'calendar.events.list', options => {  calendarId => 'primary', timeMin => $timeMin }); #'2018-06-03T10:00:00-07:00'} );
  

 my $r = undef;
 if ( 1 == 1 ) ##  insert new event into calendar
 {
  #say Dumper $meths_by_id->{'calendar.calendars.insert'};#exit; 
  my $demo_calendar_id = 'shotgundriver.com_8ejfk543736dp8vjqehtafflks@group.calendar.google.com';

  say Dumper $meths_by_id->{'calendar.events.insert'};exit;
  my $r_data = insert_new_event_into_calendar($gapi_agent, $demo_calendar_id )->json;
  if ( $r_data->{kind} eq  'calendar#event' )
  {
      say "Sleeping for 20 secs so you can check the calendar"; sleep(20);
      say "Deleteing event with eventId = $r_data->{id}";
      my $r2 = $gapi_agent->api_query(  api_endpoint_id => 'calendar.events.delete', 
                                      options => {  calendarId => $demo_calendar_id, eventId=>$r_data->{id} }); 
      say "Success indicated by 204 response" if ($r2->code == 204);
  }
  #$r =  $gapi_agent->api_query(  api_endpoint_id => 'calendar.calendars.insert', options => { summary => 'A GENERATED NEW CALENDAR' }); 

  exit; ## we have no $r so stop
}

  if ( 1==0) ## 
  {
      #say Dumper $meths_by_id->{'calendar.calendars.insert'};#exit; 
      $r =  $gapi_agent->api_query(  api_endpoint_id => '', 
                                      options => {  }); 
  }

  
  #$r = insert_new_event_into_calendar($gapi_agent);

  croak('no result to check yet ') unless defined $r;;
  if ($r->is_success )
  {

      my $data =  $r->json;
      print Dumper $data;
      render_calendar_list( $data )   if ($data->{kind} eq 'calendar#calendarList');
      render_calendar_events( $data ) if ($data->{kind} eq 'calendar#events');
      say "GOT A calendar#calendarListEntry" if ($data->{kind} eq  'calendar#calendarListEntry');
      
  }
  else
  {
      say $r->to_string;
      say $r->{body};
      croak("query returned an error  " . $r->code() );

  }
 
  
  
  #say $r->{body};

  exit;
   

  foreach my $meth (qw/calendar.acl.list  /) ##      -- FAILERS -  mybusiness.categories.list mybusiness.attributes.list
  {
    say "Testing endpoint '$meth' with no additional options";
    my $r = $gapi_agent->api_query( api_endpoint_id => $meth, options => {}, method=>'get');
    say "\n\n";
    say $r->to_string;
    say '-----';
    say $r->{body};
    say '-----';
    say Dumper $r;
  }
  exit;

}





########################### HELPER SUBS ###################

sub insert_new_event_into_calendar
{
    my ( $gapi_client, $calendar_id, $summary,  $start_dt, $finish_dt ) = @_;
    # https://developers.google.com/calendar/v3/reference/events/insert
    # desceription status location attendees[].email supportsAttachments 
    $start_dt    = DateTime->now() unless defined $start_dt ;
    $finish_dt   = DateTime->now() unless defined $finish_dt ;
    $calendar_id = 'primary' unless defined $calendar_id;
    $summary     = "TEST EVENT CREATED BY WebService::GoogleAPI::Client" unless defined $summary;

    my $formatter = DateTime::Format::RFC3339->new(); 
    my $r = $gapi_client->api_query(  api_endpoint_id => 'calendar.events.insert', 
                                                options    => {
                                                    calendarId => $calendar_id,
                                                    start => {
                                                        dateTime => $formatter->format_datetime( $start_dt )
                                                    },
                                                    end => {
                                                        dateTime => $formatter->format_datetime( $finish_dt )
                                                    },
                                                    summary => $summary
                                                }
                                        ); 
  #print Dumper $r;
  return $r;
}

sub render_calendar_list
{
    my ( $data ) = @_;
    croak("expected hashref data with key kind of 'calendar#calendarList'") unless $data->{kind} eq 'calendar#calendarList';
    foreach my $cal ( @{$data->{items}} )
    {
        print qq{
id:      $cal->{id}
summary: $cal->{summary}

        };
    }
}

sub render_calendar_events
{
    
    my ( $data ) = @_;
    croak("expected hashref data with key kind of 'calendar#events'") unless $data->{kind} eq 'calendar#events';
    foreach my $ev ( @{$data->{items}} )
    {
        my $vals = {};
        foreach my $f ( qw// )
        {
            
        }
        $vals->{start} = $ev->{start}{date} if defined $ev->{start}{date};
        $vals->{start} = $ev->{start}{dateTime} if defined $ev->{start}{dateTime};
        $vals->{end} = $ev->{end}{date}     if defined $ev->{end}{date};
        $vals->{end} = $ev->{end}{dateTime}     if defined $ev->{end}{dateTime};
        
        say qq{
id:      $ev->{id}
url:     $ev->{htmlLink}
summary: $ev->{summary}};
        say qq{start:   $vals->{start}
end:     $vals->{end} } unless defined $ev->{recurrence}; ## skipping recurring events
    } 
}


=head2 Calnedar Notes


Peter's Public Calendar for events related to WebService::GoogleAPI::Client Library

shotgundriver.com_8ejfk543736dp8vjqehtafflks@group.calendar.google.com


=head2 Some Date Play Notes 
say my $offset = DateTime::TimeZone->new( name => 'local' )->offset_for_datetime(DateTime->now()) / 60 / 60;
displays '10' for me at GMT+10



perl -MDateTime -wE 'say DateTime->today
                                   ->set_day(1)
                                   ->subtract(months => 1)
                                   ->subtract(days => 1)
                                   ->iso8601()'

perl -MDateTime -wE 'say DateTime->today( time_zone => DateTime::TimeZone->new( name => "local" )->name() )
                                   ->set_day(1)
                                   ->add(months => 1)
                                   ->subtract(days => 1)
                                   ->set_day(1)
                                   ->iso8601( time_zone => DateTime::TimeZone->new( name => "local" )->name() ) '

nb - doesn't look like the timezeon really works in these

say DateTime->now()->iso8601();

=cut
