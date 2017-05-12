package WWW::Socrata;

use strict;
use warnings;
use WWW::Curl::Easy;
use JSON;
use URI::Escape;
use Carp;

our $VERSION = '0.02';

sub new {
	my $class = shift;
	my $rh_params = shift;
	my $self = {};
	bless $self, ref $class || $class;

	if (! $rh_params) {
		$rh_params = {};
	}
	$self->_initialize($rh_params);

	return $self;
}


sub _initialize{
	 my ($self, $rh_params) = @_;

	! defined $rh_params->{base_url} 
		&& croak "base_url parameter required to create new Socrata object";

	# base URL
	#The base URL for this Socrata API, ex: http://data.medicare.gov/api or http://www.socrata.com/api
	$self->{base_url} = $rh_params->{base_url} || "http://nycopendata.socrata.com/api";
	# app token
	$self->{app_token} = $rh_params->{app_token} || "";
	# username and password used for authentication requests
	$self->{username} = $rh_params->{username} || "";
	$self->{password} = $rh_params->{password} || "";

}


sub get{
	my ($self, $path, $rh_params) = @_;

	if (! $path || $path eq ""){ warn "you must define a path"; }

	# use passed in path for dataset
	my $full_url = $self->{base_url} . $path;

	#define default headers to send
	my @headers = (
		'Accept: application/json',
		'Content-type: application/json',
		"X-App-Token: " . $self->{app_token},
	);

	#define parameters
	my $qstring;
	my @paramlist;
	foreach (keys(%$rh_params)){
		push (@paramlist,join("=", uri_escape($_), uri_escape($rh_params->{$_})));
	}
	$qstring = join("&", @paramlist);
	if ($qstring ne ""){
		$full_url .= "?" .$qstring;
	}

	# initialize curl object and set options
	my $curl = WWW::Curl::Easy->new();
	$curl->setopt(CURLOPT_HEADER, 1);
	$curl->setopt(CURLOPT_URL, $full_url);
	$curl->setopt(CURLOPT_HTTPHEADER, \@headers);

	# add suthentication if username and password are defined
	if ($self->{username} ne ""){
		$curl->setopt(CURLOPT_USERPWD, $self->{username} . ":" . $self->{password});
	}

	#define reposnse varaiable
	my $response_body;
	$curl->setopt(CURLOPT_WRITEDATA,\$response_body);

	# perform the curl
	my $retcode = $curl->perform;
	my $obj_response = {};

	# if good response
	if ($retcode == 0){

		# remove headers from output
		my @response = split("\n",$response_body);
		my $count =0;
		foreach (@response){
			if ($_ !~ /{/){
				$count++;
			} else{
				last;
			}
		}
		for (my $i=0; $i<$count; $i++){
			shift @response;
		}
		$response_body = join("\n", @response);

		$obj_response = decode_json($response_body);
		return $obj_response;
	} else {
		croak "An error happened: " . $curl->strerror($retcode) . " " . $curl->errbuf . "\n";
	}
}

=head1 NAME

WWW::Socrata - The great new WWW::Socrata!

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use WWW::Socrata;
    my %options = (
                base_url =>  "https://nycopendata.socrata.com",
                );
    my $socrata = new WWW::Socrata(\%options);
    my $rh_result = $socrata->get("/api/views/74cu-ncm4/rows.json", {});


=head1 DESCRIPTION

This library provides a simple wrapper for accessing some of the features of the Socrata Open Data API from PHP. Currently it only supports HTTP GET operations, but in the future it will support other methods as well.

The library is very simple. To access the Socrata API, you first instantiate a "Socrata" object, passing in the API base URL for the data site you wish to access. The Base URL is always the URL for the root of the datasite, with "/api" added to the path (ex: http://www.socrata.com/api or http://data.medicare.gov/api). Then you can use its included methods to make simple API calls:

This library provides an interface to the SODA Publisher API. If you're new to all this, you may want to brush up on the getting started guide.
dev.socrata.com/publisher/getting-started

If you're curious about how things work under the hood, you can also browse the API documentation directly.
http://opendata.socrata.com/api/docs/

=head1 OPTIONS

Additional options when creating the new Socrata object

   use WWW::Socrata;
   my %options = (
                base_url  =>  "https://nycopendata.socrata.com",
		app_token => "", #optional
		username  => "", #optional for authenticated requests
		password  => "", #optional for authenticated requests
                );
    my $socrata = new WWW::Socrata(\%options);

You may also add additional criteria on the get function, for searching or retrieving subsets of the data

   my $rh_result = $socrata->get("/api/views/74cu-ncm4/rows.json",
                                {
                                "method"=>"getRows",
                                "start"=>120,
                                "length" =>60,
                                });

	
=head1 AUTHOR

Benjamin Marcus, C<< <ben at fourthfloorequipment.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-socrata at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Socrata>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Socrata


You can also look for information at:
http://www.socrata.org

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Socrata>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Socrata>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Socrata>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Socrata/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Benjamin Marcus.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Socrata
