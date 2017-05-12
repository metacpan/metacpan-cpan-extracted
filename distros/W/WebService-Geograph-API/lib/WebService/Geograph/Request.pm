package WebService::Geograph::Request;

use warnings ;
use strict ;
use HTTP::Request ;
use URI;
use Date::Simple () ;

use Data::Dumper ;

our @ISA = qw (HTTP::Request) ;
our $VERSION = '0.05' ;

=head1 NAME

WebService::Geograph::Request - A request object to the Geograph API

=head1 SYNOPSIS

  use WebService::Geograph::API;
  
  my $api = new WebService::Geograph::API ( { 'key' => 'your_api_key_here'} ) ;

  my $rv = $api->lookup ( 'csv', { 'i'     => 12345,
                                   'll'    => 1,
                                   'thumb' => 1,
                                 }) ;

  my $data = $rd->{results} ;

=head1 DESCRIPTION

This object encapsulates a single request and its parameters 
the user specified to the Geograph API sevice.

The C<WebService::GeoGraph::Request> object is essentially a subclass of C<HTTP::Request> so you can
actually edit its usual parameters as much as you want.

=cut

=head1 AUTHOR

    Spiros Denaxas
    CPAN ID: SDEN
    Lokku Ltd ( http://www.nestoria.co.uk )
    s [dot] denaxas [@] gmail [dot]com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut 

=head1 SEE ALSO

L<WebService::Geograph::API>, L<WebService::Geograph::Response>, L<http://www.geograph.co.uk>, L<http://www.geograph.org.uk/help/api#api>

=cut

sub new {
	my $class = shift ;
	my $self = new HTTP::Request ;
	my $mode = shift ;
	my $rh_args = shift ;
	
	$self->{mode} = $mode ;
	$self->{args} = $rh_args ;
		
	bless $self, $class ;
	
	$self->method('POST') ;
	my $uri = &_get_uri_for_mode($mode) ;
	
	if (not defined $uri) {
		warn "Invalid/Unsupported mode selected: $mode\nPlease look at the documentation for supported modes.\n" ;
		return undef ;
	}		
	
    $self->{uri} = $uri;
	
	return $self ;
		
}

sub encode_args {
	my $self = shift ;
	
	my $args = $self->{args} ;
	my $url = URI->new( $self->{uri}, 'http' ) ;
	
	&validate_request_args($self->{mode}, $args) ;
	
	
	$url->query_form( %$args  ) ;
	return $url ;


} ;


sub validate_request_args {
	my ($mode, $rh_args) = (@_) ;
		
	# make an initial check for missing values for any arguments.	
	foreach (keys %$rh_args) {
		&error_and_exit("Missing value for argument: $_.\n") 
			unless (defined $rh_args->{$_}) ;
	}
	
	# fire up mode-specific validation.	
	if ($mode eq 'csv') { 
		return 1 if  (&_validate_csv_args($rh_args)) ;
	} elsif ($mode eq 'search') {
		return 1 if (&_validate_search_args($rh_args)) ;
	} 

}

sub _validate_search_args {
	my $rh_args = shift ;
	
	unless (exists $rh_args->{q}) {
		&error_and_exit("You must specify a search value using the q variable") ;
	}
	return 1 ;
}


sub _validate_csv_args {
		my $rh_args = shift ;
		
		if (exists $rh_args->{i}) {
			&error_and_exit("Invalid i value set.\nThe limit must be a numeric value.\n") 
				unless (($rh_args->{i} =~ m/\d/) and ($rh_args->{i} !~ m/[a-zA-z]/)) ;
			&error_and_exit("The i switch cannot be combined with any other switches.\n")	
				if ( (exists $rh_args->{since}) or (exists $rh_args->{limit}) or (exists $rh_args->{ri}) 
				   	 or (exists $rh_args->{'last'}) ) ;
		} # end of i validation.
		
		if (exists $rh_args->{count}) {
			&error_and_exit("The count switch cannot be used unless the i switch is used.\n")
				unless (exists $rh_args->{i}) ;
			&error_and_exit("Invalid count value, must be numeric.\n") 
				unless (($rh_args->{count} =~ m/\d/) and ($rh_args->{count} !~ m/[a-zA-z]/)) ;
		} # end of count valiation.
		
		if (exists $rh_args->{page}) {
			&error_and_exit("The count switch cannot be used unless the i switch is used.\n")
				unless (exists $rh_args->{i}) ;
			&error_and_exit("Invalid page value, must be numeric.\n") 
				unless (($rh_args->{page} =~ m/\d/) and ($rh_args->{page} !~ m/[a-zA-z]/)) ;
		} # end of page valiation.
		
		
		if (exists $rh_args->{since}) {
			my $date = $rh_args->{since} ;
			&error_and_exit("Invalid date supplied.\nDates must be supplied in YYYY-MM-DD format.\n") 
				unless (defined (Date::Simple->new($date))) ;
			} # end of date validation.
		
		if (exists $rh_args->{limit}) {
			&error_and_exit("Invalid limit set.\nThe limit must be a numeric value.\n") 
				unless (($rh_args->{limit} =~ m/\d/) and ($rh_args->{limit} !~ m/[a-zA-z]/)) ;
		} # end of limit validation
		
		if (exists $rh_args->{ri}) {
			&error_and_exit("Invalid National Grid value supplied.\nCan either be 1 (GB) or 2 (IE).\n")
				unless (($rh_args->{ri} == 1) or ($rh_args->{ri} == 2)) ;
		} # end of national gril validation
		
		if (exists $rh_args->{'last'}) {
			
			my $rh_valid_intervals = {
				'MINUTE' => 1,
				'HOUR'   => 1,
				'DAY'    => 1,
				'YEAR'   => 1,
				'MONTH'  => 1,
				'WEEK'   => 1,
			};
			
			my ($number, $interval) = split /\+/, $rh_args->{last} ;
			
			&error_and_exit("Invalid formatting for last switch.\n") 
				unless ( (($number) and ($interval)) and
					     (($number =~ m/\d/) and ($number !~ m/[a-zA-Z]/)) and 
					      ( exists $rh_valid_intervals->{$interval})
					   )  ;
		} # end of last validation
		 
		if (exists $rh_args->{thumb}) {
			&error_and_exit("Invalid thumb value.\nCan either be 1 or 0.\n")
				unless (($rh_args->{thumb} == 1) or ($rh_args->{thumb} == 1) ) ;
		} # end of thumb validation
		
		if (exists $rh_args->{en}) {
			&error_and_exit("Invalid en value.\nCan either be 1 or 0.\n")
				unless (($rh_args->{en} == 1) or ($rh_args->{en} == 1) ) ;
			&error_and_exit("The en switch cannot be combined with the ll switch.\n")
				if ( exists $rh_args->{ll}) ;
		} # end of en validation.
		
		if (exists $rh_args->{ll}) {
			&error_and_exit("Invalid ll value.\nCan either be 1 or 0.\n")
				unless (($rh_args->{ll} == 1) or ($rh_args->{ll} == 0) ) ;
			&error_and_exit("The ll switch cannot be combined with the en switch.\n")
				if ( exists $rh_args->{en}) ;
		} # end of ll validation.
		
		return 1 ;		
}

sub error_and_exit {
	my $message = shift ;
    warn $message ;
	exit(0) ;
}

sub _get_uri_for_mode {
	my $mode = shift ;
	return unless defined $mode ;
	
	my $rh_valid_modes = {
		'csv' => 'CSV Export',
		'search' => 'Search Query Building'
	} ;
	
	return unless exists $rh_valid_modes->{$mode} ;
	
	my $rh_mode_uri_map = {
		'csv' => 'http://www.geograph.org.uk/export.csv.php',
		'search' => 'http://www.geograph.org.uk/search.php'
	} ;
	
	return unless (exists $rh_mode_uri_map->{$mode}) && (defined $rh_mode_uri_map->{$mode}) ;
	
	my $uri = $rh_mode_uri_map->{$mode} ;
	return $uri ;
		
}