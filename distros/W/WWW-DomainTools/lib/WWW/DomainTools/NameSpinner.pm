package WWW::DomainTools::NameSpinner;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = "1.03";
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}

use base qw( WWW::DomainTools );


=head1 NAME

WWW::DomainTools::NameSpinner - Suggest other domain names

=head1 SYNOPSIS

  use WWW::DomainTools::NameSpinner;

  my $api = WWW::DomainTools::NameSpinner->new(
        key => '12345',
        partner => 'yourname',
        customer_ip => '1.2.3.4'
  );

  my $res = $api->request(
        ext => "COM|NET|ORG|INFO",
        q => 'example.com',
  );

=head1 DESCRIPTION

This module allows you to use the Domain Tools name spinner API in to list
domain name suggestions based on a domain that you pass in.  You will 
need to get a license key from their site to use this tool.

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
        appname => 'name_spinner',
        version => 4
    );

}

1;
