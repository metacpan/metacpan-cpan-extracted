# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming                                                      *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming;


# Uses ************************************************************************
use strict;
use warnings;
use LWP::UserAgent;
eval { require XML::Parser::Lite; };
eval { require XML::Mini::Document; } if (!_parser());
die("Could not load XML::Parser::Lite or XML::Mini::Document!\n") if
	(!_parser());


# Exports *********************************************************************
our @ISA = ('LWP::UserAgent');
our $VERSION = '0.05';


# Statics *********************************************************************
my %Upco_Info;


# Code ************************************************************************
BEGIN
{
	my $path;
	my $objc;

	$path =  (caller())[1];
	$path =~ s#WebService/Upcoming.pm$##;
	foreach $objc (glob($path.'WebService/Upcoming/Object/*.pm'))
	{
		require $objc;

		$objc =  substr($objc,length($path));
		$objc =~ s#/#::#g;
		$objc =~ s/\.pm$//g;
		foreach ($objc->_info())
		{
			$Upco_Info{$_->{'upco'}} =
			 {
				'http' => $_->{'http'},
				'objc' => $objc
			 };
		}
	}
}
sub new
{
	my $clas;
	my $keyy;
	my $vers;
	my $self;

	($clas,$keyy,$vers) = @_;
	$self = new LWP::UserAgent;
	bless($self,$clas);

	$self->{'keyy'} = $keyy;
	$self->{'vers'} = $vers || '1.0';
	$self->agent("WebService::Upcoming/$VERSION");

	return $self;
}
sub key
{
	my $self;
	my $keyy;

	($self,$keyy) = @_;
	$self->{'keyy'} = $keyy if (defined($keyy));

	return $self->{'keyy'};
}
sub query
{
	my $self;
	my $upco;
	my $args;
	my $rqst;
	my $rspn;
	my $urix;

	($self,$upco,$args) = @_;
	$self->{'code'} = 0;
	$self->{'text'} = '';
	if ($self->{'vers'} ne '1.0')
	{
		$self->{'text'} = 'Unknown API version specified';
		return undef;
	}
	if (!$upco)
	{
		$self->{'text'} = 'No Upcoming API method specified';
		return undef;
	}

	# Build the request ---------------------------------------------------
	delete($args->{'username'}) if (!$args->{'username'});
	delete($args->{'password'}) if (!$args->{'password'});
	$args->{'method'}  = $upco;
	$args->{'api_key'} = $self->{'keyy'};
	$urix = URI->new('http://upcoming.org/services/rest/');
	$rqst = new HTTP::Request;
	$rqst->header('Content-Type' => 'application/x-www-form-urlencoded');
	$rqst->method($Upco_Info{$upco}->{'http'});
	if (!$rqst->method())
	{
		$self->{'text'} = 'Unknown Upcoming API method: '.$upco;
		return undef;
	}
	elsif ($rqst->method() eq 'GET')
	{
		$urix->query_form(%{$args});
		$rqst->uri($urix);
	}
	elsif ($rqst->method() eq 'POST')
	{
		my $ctnt;

		$rqst->uri($urix);
		$urix->query_form(%{$args});
		$ctnt = $urix->query();
		if (defined($ctnt))
		{
			$rqst->header('Content-Length' => length($ctnt));
			$rqst->content($ctnt);
		}
	}
	else
	{
		$self->{'text'} = 'Unknown HTTP method: '.$rqst->method();
		return undef;
	}

	# Get the response ----------------------------------------------------
	$rspn = $self->request($rqst);
	$self->{'code'} = $rspn->code();

	# HACK: Work around an empty-attribute bug in XML::Mini::Document 1.28
	$rspn->{'_content'} =~ s/[\w\_\-]+=\"\"//g if
		(_parser() eq 'Mini::Document');

	return $rspn->{'_content'};
}
sub parse
{
	my $self;
	my $upco;
	my $rspn;
	my $hash;
	my $objc;
	my @objc;
        my @list;

	($self,$upco,$rspn) = @_;
	$self->{'text'} = '';

	# Parse the response --------------------------------------------------
	if (_parser() eq 'Parser::Lite')
	{
		my $lite;
		my @hash;

		$hash = {};
		$lite = new XML::Parser::Lite('Handlers' =>
		 {
			'Start' => sub
			 {
				my $temp;

				shift;
				push(@hash,$hash);
				$temp = shift;
				$hash->{$temp} = [$hash->{$temp}]
					if (ref($hash->{$temp}) eq 'HASH');
				if (ref($hash->{$temp}) eq 'ARRAY')
				{
					push(@{$hash->{$temp}},$hash = {});
				}
				else
				{
					$hash = $hash->{$temp} = {};
				}
				while ($temp = shift)
				{
					$hash->{$temp} = shift;
				}
			 },
			'End' => sub
			 {
				shift;
				$hash = pop(@hash);
			 }
		 });
		$lite->parse($rspn);
	}
	else
	{
		my $mini;

		$mini = XML::Mini::Document->new();
		$mini->parse($rspn);
		$hash = $mini->toHash();
	}

	# Response: Bad envelope
	if (!defined($hash->{'rsp'}))
	{
		$self->{'text'} = 'Bad envelope from server: '.
		 join(', ',keys(%{$hash}));
		return undef;
	}

	# Response: Bad status
	elsif ($hash->{'rsp'}->{'stat'} eq 'fail')
	{
		$self->{'text'} = 'Fail status from server';
		$self->{'text'} = $hash->{'rsp'}->{'error'}->{'msg'} if
		 (($hash->{'rsp'}->{'error'}) &&
		  ($hash->{'rsp'}->{'error'}->{'msg'}));
		return undef;
	}

	# Response: Bad version
	elsif ($hash->{'rsp'}->{'version'} ne '1.0')
	{
		$self->{'text'} = 'Unknown version from server: '.
		 $hash->{'rsp'}->{'version'};
		return undef;
	}

	# Response: Bad... something.  What the hell was that?
	elsif ($hash->{'rsp'}->{'stat'} ne 'ok')
	{
		$self->{'text'} = 'Unknown status from server: '.
		 $hash->{'rsp'}->{'stat'};
		return undef;
	}

	# Parse the envelope contents -----------------------------------------
	$objc = $Upco_Info{$upco}->{'objc'};
	return [] if ((!$objc) || (!$hash->{'rsp'}->{$objc->_name()}));
	if (ref($hash->{'rsp'}->{$objc->_name()}) eq 'HASH')
	{
		@objc = ($hash->{'rsp'}->{$objc->_name()});
	}
	else
	{
		@objc = @{$hash->{'rsp'}->{$objc->_name()}};
	}
	foreach (@objc)
	{
		push(@list,$objc->new($_,$hash->{'rsp'}->{'version'}));
	}
        return \@list;
}
sub call
{
	my $self;
	my $upco;
	my $args;
	my $rspn;

	($self,$upco,$args) = @_;
	$rspn = $self->query($upco,$args);
	return undef if (!defined($rspn));
	return $self->parse($upco,$rspn);
}
sub  err_code
{
	return $_[0]->{'http'};
}
sub  err_text
{
	return $_[0]->{'text'};
}
sub _parser
{
	return 'Parser::Lite'   if (defined($XML::Parser::Lite::VERSION));
	return 'Mini::Document' if (defined($XML::Mini::Document::VERSION));
	return undef;
}
1;
__END__

=head1 NAME

WebService::Upcoming - Perl interface to the Upcoming API

=head1 SYNOPSIS

  use WebService::Upcoming;

  my $upco = new WebService::Upcoming("*** UPCOMING API KEY HERE ***");
  my $objc = $upco->call("event.search",
              {
                  "search_text" => "music"
              });
  die("ERROR: ".$upco->err_text()."\n") if (!defined($objc));
  foreach (@{$objc})
  {
	print("EVENT: ".$_->name()." on ".$_->start_date()."\n");
  }


=head1 DESCRIPTION

A simple interface for using the Upcoming API.

C<WebService::Upcoming> is a subclass of L<LWP::UserAgent>, so all of the various proxy, request limits, caching, and other features are available.

=head2 METHODS

=over 4

=item C<new($key [, $version ])>

Creates an C<WebService::Upcoming> object.  $key is the API key used to identify the client to the Upcoming server.  $version is the version of the Upcoming API to call, and it defaults to "1.0" if excluded.

API keys may be obtained from http://upcoming.org/services/api/keygen.php.

=item C<key( [ $key ] )>

Sets or retrieves the current API key.

=item C<call($method, \%args)>

Constructs and executes a request to upcoming.org, returning an array of objects that define the response.

$method defines the Upcoming API method to call.  \%args is a reference to a hash containing arguments to the method.

Each call() returns a reference to an array of C<WebService::Upcoming::Object::*> objects, depending on the request.  event.getInfo, for instance, will return C<WebService::Upcoming::Object::Event> objects, with methods for each attribute: id(), name(), description(), etc.  Empty arrays can also be returned, indicating a successful call(), but without any response, such as watchlist.remove.

On failure, call() returns undef.  HTTP error codes are available through $upco->err_code(), human-readable error text is available through $upco->err_text().

Version 1.0 of the Upcoming API includes the following objects, all represented in the Perl namespace C<WebService::Upcoming::Object>: Category, Country, Event, Metro, State, User, Venue and Watchlist.

For a list of methods, their arguments and what object to expect in response, see http://www.upcoming.org/services/api/.  For each XML response in the Upcoming documentation, the attributes are available through methods of the same name on the C<WebService::Upcoming::Object::*> objects.

=item C<query($method, \$args)>

Constructs and executes a request to upcoming.org, returning the XML response.

$method defines the Upcoming API method to call.  \%args is a reference to a hash containing arguments to the method.

See <call()> for details.

=item C<parse($method, $response)>

Parses an API response from upcoming.org, returning an array of objects that define the response.

$method defines the Upcoming API method that generated the response.  $response is the XML sent by the server.

See <call()> for details.

=item C<err_code()>

Returns the last HTTP error code.  Only valid if call() returns undef.

=item C<err_text()>

Returns the last human-readable error text.  Only valid if call() returns undef.

=back

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<http://www.upcoming.org/>,
L<http://www.upcoming.org/services/api/>

=cut
