package WWW::DomainTools::SearchEngine;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = "0.06";
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

use base qw( WWW::DomainTools );
use List::Util qw/ first /;


=head1 NAME

WWW::DomainTools::SearchEngine - Search domain names for availability

=head1 SYNOPSIS

  use WWW::DomainTools::SearchEngine;

  my $api = WWW::DomainTools::SearchEngine->new(
        key => '12345',
        partner => 'yourname',
        customer_ip => '1.2.3.4'
  );

  my $res = $api->request(
        ext => "COM|NET|ORG|INFO",
        q => 'example.com',
  );

=head1 DESCRIPTION

This module allows you to use the Domain Tools domain search XML API.  You will
need to get a license key.  

L<http://xml-api.domaintools.com>

=head1 METHODS

=over 4

=item request( url parameters hash )

The keys and values expected are documented on the Domain Tools website.

If the request is successful, the return value is either a hash reference or 
a string depending on the value of the 'format' parameter to the constructor.

See the documentation for the new() method for more detailed information
about 'format' and other standard parameters.

If the HTTP request fails, this method will die.

=back

=over 4

=item domain_is_available( domain_name )

Pass in a domain name. It will return either a 1 or a 0 indicating that the domain
name is available for registration (or not).

TLS's that are currently checked for availability are .com .net .org .info .biz .us

If you attempt to check availability of a domain name with an unsupported TLD, this
method will die().

If the HTTP request fails, this method will die.

=back

=over 4

=item new( options hash )

Valid keys are:

=over 4

=item * url

Your XML api full url.  Eg. http://partnername.whoisapi.com/api.xml

The default is http://engine.whoisapi.com/api.xml

=item * key

Your license key

=item * partner

Your partner ID

=item * customer_ip

The (optional) IP of the customer that you are making the request for

=item * format

How you want the response returned when you call the request method.

'hash' is the default and means that you want a hash reference returned which
is built by using L<XML::Simple>.

'xml' means that you want a string returned containing the raw XML response.

=item * timeout

The number of seconds that you want to wait before cancelling the HTTP request.

default: 10 

=item * lwp_ua

An instance of L<LWP::UserAgent> to use for the requests.  This will allow you
to set up an L<LWP::UserAgent> with all of the settings that you would like to
use such as proxy settings etc.

default: LWP::UserAgent->new

=back

=back

=head1 SEE ALSO

L<WWW::DomainTools>
L<http://xml-api.domaintools.com>
L<http://xml-api.domaintools.com/api23.html>

=head1 BUGS

Please report bugs using the CPAN Request Tracker at L<http://rt.cpan.org/>

=head1 AUTHOR

David Bartle <captindave@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

I am not affiliated with Domain Tools or Name Intelligence.  The use of
their API's are governed by their own terms of service:

http://www.domaintools.com/members/tos.html

The full text of the license can be found in the
LICENSE file included with this module.

=cut

sub _init {
    my ($self) = @_;

    %{ $self->{default_params} } = (
        appname => 'search_engine',
        version => 4
    );

}

sub domain_is_available {
    my ( $self, $domain_name ) = @_;

    my $top_level_domain = ( reverse split( /\./, $domain_name ) )[0];

    ## make sure this tld is supported by the API
    if ( !first { lc($_) eq lc($top_level_domain) }
        @WWW::DomainTools::VALID_TLDS )
    {
        die("The TLD $top_level_domain is not supported by this API");
    }

    ## perform the domain tools search
    my $result = $self->request(
        ext =>
            $self->_tld_list_to_ext_param(@WWW::DomainTools::VALID_TLDS),
        q          => $domain_name,
        exactfirst => 'y',
    );

    ## if no records were returned, this means that it's available

    if ( $result->{response}->{records_returned} == 0 ) {
        return 1;
    }

    my $status_line = $result->{response}->{e}->{e_s};
    my $extn_line   = $result->{response}->{extn};
    my $tld_status_lookup
        = $self->_res_status_lookup( $status_line, $extn_line );
    my $tld_status = $tld_status_lookup->{$top_level_domain};

    ## take the exact match and look at the availability for the requested tld
    if ( $tld_status eq "q" || $tld_status eq "d" ) {
        return 1;
    }

    return 0;

}

1;
