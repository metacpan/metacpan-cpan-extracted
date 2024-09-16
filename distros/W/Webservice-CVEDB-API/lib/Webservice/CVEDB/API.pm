package Webservice::CVEDB::API;
our $VERSION = '1.000';

use v5.40;
use feature 'class';
no warnings 'experimental::class';

class Webservice::CVEDB::API 1.000;

use HTTP::Tiny;
use JSON::PP;
use Carp;

field $ua   :reader = HTTP::Tiny->new(timeout => 7);
field $base :reader = 'https://cvedb.shodan.io' ;

method get_cve ($cve_id){
    return fetch($self, "/cve/$cve_id");
}

method get_cpes (%params){
    return fetch($self, "/cpes?", \%params);
}

method get_cves (%params){
  return fetch($self, "/cves?", \%params);
}

sub fetch($self, $endpoint, $params //= ''){
    $params = $self->ua->www_form_urlencode( $params ) if $params;

    my $response = $self->ua->get($self->base.$endpoint.$params) or croak "$!";
    if (! $response->{success}){
        my %error;
        try{
            my $detail = decode_json($response->{content}) or croak "$!";
            $error{detail} = $detail->{detail}."\n";
            $error{success} = $response->{success};
        }catch($e){
            $error{detail} = $response->{content};
            $error{success} = $response->{success};
        }

        return \%error;
    }

    try{
        $response->{content} = decode_json($response->{content});
    }catch($e){
        croak "unable to decode message from API \n".$e;
    }

    $response->{content}->{success} = $response->{success};
    return $response->{content};
}
1;

__END__

=pod

=head1 NAME

Webservice::CVEDB::API - Fast Vulnerability lookups using CVE_ID and CPE23

=head1 SYNOPSIS

    use v5.40;
    use Webservice::CVEDB::API;


    my $ua = Webservice::CVEDB::API->new();

    my $response = $ua->get_cve('CVE-2016-10088');

    $response = $ua->get_cpes(
        product => 'linux',
        count => 'false',
        skip => 0,
        limit => 1000,
    );

    $response = $ua->get_cves(
        product => 'linux',
        count => 'false',
        skip => 0,
        limit => 2,
    );


=head1 DESCRIPTION

This module provides an object oriented interface via the keyword "class" feature to the CVEDB free API endpoint provided by L<https://cvedb.shodan.io/>. Shodan also provides much more robust paid services with subscription that this module does not provide access to.

=head1 METHODS

=head2 get_cve()

Accepts a string that is the CVE ID to be looked up.
Returns a hash reference with the results of the scan.

example response:

    {
        "cve_id": "string",
        "summary": "string",
        "cvss": 10,
        "cvss_version": 0,
        "cvss_v2": 10,
        "cvss_v3": 10,
        "epss": 1,
        "ranking_epss": 1,
        "kev": true,
        "propose_action": "string",
        "ransomware_campaign": "string",
        "references": [
            "string"
        ],
        "published_time": "2024-09-15T21:14:54.534Z",
        "cpes": [
            "string"
        ]
    }

=head2 get_cves()

Retrieve information about CVEs based on a specified product name or CPE 2.3 identifier.

=head3 Parameters:

=over

=item

B<cpe23> I<(String, Optional)>:
The CPE version 2.3 identifier for CVE information retrieval.

=item

B<product> I<(String, Optional)>:
The name of the product for CVE information retrieval.

=item

B<count I<(Boolean, Default: false)>>: If set to true, this returns only the count of matching CVEs. This will help get a quick overview of how many CVEs are associated with the product or CPE identifier, especially if the total number exceeds the limit (by default the limit is 1000 but can be adjusted).

=item

B<is_kev I<(Boolean, Default: false)>>: If set to true, this returns only CVEs with the kev flag set to true.

=item

B<sort_by_epss I<(Boolean, Default: false)>>: If set to true, this sorts CVEs by the epss score in descending order.

=item

B<skip I<(Integer, Default: 0)>>: Number of CVEs to skip in the result set.

=item

B<limit I<(Integer, Default: 1000)>>: The maximum number of CVEs to return in a single query. By default, up to 1000 CVEs can be returned, but you can adjust this value based on your specific needs.

=item

B<start_date I<(str, optional)>>: Start date for filtering CVEs (inclusive, format YYYY-MM-DDTHH:MM:SS).

=item

B<end_date I<(str, optional)>>: End date for filtering CVEs (inclusive, default is current date, format YYYY-MM-DDTHH:MM:SS).

=back

=head3 Returns:

=over

=item

B<if cpe23 and product are not specified>: Users can use the skip and limit parameters to paginate through the results effectively.

 B<Returns>: cves is a list of the newest CVEs based on published time.

=item

B<if cpe23 and product are specified>: Raise a message indicating that you can only specify one of cpe23 or product.


=item

B<if cpe23 is specified>:

 B<Returns>: cves is a list of CVEs matching the specified cpe23 identifier.

=item

B<if product is specified>:

 B<Returns>: cves is a list of CVEs matching the specified product name. Please refer to the CVEs schema for more details.

=back

Use start_date and end_date to filter CVEs based on published time. If start_date is not specified, it defaults to 00:00:00 on the given date. If end_date is not provided, it defaults to the current date and time.

example response:

    {
        "cves": [
            {
               "cve_id": "string",
               "summary": "string",
               "cvss": 10,
               "cvss_version": 0,
               "cvss_v2": 10,
               "cvss_v3": 10,
               "epss": 1,
               "ranking_epss": 1,
               "kev": true,
               "propose_action": "string",
               "ransomware_campaign": "string",
               "references": [
                   "string"
               ],
          "published_time": "2024-09-15T21:20:31.377Z"
        }
      ]
    }

=head2 get_cpes()

Retrieve a CPE 2.3 dictionary based on a specified product.

=head3 Parameters:

=over

=item

B<product I<(String, Required)>>: The name of the product for which you want to retrieve CPE dictionary.

=item

B<count I<(Boolean, Default: false)>>:If set to true, this returns only the count of matching CPEs. This will help a quick overview of how many CPEs are associated with the product name, especially if the total number exceeds the limit (by default the limit is 1000 but can be adjusted).

=item

B<skip I<(Integer, Default: 0)>>: Number of CPEs to skip in the result set.

=item

B<limit I<(Integer, Default: 1000)>>: The maximum number of CPEs to return in a single query. By default, up to 1000 CPEs can be returned, but you can adjust this value based on your specific needs.

=back

=head3 Returns:

=over

=item

B<if product is specified>:

 Returns: cpes is a list of CPEs matching the specified product name. Please refer to the CPEs schema for more details.

=back

example response:

    {
      "cpes": [
        "string"
      ]
    }

=head1 SEE ALSO

=over

=item

Call for API implementations on PerlMonks: L<https://perlmonks.org/?node_id=11161472>

=item

Listed at  freepublicapis.com: L<https://www.freepublicapis.com/cvedb-api>

=item

Official api webpage: L<https://cvedb.shodan.io/>

=back

=head1 AUTHOR

Joshua Day, E<lt>hax@cpan.orgE<gt>

=head1 SOURCECODE

Source code is available on Github.com : L<https://github.com/haxmeister/perl-CVEDB>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
