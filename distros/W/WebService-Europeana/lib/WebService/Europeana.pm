package WebService::Europeana;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.3');

use JSON;
use Log::Any;
use LWP::UserAgent;
use Moo;
use Method::Signatures;
use Try::Tiny;
use URL::Encode qw(url_encode);

has 'api_url' => ( is => 'ro', default  => 'http://www.europeana.eu/api/v2/' );
has 'wskey'   => ( is => 'ro', required => 1 );

has log => (
    is      => 'ro',
    default => sub { Log::Any->get_logger },
);

method search(Str :$query, Str :$profile = "standard", Int :$rows = 12, Int :$start = 1, Str :$reusability, Str|ArrayRef :$qf ) {

    my $ua = LWP::UserAgent->new();
    my $query_string = undef;
    my $response = undef;
    my $json_result  = undef;
    my $result_ref   = undef;

    $query_string = sprintf( "%s%s?wskey=%s&rows=%s&query=%s&profile=%s",
        $self->api_url, "search.json", $self->wskey, $rows, url_encode($query), $profile );

    $query_string .= "&reusability=".$reusability if ($reusability);

    # qf can be  an ArrayRef
    if (ref($qf) eq 'ARRAY'){
      foreach my $f (@{$qf}){
       $query_string .= "&qf=".$f;
     }
    }else{
     $query_string .= "&qf=".$qf if ($qf); 
    }

    $self->log->infof( "Query String: %s", $query_string );

    $response = $ua->get($query_string);

    if ($response->is_success) {
      $json_result = $response->decoded_content;  # or whatever
    }
    else {
      $self->log->errorf("Problem accessing the API: %s!",
			 $response->status_line);
      $result_ref->{success} = 0;
      $result_ref->{error_msg} = $response->status_line;
      return $result_ref;
    }

    try {
        $result_ref = decode_json($json_result);
    }
    catch {
        $self->log->errorf( "Decoding of response '%s' failed: %s",
            $json_result, $_ );
    };

    if ($result_ref) {
      if (( $result_ref->{success} )
            && ( $result_ref->{success} == 1 )
	 ){
	$self->log->info("Search was a success!");
      }
 
      if ($result_ref->{itemsCount}){
	$self->log->infof("%d item(s) of a total of %d results returned", 
			  $result_ref->{itemsCount},
			  $result_ref->{totalResults}
			 );
      }else{
	$self->log->info("No results found");
        # add zero count
	$result_ref->{itemsCount} = 0;
      }
 
      return $result_ref;
    }
  }

1;


__END__

=begin markdown

[![Build Status](https://travis-ci.org/hatorikibble/webservice-europeana.svg?branch=master)](https://travis-ci.org/hatorikibble/webservice-europeana)

=end markdown

=head1 NAME

WebService::Europeana - access the API of europeana.eu

=head1 VERSION

This document describes WebService::Europeana version 0.0.2


=head1 SYNOPSIS

    use WebService::Europeana;

    my $Europeana = WebService::Europeana->new(wskey => 'API_KEY');
    my $result = $Europeana->search(query => "Europe", 
                                    reusability=> 'open', 
                                    rows => 3);

    foreach my $item (@{$result->{items}}){
      print $item->{title}->[0]."\n";
    }

=head1 DESCRIPTION

This module is a wrapper around the REST API of Europeana (cf. L<http://labs.europeana.eu/api/introduction>). At the moment only a basic search function is implemented.


=head1 CONSTRUCTOR

    $Europeana = WebService::Europeana->new(wskey=>'API_KEY')

=over 4

=item wskey

API key, can be requested at <http://labs.europeana.eu/api/registration>

=back

=head1 METHODS


=head2 search

for further explanation of the possible parameters please refer to
L<http://labs.europeana.eu/api/search>

=over 4

=item * query	

The search term(s).

=item * profile	

Profile parameter controls the format and richness of the response. See the possible values of the profile parameter.

=item * reusability  

Filter by copyright status. Possible values are open, restricted or permission.


=item * rows 

The number of records to return. Maximum is 100. Defaults to 12. 

=item * start  

The item in the search results to start with when using cursor-based pagination. The first item is 1. Defaults to 1. 

=item * qf

Facet filtering query. This parameter can be a simple string e.g. C<< qf=>"TYPE:IMAGE" >> or an array reference, e.g. C<< qf=>["TYPE:IMAGE","LANGUAGE:de"] >>

=back

=head1 LOGGING

This module uses the L<Log::Any>-Framework. To get logging output use L<Log::Any::Adapter> along with a destination-specific subclass.

For example, to send output to a file via L<Log::Any::Adapter::File>, your application could do this:

   use WebService::Europeana
   use Log::Any::Adapter ('File', '/path/to/file.log');

   my $Europeana = WebService::Europeana->new(wskey=>'API_KEY');
      $results = $Europeana->search(query=>'Europe');


=head1 BUGS AND LIMITATIONS

At the moment just a basic subset of the search parameters is implemented.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-europeana@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Peter Mayr  C<< <pmayr@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Peter Mayr C<< <pmayr@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
