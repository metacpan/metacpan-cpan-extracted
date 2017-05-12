package WebService::Connpass;

use warnings;
use strict;
use Carp;
use utf8;

use version;
our $VERSION = qv('0.0.1');

use base qw/Class::Accessor/;
use Data::Recursive::Encode;
use DateTime::Format::ISO8601;
use Hash::AsObject;
use JSON;
use LWP::UserAgent;
use URI;

# Accessors
__PACKAGE__->mk_accessors( qw/ iter / );

# Constructor
sub new {
	my ($class, %param) = @_;
	my $self = bless({}, $class);

	# Parameter - Base URL (API Endpoint)
	if(defined($param{baseurl})){
		$self->{baseurl} = $param{baseurl};
		delete $param{baseurl};
	}else{
		$self->{baseurl} = 'http://connpass.com/api/v1/';
	}

	# Parameter - Encoding (Char-set)
	if(defined($param{encoding})){
		$self->{encoding} = $param{encoding};
		delete $param{encoding};
	}

	# Parameter - Automatic next page fetch 
	if(defined($param{disable_nextpage_fetch}) && $param{disable_nextpage_fetch}){
		$self->{nextpage_fetch} = 0;
		delete $param{disable_nextpage_fetch};
	}else{
		$self->{nextpage_fetch} = 1;
	}

	# Parameter - Timeout
	$param{timeout} =  $param{timeout} || 10;

	# Parameter - UserAgent string
	$param{agent} =  $param{agent} || __PACKAGE__.'/'.$VERSION;

	# ----------

	# Prepare a LWP::UA instance
	$self->{ua} = LWP::UserAgent->new(%param);

	# Prepare a Date parser instance
	$self->{datetime_parser} = DateTime::Format::ISO8601->new();

	# Prepare events store array
	$self->{events} = [];

	$self->{current_request_path} = '';
	$self->{current_query} = ();
	return $self;
}

# Fetch events
sub fetch {
	my ($self, $request_path, %query) = @_;

	my $is_auto_fetch = 0;
	if(defined($query{_is_auto_fetch})){
		$is_auto_fetch = 1;
		delete $query{_is_auto_fetch};
	}

	$self->{current_request_path} = $request_path;
	$self->{current_query} = \%query || {};
	$self->{current_query}->{count} = $self->{current_query}->{count} || 10; # Each fetch num of item

	# Request
	my $url = $self->_generate_get_url($self->{baseurl}.$request_path.'/', %{$self->{current_query}});
	my $response = $self->{ua}->get($url);
	unless($response->is_success){
		die 'Fetch error: '.$response->status_line;
	}

	# Decode JSON
	my $js_hash = JSON->new->utf8->decode($response->content);

	# Encoding
	if(defined($self->{encoding})){
		$js_hash = Data::Recursive::Encode->encode($self->{encoding}, $js_hash);
	}

	# Initialize the events store array
	unless($is_auto_fetch){ # If not auto-fetch...
		$self->{events} = [];
	}

	# Store events
	foreach my $item(@{$js_hash->{events}}){
		my $item_id = $item->{event_id};
		push(@{$self->{events}}, $item);
	}

	# Reset iterator
	unless($is_auto_fetch){
		$self->iter(0);
	}

	return;
}

# Put to next a Iterator
sub next {
	my $self = shift;
	my $_is_disable_autofetch = shift || 0;

	my $i = $self->iter();
	if($i < 0){ $i = 0; }

	if($i < @{$self->{events}}){
		# Next one
		$self->iter($i + 1);
		# Return one event object
		return $self->_generate_event_object($self->{events}->[$i]);
	}else{
		# Fetch next page automatically
		if($self->{nextpage_fetch} == 1 && $_is_disable_autofetch == 0 && @{$self->{events}} % $self->{current_query}->{count} == 0){
			$self->{current_query}->{start} = $i;
			$self->{current_query}->{_is_auto_fetch} = 1;
			# Auto fetch
			$self->fetch($self->{current_request_path}, %{$self->{current_query}});
			return $self->next(1);
		}
	}
	return;
}

# prev a Iterator
sub prev {
	my $self = shift;

	my $i = $self->iter() - 1;

	if(0 <= $i){
		# Prev one
		$self->iter($i);
		# Return one event object
		return $self->_generate_event_object($self->{events}->[$i]);
	}
	return;
}

# Generate Event object from Hash
sub _generate_event_object {
	my ($self, $hash) = @_;
	
	# Date parse
	unless(defined($hash->{started})){
		$hash->{started} = defined($hash->{started_at}) ? $self->{datetime_parser}->parse_datetime($hash->{started_at}) : undef;
	}

	unless(defined($hash->{ended})){
		$hash->{ended} = defined($hash->{ended_at}) ? $self->{datetime_parser}->parse_datetime($hash->{ended_at}) : undef;
	}

	unless(defined($hash->{updated})){
		$hash->{updated} = defined($hash->{updated_at}) ? $self->{datetime_parser}->parse_datetime($hash->{updated_at}) : undef;
	}

	return Hash::AsObject->new($hash);
}

# Generate URL from URL And Query parameters
sub _generate_get_url {
	my ($self, $url, %params) = @_;
	my $uri = URI->new($url);
	$uri->query_form(\%params);
	return $uri->as_string();
}

1;
__END__
=head1 NAME

WebService::Connpass - connpass API (v1) wrapper module for perl5

=head1 SYNOPSIS

  use WebService::Connpass;
  
  my $connpass = WebService::Connpass->new( encoding => 'utf8' );
  
  # Request event
  $connpass->fetch( 'event', keyword => 'perl' );
  
  # Print each events information
  while ( my $event = $connpass->next ){
    # Title and Event ID
    print $event->title . " (" . $event->event_id . ")";
    # Date (started_at)
    print " - ".$event->started if $event->started;
    print "\n";
  }

=head1 INSTALLATION (from GitHub)

  $ git clone git://github.com/mugifly/p5-WebService-Connpass.git
  $ cpanm ./p5-WebService-Connpass

=head1 METHODS

=head2 new ( [%params] )

Create an instance of WebService::Connpass.

%params = (optional) LWP::UserAgent options, and encoding (example: encoding => 'utf8').

=head2 fetch ( $api_path [, %params] )

Send request to Connpass API.
Also, this method has supported a fetch like 'Auto-Pager'.

=over 4

=item * $api_path = Path of request to Connpass API. Currently available: "event" only.

=item * %params = Query parameter.

=back

About the query, please see: http://connpass.com/about/api/

=head3 About the fetch like 'AutoPager' 

You can fetch all search results, by such as this code:

  # Request event
  $connpass->fetch( 'event' );
  
  # Print each events title
  while ( my $event = $connpass->next ){
        print $event->title . "\n";
  }

In the case of default, you can fetch max 10 items by single request to Connpass API.
However, this module is able to fetch all results by repeat request, automatically.

Also, you can disable this function, by specifying an option(disable_nextpage_fetch => 1) when call a constructor:

  my $connpass = WebService::Connpass->new(disable_nextpage_fetch => 1);

  # Request event
  $connpass->fetch( 'event' );
  
  # Print each events title
  while ( my $event = $connpass->next ){
        print $event->title . ."\n";
  }

In this case, you can fetch max 10 items.

But also, you can fetch more items by causing a 'fetch' method again with 'start' parameter:

  # Request the event of the remaining again
  $connpass->fetch( 'event', start => 10 ); # Fetch continue after 10th items.

=head2 next

Get a next item, from the fetched items in instance.

The item that you got is an object.

You can use the getter-methods (same as a API response fields name, such as: 'title', 'event_id', 'catch', etc...) 

 my $event = $conpass->next; # Get a next one item
 print $event->title . "\n"; # Output a 'title' (included in this item)

In addition, you can also use a following getter-methods : 'started', 'ended', 'updated'.
So, these methods return the each object as the 'DateTime::Format::ISO8601', from 'started_at', 'ended_at' and 'updated_at' field.

=head2 prev

Get a previous item, from the fetched items in instance.

=head2 iter

Set or get a position of iterator.

=head1 SEE ALSO

L<https://github.com/mugifly/p5-WebService-Connpass/> - Your feedback is highly appreciated.

L<WebService::Zussar> - https://github.com/mugifly/WebService-Zussar/

L<DateTime::Format::ISO8601>

L<Hash::AsObject>

L<LWP::UserAgent>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Masanori Ohgita (http://ohgita.info/).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Thanks, Perl Mongers & CPAN authors. 
