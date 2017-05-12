package WebService::Technorati::ApiQuery;
use strict;
use utf8;

use LWP::UserAgent;
use HTTP::Request;
use XML::XPath;

use WebService::Technorati::Exception;

use constant DEFAULT_API_HOST_URL => 'http://api.technorati.com';


BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

my $api_host_url = '';

=head1 NAME

WebService::Technorati::ApiQuery - a base class for web services client queries

=head1 SYNOPSIS

This class has no constructor, as there's little use instantiating one. The fun
is in the derived classes.

=head1 DESCRIPTION

When adding a new API call client, this class provides a lot scaffolding such as
query string building, HTTP protocol stuff, XML::XPath object creation, and other
common behaviors.

=head1 USAGE

This class is mostly utility functions that are inherited by ApiQuery derivations.




=head1 BUGS

No bugs currently open

=head1 SUPPORT

Join the Technorati developers mailing list at
http://mail.technorati.com/mailman/listinfo/developers

=head1 AUTHOR

    Ian Kallen
    ikallen _at_ technorati.com
    http://developers.technorati.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the terms of the following 
Creative Commons License:
http://creativecommons.org/licenses/by/2.0
as well as the indemnification provisions of the 
Apache 2.0 style license, the full text of which can be 
found in the LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

=head2 apiHostUrl

 Usage     : apiHostUrl('http://developers.technorati.com')
 Purpose   : gets/sets the base URL
 Returns   : a URL string
 Argument  : a base URL, if setting the value; otherwise none
 Throws    : none
 Comments  : Instantiations of an ApiQuery subclass may want to change 
             which api host they connect to (i.e. for beta testing 
             interface changes that aren't yet deployed to the default 
             host, http://api.technorati.com).
See Also   : WebService::Technorati

=cut

sub apiHostUrl {
    my $self = shift;
    my $change = shift;
    if ($change) {
        $api_host_url = $change;
    }
    if ($api_host_url) {
        return $api_host_url;
    }
    return DEFAULT_API_HOST_URL;
}


=head2 fetch_url

 Usage     : fetch_url('http://developers.technorati.com')
 Purpose   : fetches the URL contents
 Returns   : a scalar of the content data
 Argument  : a URL
 Throws    : WebService::Technorati::NetworkException if the URL contents
             cannot be fetched
 Comments  : the underlying implementation uses LWP::UserAgent
See Also   : WebService::Technorati

=cut
        
sub fetch_url {
    my $url = shift;
    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request);
    if ($response->is_success) {
        return $response->content;
    } else {
        print $response->code,"\n";
        print $response->error_as_HTML;
        WebService::Technorati::NetworkException->throw("fetching $url failed, stopping");
    }   
}   

=head2 build_query_string

 Usage     : build_query_string($hashref);
 Purpose   : transforms the keys/values into a query string
 Returns   : the query string
 Argument  : a hash reference
 Throws    : none
 Comments  : multi value keys are not yet accounted for
See Also   : WebService::Technorati

=cut

sub build_query_string {
    my $params = shift;
    my @pairs = ();
    while (my($key,$val) = each %{$params}) {
        push(@pairs, "$key=$val");
    }
    return join('&', @pairs);
}

=head2 execute

 Usage     : build_query_string($apiurl, $hashref);
 Purpose   : handles the low level execution cycle of an API call
 Returns   : void
 Argument  : a hash reference
 Throws    : none
 Comments  : calls build_query_string, fetch_url, instantiates XML::XPath 
             and calls readResults
See Also   : WebService::Technorati

=cut

sub execute {
    my $self = shift;
    my $url = shift;
    my $args = shift;
    $url .= '?' . build_query_string($args);
    my $result_xml = fetch_url($url);
    my $result_xp = XML::XPath->new( xml => $result_xml );
    $self->readResults($result_xp);
}


=head2 readResults

 Usage     : readResults($xpath_data);
 Purpose   : this is an abstract method
 Returns   : void
 Argument  : an XML::XPath representation of an API response
 Throws    : WebService::Technorati::MethodNotImplementedException if not overriden
 Comments  : derived classes must implement this in order to use execute(...)
See Also   : WebService::Technorati

=cut

sub readResults {
    WebService::Technorati::MethodNotImplementedException->throw(
        "abstract methond 'readResults()' not implemented");
} 

1;

__END__
