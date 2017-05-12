package WebService::30Boxes::API;

use strict;
use Carp qw/croak/;
require WebService::30Boxes::API::Request;
require WebService::30Boxes::API::Response;
require WebService::30Boxes::API::Event;
require WebService::30Boxes::API::Todo;
require LWP::UserAgent;
require XML::Simple;

our $VERSION = '1.05';

sub new {
   my ($class, %params) = @_;

   my $self = bless ({}, ref ($class) || $class);
   unless($params{'api_key'}) {
       croak "You need to set your API key before launching a request.\n".
             "See http://30boxes.com/api/api.php?method=getKeyForUser";
   }
   $self->{'_apiKey'} = $params{'api_key'};
   $self->{'_ua'}     = LWP::UserAgent->new(
      'agent' => __PACKAGE__."/".$VERSION,
   );

   return $self;
}

sub call {
   my ($self, $meth, $args) = @_;

   croak "No method specified." unless(defined $meth);

   my $req = WebService::30Boxes::API::Request->new($meth, $args);
   if(defined $req) { 
      unless(defined $self->{'_apiKey'}) {
      }
      $req->{'_api_args'}->{'apiKey'} = $self->{'_apiKey'};
      $req->encode_args();
      my $response = $self->_execute($req);

      #adjust
      if (defined $response->{'_xml'}->{'eventList'}->{'event'}->{'allDayEvent'}){
      		_adjust($response, 'event', 'allDayEvent');
      }

      if (defined $response->{'_xml'}->{'todoList'}->{'todo'}->{'done'}){
      		_adjust($response, 'todo', 'done');
      }

      my $error_msg = $response->{'error_msg'};
      my $error_code = $response->{'error_code'};

      if ($meth =~ /^events/){
		return new WebService::30Boxes::API::Event($response, $response->{'success'}, $response->{'error_msg'}, $response->{'error_code'});
      }
      elsif ($meth =~ /^todos/){
		return new WebService::30Boxes::API::Todo($response, $response->{'success'}, $response->{'error_msg'}, $response->{'error_code'});
      }
   } else {
      return;
   }
}

sub _adjust {
	my ($response, $method, $identifier) = @_;
	my $eventId = $response->{'_xml'}->{$method . 'List'}->{$method}->{$identifier};
	my %temp = %{$response->{'_xml'}->{$method . 'List'}->{$method}};
	delete $response->{'_xml'}->{$method . 'List'}->{$method};
	$response->{'_xml'}->{$method . 'List'}->{$method}->{$eventId} = \%temp;
}

sub request_auth_url {
   my ($self, $args) = @_;
   for my $c (qw/applicationName applicationLogoUrl/) {
      croak "$c is not defined." unless(defined $args->{$c});
   }

   my $req = WebService::30Boxes::API::Request->new('user.Authorize', $args);
      $req->{'_api_args'}->{'apiKey'} = $self->{'_apiKey'};
      $req->encode_args();
   return $req->uri .'?'. $req->content; 
}

sub _execute {
   my ($self, $req) = @_;
   
   my $resp = $self->{'_ua'}->request($req);
   bless $resp, 'WebService::30Boxes::API::Response';

   if($resp->{'_rc'} != 200){
      $resp->set_error(0, "API returned a non-200 status code ".
                          "($resp->{'_rc'})");
      return $resp;
   }

   my $result = $resp->reply(XML::Simple::XMLin($resp->{'_content'}, 
                             ForceArray => 0));
   if(!defined $result->{'stat'}) {
      $resp->set_error(0, "API returned an invalid response");
      return $resp;
   }

   if($result->{'stat'} eq 'fail') {
      $resp->set_error($result->{err}{code}, $result->{err}{msg});
      return $resp;
   }

   $resp->set_success();

   return $resp; 
}

1;
#################### main pod documentation begin ###################

=head1 NAME

WebService::30Boxes::API - Perl interface to the 30 Boxes API

=head1 SYNOPSIS

  use WebService::30Boxes::API;

  #$api_key and $auth_token are defined before
  my $boxes = WebService::30Boxes::API->new(api_key => $api_key);

  my $events = $boxes->call('events.Get', {authorizedUserToken => $auth_token});
  #my $todos = $boxes->call('todos.Get', {authorizedUserToken => $auth_token});
  if($events->{'success'}){
  	print "List start: " . $events->get_listStart . "\n";
  	print "List end: " . $events->get_listEnd . "\n";
  	print "User Id: " . $events->get_userId . "\n\n\n";
  
  	#while ($events->nextEventId){ - if you use this, you don't need to specify
  	#$_ as an argument
  	#foreach (@{$events->get_ref_eventIds}){
  	foreach ($events->get_eventIds){
  		print "Event id: $_\n";
  		print "Title: " . $events->get_title($_) . "\n";
  		print "Repeat end date: " . $events->get_repeatEndDate($_) . "\n";
  		print "Repeat skip dates: ";
  		foreach ($events->get_repeatSkipDates($_)){print "$_\n";}
  		print "Repeat type: " . $events->get_repeatType($_) . "\n";
  		print "Repeat interval: " . $events->get_repeatInterval($_) . "\n";
  		print "Reminder: " . $events->get_reminder($_) . "\n";
  		print "Tags: ";
  		foreach ($events->get_tags($_)){print "$_\n";}
  		print "Start date: " . $events->get_startDate($_) . "\n";
  		print "Start time: " . $events->get_startTime($_) . "\n";
  		print "End date: " . $events->get_endDate($_) . "\n";
  		print "End time: " . $events->get_endTime($_) . "\n";
  		print "Is all day event: " . $events->get_isAllDayEvent($_) . "\n";
  		print "Notes: ";
  		foreach ($events->get_notes($_)){print "$_\n";}
  		print "Privacy: " . $events->get_privacy($_) . "\n\n";
  	}
  }
  else{
  	print "An error occured (" . $events->{'error_code'} . ": " .
  		$events->{'error_msg'} . ")\n";
  }

=head1 DESCRIPTION

C<WebService::30Boxes::API> - Perl interface to the 30 Boxes API

=head2 METHODS

The following methods can be used

=head3 new

C<new> create a new C<WebService::30Boxes::API> object

=head4 options

=over 5

=item api_key

The API key is B<required> and this module will croak if you do not set one
here. A fresh key can be obtained at L<http://30boxes.com/api/api.php?method=getKeyForUser>

=back

=head3 call

With this method, you can call one of the available methods as described
on L<http://30boxes.com/api/>. 

C<call> accepts a method name followed by a hashref with the values to
pass on to 30Boxes.
object.

It returns an object of type WebService::30Boxes::API::Event or WebService::30Boxes::API::Todo (depending
which API method was called), which the user can then use to get the desired information.

=head3 request_auth_url

Some API methods require authentication (permission by the user). This
is done by sending the user to a specific URL where permission can be granted
or denied. This method accepts a hashref with these three values:

=over 5

=item applicationName

(B<Mandatory>) applicationName sets the well, application name you want to
show to the user.

=item applicationLogoUrl

(B<Mandatory>) The URI to your logo.

=item returnUrl

(B<Optional>) This is where you want the user to return too after permission
is granted.

=back

=head1 SEE ALSO

L<http://30boxes.com/>, L<http://30boxes.com/api/>

L<WebService::30Boxes::API::Response>

L<WebService::30Boxes::API::Event>

L<WebService::30Boxes::API::Todo>

30boxes.pl - this is a Perl script you can find on CPAN under Web that can be run in the terminal
and it will display the events for a given period of time along with the Todo list. It takes command
line arguments that specify how many days/weeks worth of events and how many todos will be displayed. 
I use it to display events and todos when I open my terminal. Send me an email with bugs or feature requests.

=head1 TODO

Add more error checking. Compact the code and make it more efficient. Please email me for feature requests.

=head1 BUGS

Please email chitoiup@umich.edu with any bugs.

=head1 AUTHORS

M. Blom (main functionality), 
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

Robert Chitoiu (integration with Event and Todo)
E<lt>chitoiup@umich.eduE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
